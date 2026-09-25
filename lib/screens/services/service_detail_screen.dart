import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/gov_service_model.dart';

class ServiceDetailScreen extends StatelessWidget {
  final GovServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: service.officialWebsite));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Official website URL copied to clipboard!')),
    );
  }

  void _launchUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(service.officialWebsite);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showLaunchErrorSnackBar(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showLaunchErrorSnackBar(context);
      }
    }
  }

  void _showLaunchErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Unable to open the official website. Please try again.'),
        action: SnackBarAction(
          label: 'COPY URL',
          textColor: Colors.amber,
          onPressed: () => _copyToClipboard(context),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Description', service.description),

            // Online Application status — whether the application itself can
            // be completed fully online without an in-person visit / wet-ink
            // signature.
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service.onlineApplicable ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: service.onlineApplicable ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    service.onlineApplicable ? Icons.check_circle : Icons.info,
                    color: service.onlineApplicable ? Colors.green[700] : Colors.orange[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.onlineApplicable ? 'Fully Online Application' : 'Needs an In-Person Visit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: service.onlineApplicable ? Colors.green[800] : Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(service.onlineNote, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildSection('Eligibility', service.eligibility),
            _buildSection('Documents Required', service.documentsRequired),
            _buildSection('Fees', service.fees),
            _buildSection('Processing Time', service.processingTime),
            const SizedBox(height: 8),

            // Verified Official Portal Domain Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Official Government Portal:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        SelectableText(
                          service.officialWebsite,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.green),
                    tooltip: 'Copy URL',
                    onPressed: () => _copyToClipboard(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Official Website', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
