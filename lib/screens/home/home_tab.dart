import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/application_model.dart';
import '../../models/vault_model.dart';
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
                  TextSpan(text: 'Seva', style: TextStyle(color: AppTheme.secondaryDark)),
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
          GestureDetector(
            onTap: () => onSelectTab?.call(3),
            child: const Padding(
              padding: EdgeInsets.only(right: 16, left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            FutureBuilder<UserModel?>(
              future: user != null ? context.read<AuthService>().getUserProfile(user.uid) : null,
              builder: (context, snapshot) {
                String name = snapshot.data?.name ?? user?.email?.split('@').first ?? 'User';
                return Text('Welcome back, $name', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary));
              },
            ),
            const SizedBox(height: 2),
            Text('Manage your government documents easily', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _buildHighlightCards(context, user?.uid),
            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildQuickActionsRow(context),
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

  // ---------------------------------------------------------------------
  // TWO-CARD HIGHLIGHT ROW (Applications + Doc Vault)
  // ---------------------------------------------------------------------

  Widget _buildHighlightCards(BuildContext context, String? userId) {
    return Row(
      children: [
        Expanded(
          child: userId == null
              ? _highlightCard(
                  icon: Icons.assignment_outlined,
                  badge: '0',
                  caption: 'APPLICATIONS',
                  title: 'In Progress',
                  bgColor: AppTheme.secondaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen())),
                )
              : StreamBuilder<List<ApplicationModel>>(
                  stream: context.read<FirestoreService>().getApplications(userId),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return _highlightCard(
                      icon: Icons.assignment_outlined,
                      badge: '$count',
                      caption: 'APPLICATIONS',
                      title: 'In Progress',
                      bgColor: AppTheme.secondaryColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen())),
                    );
                  },
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: userId == null
              ? _highlightCard(
                  icon: Icons.lock_outline,
                  badge: '0',
                  caption: 'DOC VAULT',
                  title: 'Files Saved',
                  bgColor: AppTheme.teal,
                  onTap: () => onSelectTab?.call(2),
                )
              : StreamBuilder<List<VaultModel>>(
                  stream: context.read<FirestoreService>().getVaultDocuments(userId),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return _highlightCard(
                      icon: Icons.lock_outline,
                      badge: '$count',
                      caption: 'DOC VAULT',
                      title: 'Files Saved',
                      bgColor: AppTheme.teal,
                      onTap: () => onSelectTab?.call(2),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _highlightCard({
    required IconData icon,
    required String badge,
    required String caption,
    required String title,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              caption,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // QUICK ACTIONS (3-across icon row)
  // ---------------------------------------------------------------------

  // Real destinations mapped to the spec's 4-color quick-action scheme
  // (Services→Blue, Track→Green, Documents→Teal, Guides→Dark Blue). This
  // app doesn't have a separate "Guides" screen — the Services tab already
  // *is* the step-by-step government service guide — so the 4th slot here
  // is Reminders, a real distinct feature, kept in dark blue.
  Widget _buildQuickActionsRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                'Services',
                Icons.description_outlined,
                AppTheme.primaryBlue,
                AppTheme.lightBlue,
                () {
                  if (onSelectTab != null) onSelectTab!(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                'Track Application',
                Icons.track_changes,
                AppTheme.primaryGreen,
                AppTheme.lightGreen,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                'My Documents',
                Icons.folder_outlined,
                AppTheme.teal,
                AppTheme.lightTeal,
                () => onSelectTab?.call(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                'Reminders',
                Icons.alarm,
                AppTheme.darkBlue,
                AppTheme.lightBlue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    Color bgTint,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RECENT APPLICATIONS
  // ---------------------------------------------------------------------

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
                leading: const Icon(Icons.assignment, color: AppTheme.secondaryDark),
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
