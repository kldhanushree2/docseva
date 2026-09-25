import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/reminder_model.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  void _showAddReminderDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Reminder Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category (e.g. Passport, License)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) => setState(() => selectedPriority = val ?? 'Medium'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('Due Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    // Makes "how will it remind" concrete: shows exactly
                    // when the notification will fire, instead of that
                    // being a silent, invisible 1-day-before calculation.
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(kIsWeb ? Icons.info_outline : Icons.notifications_active_outlined,
                              size: 18, color: AppTheme.primaryDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              kIsWeb
                                  ? 'A reminder will be saved, but on-device push notifications only fire on the Android/iOS app, not on web.'
                                  : 'A notification will alert you on this device at 9:00 AM on '
                                      '${DateFormat('dd MMM yyyy').format(selectedDate.subtract(const Duration(days: 1)))} '
                                      '(1 day before the due date).',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a Title for the reminder')),
                      );
                      return;
                    }

                    // Fires at 9:00 AM the day before the due date, matching
                    // the note shown above in the dialog.
                    final reminderAt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                    ).subtract(const Duration(days: 1)).add(const Duration(hours: 9));

                    final reminder = ReminderModel(
                      id: '',
                      userId: userId,
                      title: title,
                      category: categoryController.text.trim().isEmpty ? 'General' : categoryController.text.trim(),
                      priority: selectedPriority,
                      notes: notesController.text.trim(),
                      expiryDate: selectedDate.millisecondsSinceEpoch,
                      reminderDate: reminderAt.millisecondsSinceEpoch,
                      status: 'active',
                      repeat: 'None',
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );

                    try {
                      final newId = await context.read<FirestoreService>().addReminder(reminder);

                      // Schedule the real on-device notification (Android/iOS
                      // only — flutter_local_notifications has no web
                      // implementation). The notification id must be a
                      // 32-bit int, so derive one deterministically from the
                      // Firestore document id.
                      if (!kIsWeb) {
                        await NotificationService.instance.scheduleReminder(
                          reminderId: newId.hashCode & 0x7fffffff,
                          title: 'DocSeva Reminder: $title',
                          body: reminder.notes.isNotEmpty
                              ? reminder.notes
                              : '${reminder.category} is due on ${DateFormat('dd MMM yyyy').format(selectedDate)}.',
                          scheduledDate: reminderAt,
                        );
                      }

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add reminder: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const Center(child: Text('Please login'));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: StreamBuilder<List<ReminderModel>>(
        stream: context.read<FirestoreService>().getReminders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(reminder.priority),
                    child: const Icon(Icons.alarm, color: Colors.white),
                  ),
                  title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // Previously only showed the title and due date; category,
                  // priority, notes, and when/how it notifies were collected
                  // but never displayed anywhere.
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${reminder.category} • ${reminder.priority} priority'),
                        Text('Due: ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(reminder.expiryDate))}'),
                        Text(
                          kIsWeb
                              ? 'Notifies: Android/iOS app only (not on web)'
                              : 'Notifies: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(reminder.reminderDate))}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                        if (reminder.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(reminder.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (!kIsWeb) {
                        await NotificationService.instance.cancelReminder(reminder.id.hashCode & 0x7fffffff);
                      }
                      if (context.mounted) {
                        await context.read<FirestoreService>().deleteReminder(reminder.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context, user.uid),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No active reminders'),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return AppTheme.primaryColor;
    }
  }
}
