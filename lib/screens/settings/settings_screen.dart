import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  PermissionStatus? _notificationStatus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When the user comes back from the phone's system settings, re-check the
  // permission so the screen always shows the real current state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.notification.status;
      if (mounted) setState(() => _notificationStatus = status);
    } catch (_) {
      // Leave the status unknown if the platform can't report it.
    }
  }

  Future<void> _requestNotifications() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final current = await Permission.notification.status;
      if (current.isPermanentlyDenied) {
        // Android will not show the pop-up again, so send the user to the
        // app's page in system settings.
        await openAppSettings();
      } else {
        final result = await Permission.notification.request();
        if (mounted) setState(() => _notificationStatus = result);
        if (result.isPermanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications are blocked. Tap "Open settings" to allow them.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not change this permission: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of DocSeva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ---------------------------------------------------------
          // APPEARANCE
          // ---------------------------------------------------------
          _sectionHeader('Appearance'),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose Light, Dark, or follow your phone\'s setting.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto, size: 18),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode, size: 18),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode, size: 18),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeProvider.mode},
                      onSelectionChanged: (selection) => themeProvider.setMode(selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // PERMISSIONS
          // ---------------------------------------------------------
          _sectionHeader('Permissions'),
          _card(
            child: Column(
              children: [
                _notificationTile(scheme),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.folder_open_outlined, color: scheme.primary),
                  title: const Text('Files & photos'),
                  subtitle: const Text(
                    'No permission needed. DocSeva only opens the files you choose yourself.',
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                if (!kIsWeb) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings_applications_outlined, color: scheme.primary),
                    title: const Text('Open app settings'),
                    subtitle: const Text('Change any permission in your phone\'s settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: openAppSettings,
                  ),
                ],
              ],
            ),
          ),

          // ---------------------------------------------------------
          // ACCOUNT
          // ---------------------------------------------------------
          _sectionHeader('Account'),
          _card(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Log out', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
              onTap: _confirmLogout,
            ),
          ),

          // ---------------------------------------------------------
          // ABOUT
          // ---------------------------------------------------------
          _sectionHeader('About'),
          _card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('DocSeva'),
                  subtitle: Text('Apply smart. Track easy. Store safe.'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _notificationTile(ColorScheme scheme) {
    if (kIsWeb) {
      return const ListTile(
        leading: Icon(Icons.notifications_off_outlined),
        title: Text('Notifications'),
        subtitle: Text('Reminders are available in the Android app only.'),
      );
    }

    final status = _notificationStatus;
    final granted = status?.isGranted ?? false;
    final blocked = status?.isPermanentlyDenied ?? false;

    String subtitle;
    if (status == null) {
      subtitle = 'Checking...';
    } else if (granted) {
      subtitle = 'Allowed. You will get reminders about deadlines and renewals.';
    } else if (blocked) {
      subtitle = 'Blocked. Open settings to allow reminders.';
    } else {
      subtitle = 'Needed to send you document reminders.';
    }

    Widget? trailing;
    if (status == null) {
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (granted) {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else {
      trailing = FilledButton.tonal(
        onPressed: _busy ? null : _requestNotifications,
        child: Text(blocked ? 'Open settings' : 'Allow'),
      );
    }

    return ListTile(
      leading: Icon(
        granted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
        color: granted ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: const Text('Notifications'),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
