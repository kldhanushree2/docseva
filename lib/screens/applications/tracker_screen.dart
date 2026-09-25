import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/application_model.dart';

class OfficialServiceInfo {
  final String serviceName;
  final String departmentName;
  final String officialSource;
  final String officialUrl;

  const OfficialServiceInfo({
    required this.serviceName,
    required this.departmentName,
    required this.officialSource,
    required this.officialUrl,
  });
}

const List<OfficialServiceInfo> kOfficialGovServices = [
  OfficialServiceInfo(
    serviceName: 'Aadhaar Card (UIDAI)',
    departmentName: 'Unique Identification Authority of India',
    officialSource: 'Official myAadhaar Portal (uidai.gov.in)',
    officialUrl: 'https://myaadhaar.uidai.gov.in/',
  ),
  OfficialServiceInfo(
    serviceName: 'PAN Card (Income Tax / Protean)',
    departmentName: 'Income Tax Department / Protean eGov (formerly NSDL)',
    officialSource: 'Official Income Tax e-Filing Portal (incometax.gov.in)',
    officialUrl: 'https://www.incometax.gov.in/iec/foportal/',
  ),
  OfficialServiceInfo(
    serviceName: 'Passport (Passport Seva)',
    departmentName: 'Ministry of External Affairs',
    officialSource: 'Official Passport Seva Portal (passportindia.gov.in)',
    // Deliberately the root domain, not a deep "track status" path: Passport
    // Seva serves its status tracker from rotating load-balanced subdomains
    // (portal2/portal5/portal6.passportindia.gov.in), so any fixed deep link
    // 404s unpredictably. From the homepage, click "Track Application Status".
    officialUrl: 'https://www.passportindia.gov.in/',
  ),
  OfficialServiceInfo(
    serviceName: 'Driving License / RC (Parivahan)',
    departmentName: 'Ministry of Road Transport & Highways',
    officialSource: 'Official Sarathi Parivahan Portal (sarathi.parivahan.gov.in)',
    officialUrl: 'https://sarathi.parivahan.gov.in/',
  ),
  OfficialServiceInfo(
    serviceName: 'Voter ID (ECI)',
    departmentName: 'Election Commission of India',
    officialSource: 'Official Voter Services Portal (voters.eci.gov.in)',
    officialUrl: 'https://voters.eci.gov.in/track-application-status',
  ),
  OfficialServiceInfo(
    serviceName: 'Tamil Nadu e-District / e-Sevai',
    departmentName: 'Tamil Nadu e-Governance Agency (TNeGA)',
    officialSource: 'Official Tamil Nadu e-District Portal (edistrict.tn.gov.in)',
    officialUrl: 'https://edistrict.tn.gov.in/',
  ),
  OfficialServiceInfo(
    serviceName: 'Other Government Service',
    departmentName: 'National Portal of India',
    officialSource: 'Official Government Portal (india.gov.in)',
    officialUrl: 'https://india.gov.in/',
  ),
];

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _appNumberController = TextEditingController();
  OfficialServiceInfo _selectedService = kOfficialGovServices.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _appNumberController.dispose();
    super.dispose();
  }

  OfficialServiceInfo _getServiceForDoc(String documentName) {
    return kOfficialGovServices.firstWhere(
      (s) => s.serviceName == documentName,
      orElse: () => kOfficialGovServices.last,
    );
  }

  void _launchOfficialWebsite(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open official URL: $url')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching official portal: $e')),
        );
      }
    }
  }

  Future<void> _addApplication(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    final appNum = _appNumberController.text.trim();
    if (appNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Application Number.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    final app = ApplicationModel(
      id: '',
      applicationNumber: appNum,
      userId: userId,
      userName: FirebaseAuth.instance.currentUser?.displayName ?? '',
      documentName: _selectedService.serviceName,
      department: _selectedService.departmentName,
      status: 'Pending Official Portal Verification',
      appliedDate: todayStr,
      expectedDate: '',
      remarks: _selectedService.officialSource,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      acknowledgementPdf: _selectedService.officialUrl,
      timeline: const [],
    );

    try {
      await context.read<FirestoreService>().addApplication(app);
      _appNumberController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete(BuildContext context, ApplicationModel app) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Application'),
          content: const Text('Are you sure you want to delete this application?'),
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
                  final targetId = app.id.isNotEmpty ? app.id : app.applicationNumber;
                  await context.read<FirestoreService>().deleteApplication(targetId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Application deleted from saved list.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete application: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const Center(child: Text('Please login to track applications'));

    return Scaffold(
      appBar: AppBar(title: const Text('Track Applications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Track Official Application',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<OfficialServiceInfo>(
                        initialValue: _selectedService,
                        decoration: const InputDecoration(
                          labelText: 'Select Government Service',
                          border: OutlineInputBorder(),
                        ),
                        items: kOfficialGovServices.map((service) {
                          return DropdownMenuItem(
                            value: service,
                            child: Text(service.serviceName, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedService = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _appNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Application / Acknowledgement Number',
                          hintText: 'Enter real application number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter application number';
                          }
                          if (val.trim().length < 4) {
                            return 'Application number is too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _addApplication(user.uid),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_task),
                        label: const Text('Save & Verify Application'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saved Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ApplicationModel>>(
              stream: context.read<FirestoreService>().getApplications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final apps = snapshot.data ?? [];

                if (apps.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No applications added yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final serviceInfo = _getServiceForDoc(app.documentName);
                    final officialUrl = app.acknowledgementPdf.isNotEmpty ? app.acknowledgementPdf : serviceInfo.officialUrl;
                    final sourceText = app.remarks.startsWith('Source:') ? app.remarks : 'Source: ${serviceInfo.officialSource}';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    app.documentName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Delete Application',
                                  onPressed: () => _confirmDelete(context, app),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildInfoRow('Application Number', app.applicationNumber),
                            _buildInfoRow('Department', app.department),
                            _buildInfoRow('Saved Date', app.appliedDate),
                            const SizedBox(height: 8),
                            Text(
                              sourceText,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 20, color: Colors.amber[900]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Verification requires authentication (CAPTCHA / OTP) on official government website.',
                                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchOfficialWebsite(context, officialUrl),
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                    label: const Text('Open Official Website'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(context, app),
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
