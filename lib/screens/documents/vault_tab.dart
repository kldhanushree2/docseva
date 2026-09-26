import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/vault_model.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/browser_file_opener.dart';

const List<String> _kCategories = [
  'Identity',
  'Tax / Finance',
  'Education',
  'Vehicle / License',
  'Other',
];

class VaultTab extends StatelessWidget {
  const VaultTab({super.key});

  // ---------------------------------------------------------------------
  // ADD DOCUMENT
  // ---------------------------------------------------------------------

  Future<void> _pickAndAdd(BuildContext context, String userId, {required bool photo}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: photo ? ['jpg', 'jpeg', 'png'] : ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file. Please try again.')),
        );
      }
      return;
    }

    final ext = (file.extension ?? (photo ? 'jpg' : 'pdf')).toLowerCase();
    if (context.mounted) {
      _showAddDocumentDialog(
        context,
        userId,
        pickedFile: file,
        pickedBytes: bytes,
        pickedExt: ext,
      );
    }
  }

  void _showAddDocumentDialog(
    BuildContext context,
    String userId, {
    required PlatformFile pickedFile,
    required Uint8List pickedBytes,
    required String pickedExt,
  }) {
    final nameController = TextEditingController(text: pickedFile.name.split('.').first);
    String category = _kCategories.first;
    bool isUploading = false;
    final isPdf = pickedExt == 'pdf';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: isPdf ? AppTheme.teal : AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickedFile.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      items: _kCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: isUploading ? null : (val) => setState(() => category = val ?? _kCategories.first),
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

                          setState(() => isUploading = true);

                          final timestamp = DateTime.now().millisecondsSinceEpoch;
                          final fileName = pickedFile.name;
                          final storagePath = 'vault/$userId/${timestamp}_$fileName';

                          String fileUrl = '';
                          bool uploadedToStorage = false;

                          try {
                            // 1. UPLOAD ACTUAL BYTES TO FIREBASE STORAGE
                            final storageRef = FirebaseStorage.instance.ref().child(storagePath);
                            final metadata = SettableMetadata(
                              contentType: isPdf ? 'application/pdf' : 'image/${pickedExt == 'png' ? 'png' : 'jpeg'}',
                            );

                            // A 25s timeout stops the dialog from spinning
                            // forever if Firebase Storage is unreachable or
                            // CORS isn't configured for this origin (see
                            // storage-cors.json in the project root).
                            final uploadTask = await storageRef
                                .putData(pickedBytes, metadata)
                                .timeout(const Duration(seconds: 25));
                            fileUrl = await uploadTask.ref
                                .getDownloadURL()
                                .timeout(const Duration(seconds: 15));
                            uploadedToStorage = true;
                          } catch (e) {
                            debugPrint('Firebase Storage upload fallback: $e');
                            // Fallback to a base64 data URI if Storage fails
                            // or is unreachable, so the document is still
                            // saved and usable offline.
                            if (pickedBytes.lengthInBytes < 700000) {
                              final mimePrefix = isPdf
                                  ? 'data:application/pdf;base64,'
                                  : 'data:image/${pickedExt == 'png' ? 'png' : 'jpeg'};base64,';
                              fileUrl = '$mimePrefix${base64Encode(pickedBytes)}';
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
                            // Only record a storagePath when a Storage
                            // object genuinely exists, so Copy/Delete never
                            // try to hit a path nothing was ever written to.
                            storagePath: uploadedToStorage ? storagePath : '',
                            fileType: isPdf ? 'PDF Document' : 'Image',
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
                                SnackBar(content: Text('Failed to save document. Please try again. ($e)')),
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

  void _showAddChoiceSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Add to Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryLightest,
                    child: Icon(Icons.image, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Photo'),
                  subtitle: const Text('Choose a JPG or PNG image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndAdd(context, userId, photo: true);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryLightest,
                    child: Icon(Icons.picture_as_pdf, color: AppTheme.teal),
                  ),
                  title: const Text('PDF'),
                  subtitle: const Text('Choose a PDF document'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndAdd(context, userId, photo: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // VIEW DOCUMENT
  // ---------------------------------------------------------------------

  void _openDocumentViewer(BuildContext context, VaultModel doc) {
    if (doc.isPdf) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerScreen(doc: doc)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerScreen(doc: doc)));
    }
  }

  // ---------------------------------------------------------------------
  // COPY DOCUMENT
  // ---------------------------------------------------------------------

  /// Resolves the raw bytes for a vault entry without relying on a plain
  /// HTTP fetch (which can be blocked by browser CORS on Flutter Web — see
  /// storage-cors.json). Base64 entries decode locally; Storage-backed
  /// entries are read back through the Firebase Storage SDK itself.
  Future<Uint8List?> _resolveBytes(VaultModel doc) async {
    if (doc.isDataUri) {
      final base64Part = doc.fileUrl.split('base64,').last.trim();
      return base64Decode(base64Part);
    }
    if (doc.storagePath.isNotEmpty) {
      return FirebaseStorage.instance.ref(doc.storagePath).getData(25 * 1024 * 1024);
    }
    return null;
  }

  Future<void> _copyDocument(BuildContext context, VaultModel doc) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Preparing a copy...'), duration: Duration(seconds: 2)));

    // On web there's no app-writable filesystem to copy a file into, so the
    // most useful "copy" is to hand the file straight to the browser, which
    // can view it, download it (Ctrl/Cmd+S) or let the user right-click →
    // Copy Image.
    if (kIsWeb) {
      if (doc.fileUrl.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Nothing to copy — this file has no data.')));
        return;
      }
      try {
        if (doc.isNetworkUrl) {
          // A real Firebase Storage URL — a normal browser navigation, so
          // url_launcher is fine here.
          await launchUrl(Uri.parse(doc.fileUrl), mode: LaunchMode.externalApplication);
        } else {
          // A data: URI. Chrome blocks script-initiated top-level
          // navigation to data: URLs (the tab opens but stays blank), so we
          // convert it to a blob: URL first, which opens normally.
          final bytes = await _resolveBytes(doc);
          if (bytes == null) throw Exception('No bytes to open');
          openBytesInBrowser(doc.mimeType, bytes);
        }
      } catch (e) {
        // Last resort — copy the link/data text to the clipboard.
        await Clipboard.setData(ClipboardData(text: doc.fileUrl));
        messenger.showSnackBar(const SnackBar(content: Text('Could not open a new tab — link copied to clipboard instead.')));
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Opened in a new tab — use your browser\'s Save/Download option.')));
      return;
    }

    try {
      final bytes = await _resolveBytes(doc);
      if (bytes == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Could not read this document to copy it.')));
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = doc.documentName.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '_');
      var outFile = File('${dir.path}/$safeName.${doc.fileExtension}');
      var suffix = 1;
      while (await outFile.exists()) {
        outFile = File('${dir.path}/${safeName}_$suffix.${doc.fileExtension}');
        suffix++;
      }
      await outFile.writeAsBytes(bytes);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Copy saved to ${outFile.path}'),
          action: SnackBarAction(label: 'Open', onPressed: () => OpenFile.open(outFile.path)),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to copy document: $e')));
    }
  }

  // ---------------------------------------------------------------------
  // DELETE DOCUMENT
  // ---------------------------------------------------------------------

  void _confirmDelete(BuildContext context, VaultModel doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.documentName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.destructiveColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<FirestoreService>().deleteVaultDocument(
                      doc.id,
                      storagePath: doc.storagePath,
                    );
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

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

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

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final docs = List<VaultModel>.from(snapshot.data ?? [])
            ..sort((a, b) => b.uploadedDate.compareTo(a.uploadedDate));
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final isBase64Image = doc.isImage && doc.isDataUri;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      : doc.isImage && doc.isNetworkUrl
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                doc.fileUrl,
                                width: 44,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppTheme.primaryColor, size: 36),
                              ),
                            )
                          : Icon(
                              doc.isPdf ? Icons.picture_as_pdf : Icons.image,
                              color: doc.isPdf ? AppTheme.teal : AppTheme.secondaryColor,
                              size: 36,
                            ),
                  title: Text(doc.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${doc.category} • ${doc.fileType} • ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(doc.uploadedDate))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _openDocumentViewer(context, doc);
                          break;
                        case 'copy':
                          _copyDocument(context, doc);
                          break;
                        case 'delete':
                          _confirmDelete(context, doc);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(leading: Icon(Icons.remove_red_eye, color: AppTheme.secondaryColor), title: Text('View')),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: ListTile(leading: Icon(Icons.copy, color: AppTheme.primaryColor), title: Text('Copy')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline, color: AppTheme.destructiveColor), title: Text('Delete')),
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
        onPressed: () => _showAddChoiceSheet(context, user.uid),
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
          const Text('Tap + to add a photo or PDF document'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            const Text('Could not load your vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// IMAGE VIEWER — full screen, pinch-to-zoom
// ---------------------------------------------------------------------

class ImageViewerScreen extends StatelessWidget {
  final VaultModel doc;

  const ImageViewerScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (doc.isDataUri) {
      try {
        image = Image.memory(
          base64Decode(doc.fileUrl.split(',').last),
          fit: BoxFit.contain,
        );
      } catch (_) {
        image = const Icon(Icons.broken_image, size: 80, color: Colors.grey);
      }
    } else if (doc.isNetworkUrl) {
      image = Image.network(
        doc.fileUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    } else {
      image = const Icon(Icons.image, size: 80, color: Colors.grey);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(doc.documentName),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(child: image),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${doc.category} • ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(doc.uploadedDate))}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// PDF VIEWER
// ---------------------------------------------------------------------

class PDFViewerScreen extends StatefulWidget {
  final VaultModel doc;

  const PDFViewerScreen({super.key, required this.doc});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  VaultModel get doc => widget.doc;

  Uint8List? _pdfBytes;
  String? _networkUrl;
  bool _parseError = false;

  // Set by onDocumentLoadFailed so a failed render (e.g. the browser
  // silently blocking a cross-origin Storage fetch) shows a real message
  // and a way out, instead of a blank viewer.
  bool _renderFailed = false;
  String? _renderFailedReason;

  bool _openingExternally = false;

  @override
  void initState() {
    super.initState();
    try {
      if (doc.isNetworkUrl) {
        _networkUrl = doc.fileUrl;
      } else if (doc.fileUrl.contains('base64,')) {
        final base64Part = doc.fileUrl.split('base64,').last.trim();
        _pdfBytes = base64Decode(base64Part);
      } else {
        _parseError = true;
      }
    } catch (e) {
      debugPrint('Error preparing PDF source: $e');
      _parseError = true;
    }
  }

  /// Opens the PDF outside the in-app viewer — used both from the app bar
  /// action and as the fallback when in-app rendering fails.
  ///
  /// For a real Storage URL this is a normal browser/external-app
  /// navigation. For the base64 fallback there is no URL to navigate to at
  /// all, so on web the bytes are handed to the browser as a `blob:` URL
  /// (a plain `data:` URL gets silently blocked by Chrome when opened via
  /// script), and on mobile/desktop they're written to a temp file and
  /// opened with the platform's default PDF app.
  Future<void> _openExternally() async {
    if (_openingExternally) return;
    setState(() => _openingExternally = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_networkUrl != null) {
        await launchUrl(Uri.parse(_networkUrl!), mode: LaunchMode.externalApplication);
      } else if (_pdfBytes != null) {
        if (kIsWeb) {
          openBytesInBrowser('application/pdf', _pdfBytes!);
        } else {
          final dir = await getTemporaryDirectory();
          final safeName = doc.documentName.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '_');
          final tempFile = File('${dir.path}/$safeName.pdf');
          await tempFile.writeAsBytes(_pdfBytes!);
          await OpenFile.open(tempFile.path);
        }
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('No file data available to open.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open PDF externally: $e')));
    } finally {
      if (mounted) setState(() => _openingExternally = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _parseError || _renderFailed;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.documentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open externally',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _renderFailed
                          ? 'This PDF could not be rendered in-app'
                              '${_renderFailedReason != null ? ' ($_renderFailedReason)' : ''}. '
                              'Try opening it directly instead.'
                          : 'Unable to open this PDF. Please check that the file is available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openingExternally ? null : _openExternally,
                    icon: _openingExternally
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new, size: 18),
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
          : _networkUrl != null
              ? SizedBox.expand(
                  key: ValueKey('network-$_networkUrl'),
                  child: SfPdfViewer.network(
                    _networkUrl!,
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
                )
              : _pdfBytes != null
                  ? SizedBox.expand(
                      key: ValueKey('memory-${doc.id}'),
                      child: SfPdfViewer.memory(
                        _pdfBytes!,
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
