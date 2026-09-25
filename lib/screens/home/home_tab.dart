import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/application_model.dart';
import '../applications/tracker_screen.dart';
import '../reminders/reminders_screen.dart';
import 'ai_assistant_screen.dart';
import '../../core/theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  final Function(int)? onSelectTab;

  const HomeTab({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.description, size: 24, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Doc', style: TextStyle(color: AppTheme.primaryColor)),
                  TextSpan(text: 'Seva', style: TextStyle(color: AppTheme.secondaryColor)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen())),
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Assistant',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Reminders',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              future: user != null ? context.read<AuthService>().getUserProfile(user.uid) : null,
              builder: (context, snapshot) {
                String name = snapshot.data?.name ?? user?.email?.split('@').first ?? 'User';
                return Text('Welcome, $name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 20),
            _buildActionGrid(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen())),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentApplications(context, user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(context, 'Gov Services', Icons.description, AppTheme.primaryColor, () {
          if (onSelectTab != null) {
            onSelectTab!(1);
          }
        }),
        _buildActionCard(context, 'Track Status', Icons.track_changes, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen()));
        }),
        _buildActionCard(context, 'Doc Vault', Icons.lock, AppTheme.secondaryColor, () {
          if (onSelectTab != null) {
            onSelectTab!(2);
          }
        }),
        _buildActionCard(context, 'Reminders', Icons.alarm, AppTheme.primaryDark, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
        }),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApplications(BuildContext context, String? userId) {
    if (userId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No applications added yet.')),
        ),
      );
    }

    return StreamBuilder<List<ApplicationModel>>(
      stream: context.read<FirestoreService>().getApplications(userId),
      builder: (context, snapshot) {
        final apps = snapshot.data ?? [];

        if (apps.isEmpty) {
          return Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.assignment_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No applications added yet.',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen()));
                    },
                    child: const Text('Add Application'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length > 2 ? 2 : apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.assignment, color: Colors.orange),
                title: Text(app.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('App No: ${app.applicationNumber}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen()));
                },
              ),
            );
          },
        );
      },
    );
  }
}
