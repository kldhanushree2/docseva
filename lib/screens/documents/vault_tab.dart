import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/vault_model.dart';
import '../../core/theme/app_theme.dart';

class VaultTab extends StatelessWidget {
  const VaultTab({super.key});

  void _showAddDocumentDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();
    String category = 'Identity';
    PlatformFile? selectedFile;
    Uint8List? selectedFileBytes;
    String selectedFileType = ''; // 'PDF' or 'Image'
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Document to Vault'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Document Name (e.g., Aadhaar Card)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: ['Identity', 'Tax / Finance', 'Education', 'Vehicle / License', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: isUploading ? null : (val) => setState(() => category = val ?? 'Identity'),
                    ),
                    const SizedBox(height: 16),

                    // FILE PICKER BUTTON
                    OutlinedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                withData: true,
                              );

                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final ext = (file.extension ?? '').toLowerCase();

                                // VALIDATION FOR SUPPORTED EXTENSIONS
                                if (ext != 'pdf' && ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Unsupported file type. Please select a PDF or image.')),
                                    );
                                  }
                                  return;
                                }

                                setState(() {
                                  selectedFile = file;
                                  selectedFileBytes = file.bytes;
                                  selectedFileType = ext == 'pdf' ? 'PDF' : 'Image';
                                  if (nameController.text.trim().isEmpty) {
                                    nameController.text = file.name.split('.').first;
                                  }
                                });
                              }
                            },
                      icon: Icon(
                        selectedFile != null
                            ? (selectedFileType == 'PDF' ? Icons.picture_as_pdf : Icons.image)
                            : Icons.attach_file,
                        color: selectedFile != null ? AppTheme.secondaryColor : AppTheme.primaryColor,
                      ),
                      label: Text(
                        selectedFile != null
                            ? '${selectedFile!.name} ($selectedFileType)'
                            : 'Select File (PDF, JPG, PNG)',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        side: BorderSide(
                          color: selectedFile != null ? AppTheme.secondaryColor : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a Document Name')),
                            );
                            return;
                          }

                          if (selectedFileBytes == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a PDF or image file.')),
                            );
                            return;
                          }

                          setState(() => isUploading = true);

                          final ext = (selectedFile?.extension ?? '').toLowerCase();
                          final timestamp = DateTime.now().millisecondsSinceEpoch;
                          final fileName = selectedFile?.name ?? 'file.$ext';
                          final storagePath = 'vault/$userId/${timestamp}_$fileName';

                          String fileUrl = '';

                          try {
                            // 1. UPLOAD ACTUAL BYTES TO FIREBASE STORAGE
                            final storageRef = FirebaseStorage.instance.ref().child(storagePath);
                            final metadata = SettableMetadata(
                              contentType: ext == 'pdf' ? 'application/pdf' : 'image/${ext == 'png' ? 'png' : 'jpeg'}',
                            );

                            // A 25s timeout stops the dialog from spinning
                            // forever. On Flutter Web this call silently
                            // hangs (instead of throwing) when the Storage
                            // bucket has no CORS policy for this origin —
                            // see storage-cors.json in the project root.
                            final uploadTask = await storageRef
                                .putData(selectedFileBytes!, metadata)
                                .timeout(const Duration(seconds: 25));
                            fileUrl = await uploadTask.ref
                                .getDownloadURL()
                                .timeout(const Duration(seconds: 15));
                          } catch (e) {
                            debugPrint('Firebase Storage upload fallback: $e');
                            // Fallback to data URI if Storage fails or is offline
                            if (selectedFileBytes!.lengthInBytes < 700000) {
                              final mimePrefix = ext == 'pdf'
                                  ? 'data:application/pdf;base64,'
                                  : 'data:image/${ext == 'png' ? 'png' : 'jpeg'};base64,';
                              fileUrl = '$mimePrefix${base64Encode(selectedFileBytes!)}';
                            } else {
                              if (dialogContext.mounted) {
                                setState(() => isUploading = false);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to upload document. Please try again. ($e)')),
                                );
                              }
                              return;
                            }
                          }

                          final doc = VaultModel(
                            id: '',
                            userId: userId,
                            documentName: name,
                            category: category,
                            fileUrl: fileUrl,
                            storagePath: storagePath,
                            fileType: ext == 'pdf' ? 'PDF Document' : 'Image',
                            uploadedDate: timestamp,
                          );

                          try {
                            // 2. SAVE VAULT RECORD TO FIRESTORE
                            await context.read<FirestoreService>().addVaultDocument(doc);

                            // 3. AUTOMATICALLY CLOSE DIALOG ON SUCCESS
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Document uploaded successfully!')),
                              );
                            }
                          } catch (e) {
                            // KEEP DIALOG OPEN ON FAILURE & PERMIT RETRY
                            if (dialogContext.mounted) {
                              setState(() => isUploading = false);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to upload document. Please try again. ($e)')),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Upload Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDocumentViewer(BuildContext context, VaultModel doc) {
    if (doc.fileType.contains('PDF') || doc.fileUrl.contains('application/pdf') || doc.fileUrl.endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewerScreen(doc: doc),
        ),
      );
    } else {
      _showImageViewerDialog(context, doc);
    }
  }

  void _showImageViewerDialog(BuildContext context, VaultModel doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc.documentName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (doc.fileUrl.startsWith('data:image')) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(doc.fileUrl.split(',').last),
                    fit: BoxFit.contain,
                  ),
                ),
              ] else if (doc.fileUrl.startsWith('http')) ...[
                Image.network(
                  doc.fileUrl,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ] else ...[
                const Icon(Icons.image, size: 80, color: AppTheme.primaryColor),
              ],
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                title: const Text('Category'),
                subtitle: Text(doc.category),
              ),
              ListTile(
                dense: true,
                title: const Text('Uploaded Date'),
                subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(doc.uploadedDate))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VaultModel doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.documentName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<FirestoreService>().deleteVaultDocument(doc.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted from Vault.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete document: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const Center(child: Text('Please login to view vault'));

    return Scaffold(
      appBar: AppBar(title: const Text('Document Vault')),
      body: StreamBuilder<List<VaultModel>>(
        stream: context.read<FirestoreService>().getVaultDocuments(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final isPdf = doc.fileType.contains('PDF') || doc.fileUrl.contains('application/pdf');
              final isBase64Image = doc.fileUrl.startsWith('data:image');

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: isBase64Image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(doc.fileUrl.split(',').last),
                            width: 44,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.image,
                          color: isPdf ? Colors.red : AppTheme.primaryColor,
                          size: 36,
                        ),
                  title: Text(doc.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${doc.category} • ${doc.fileType}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: AppTheme.secondaryColor),
                        tooltip: 'View Document',
                        onPressed: () => _openDocumentViewer(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Document',
                        onPressed: () => _confirmDelete(context, doc),
                      ),
                    ],
                  ),
                  onTap: () => _openDocumentViewer(context, doc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDocumentDialog(context, user.uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Your vault is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Tap + to select a PDF or image document'),
        ],
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final VaultModel doc;

  const PDFViewerScreen({super.key, required this.doc});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  VaultModel get doc => widget.doc;

  // Set by onDocumentLoadFailed. Previously this callback only did a
  // debugPrint, so a failed load (e.g. the browser silently blocking a
  // cross-origin Storage fetch) left the user staring at a blank viewer
  // with no explanation — exactly the "blank page, nothing loads" report.
  bool _renderFailed = false;
  String? _renderFailedReason;

  void _openInExternalBrowser(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF in Chrome: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? pdfBytes;
    String? networkUrl;
    bool hasError = false;

    // Temporary/Debug Information Logging (Requirement 7)
    debugPrint('=== DOCSEVA PDF DEBUG INFO ===');
    debugPrint('PDF Name: ${doc.documentName}');
    debugPrint('PDF Type: ${doc.fileType}');
    debugPrint('PDF URL/Path: ${doc.fileUrl.length > 100 ? doc.fileUrl.substring(0, 100) + '...' : doc.fileUrl}');
    debugPrint('Storage Location: ${doc.storagePath}');
    debugPrint('URL Available: ${doc.fileUrl.isNotEmpty}');
    debugPrint('Viewer Source Type: ${doc.fileUrl.startsWith('http') ? "Firebase Storage HTTPS Download URL" : "Base64 Data URI"}');
    debugPrint('==============================');

    try {
      if (doc.fileUrl.startsWith('http')) {
        networkUrl = doc.fileUrl;
      } else if (doc.fileUrl.contains('base64,')) {
        final base64Part = doc.fileUrl.split('base64,').last.trim();
        pdfBytes = base64Decode(base64Part);
      } else if (doc.fileUrl.isNotEmpty && !doc.fileUrl.startsWith('data:')) {
        pdfBytes = base64Decode(doc.fileUrl.trim());
      } else {
        hasError = true;
      }
    } catch (e) {
      debugPrint('Error preparing PDF source: $e');
      hasError = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.documentName),
        actions: [
          if (networkUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: 'Open in Chrome PDF Viewer',
              onPressed: () => _openInExternalBrowser(context, networkUrl!),
            ),
        ],
      ),
      body: (hasError || _renderFailed)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _renderFailed
                          ? 'This PDF could not be rendered in-app'
                              '${_renderFailedReason != null ? ' ($_renderFailedReason)' : ''}. '
                              'This usually means the browser blocked the file '
                              'request (Storage CORS not configured) — try '
                              'opening it directly instead.'
                          : 'Unable to open this PDF. Please check that the file is available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_renderFailed && networkUrl != null)
                    ElevatedButton.icon(
                      onPressed: () => _openInExternalBrowser(context, networkUrl!),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Directly Instead'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back / Close'),
                  ),
                ],
              ),
            )
          : networkUrl != null
              ? Column(
                  children: [
                    Container(
                      color: AppTheme.primaryLightest,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Viewing PDF. You can also open it directly in Chrome viewer.',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openInExternalBrowser(context, networkUrl!),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open in Chrome'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      // SizedBox.expand forces an explicit bounded size onto
                      // the viewer — without it, SfPdfViewer on Flutter Web
                      // can end up laid out with near-zero width/height
                      // inside a Column/Expanded chain and render only a
                      // sliver of the page, which matches the "mostly blank
                      // page with a strip of text at the edge" report.
                      child: SizedBox.expand(
                        // Keying by URL forces a fresh viewer instance per
                        // document instead of reusing internal state from a
                        // previously-viewed PDF.
                        key: ValueKey('network-$networkUrl'),
                        child: SfPdfViewer.network(
                          networkUrl,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          onDocumentLoadFailed: (details) {
                            debugPrint('SfPdfViewer network load warning: ${details.description}');
                            if (mounted) {
                              setState(() {
                                _renderFailed = true;
                                _renderFailedReason = details.description;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : pdfBytes != null
                  ? SizedBox.expand(
                      key: ValueKey('memory-${doc.id}'),
                      child: SfPdfViewer.memory(
                        pdfBytes,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        onDocumentLoadFailed: (details) {
                          debugPrint('SfPdfViewer memory load warning: ${details.description}');
                          if (mounted) {
                            setState(() {
                              _renderFailed = true;
                              _renderFailedReason = details.description;
                            });
                          }
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Unable to open this PDF. Please check that the file is available.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back / Close'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
