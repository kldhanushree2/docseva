import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/app_logger.dart';
import '../../core/theme/app_theme.dart';

class DebugLogScreen extends StatelessWidget {
  const DebugLogScreen({super.key});

  Color _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return AppTheme.errorColor;
      case LogLevel.warn:
        return Colors.orange;
      case LogLevel.info:
        return Colors.blueGrey;
    }
  }

  IconData _iconFor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warn:
        return Icons.warning_amber_outlined;
      case LogLevel.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear log',
            onPressed: AppLogger.clear,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogEntry>>(
        valueListenable: AppLogger.logs,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No log entries yet. Try uploading a document or asking the '
                  'AI Assistant something — each step (Storage upload, '
                  'Firestore save, each Gemini model attempt) is logged here '
                  'as it happens, including the exact error if one occurs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          // Newest first.
          final reversed = entries.reversed.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: reversed.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = reversed[index];
              return ListTile(
                dense: true,
                leading: Icon(_iconFor(e.level), color: _colorFor(e.level), size: 20),
                title: Text(e.message, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${e.tag} • ${DateFormat('HH:mm:ss').format(e.time)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
