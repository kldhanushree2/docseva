import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _localName;
  String? _localPhone;
  String? _localDob;
  String? _localGender;
  String? _localAddress;

  void _showEditProfileDialog(BuildContext context, User user, UserModel? currentData) {
    final nameController = TextEditingController(
      text: _localName ?? (currentData?.name.isNotEmpty == true ? currentData!.name : (user.displayName ?? '')),
    );
    final phoneController = TextEditingController(
      text: _localPhone ?? (currentData?.phone.isNotEmpty == true ? currentData!.phone : (user.phoneNumber ?? '')),
    );
    final addressController = TextEditingController(
      text: _localAddress ?? currentData?.address ?? '',
    );
    String dobText = _localDob ?? currentData?.dateOfBirth ?? '';
    String gender = _localGender ?? (currentData?.gender.isNotEmpty == true ? currentData!.gender : 'Prefer not to say');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final initial = dobText.isNotEmpty
                          ? (DateFormat('dd MMM yyyy').tryParse(dobText) ?? DateTime(now.year - 18))
                          : DateTime(now.year - 18);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(now.year - 120),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setDialogState(() => dobText = DateFormat('dd MMM yyyy').format(picked));
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date of Birth', border: OutlineInputBorder()),
                      child: Text(dobText.isNotEmpty ? dobText : 'Tap to select'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: ['Female', 'Male', 'Other', 'Prefer not to say']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => gender = val ?? gender),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                    maxLines: 2,
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
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();
                if (name.isEmpty) return;

                try {
                  // Always update Auth Display Name
                  await user.updateDisplayName(name);

                  if (mounted) {
                    setState(() {
                      _localName = name;
                      _localPhone = phone;
                      _localDob = dobText;
                      _localGender = gender;
                      _localAddress = address;
                    });
                  }

                  // Try updating Firestore
                  bool firestoreSuccess = true;
                  try {
                    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
                      'uid': user.uid,
                      'name': name,
                      'email': user.email ?? '',
                      'phone': phone,
                      'dateOfBirth': dobText,
                      'gender': gender,
                      'address': address,
                      'createdAt': currentData?.createdAt ?? user.metadata.creationTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
                    }, SetOptions(merge: true));
                  } catch (e) {
                    firestoreSuccess = false;
                  }

                  if (dialogContext.mounted) Navigator.pop(dialogContext);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(firestoreSuccess
                            ? 'Profile updated!'
                            : 'Profile updated locally! Enable Firestore rules in Firebase Console to sync with cloud.'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not update profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<UserModel?>(
        future: context.read<AuthService>().getUserProfile(user.uid),
        builder: (context, snapshot) {
          final userData = snapshot.data;

          final displayName = _localName ??
              ((userData?.name != null && userData!.name.isNotEmpty)
                  ? userData.name
                  : (user.displayName != null && user.displayName!.isNotEmpty)
                      ? user.displayName!
                      : _getFallbackNameFromEmail(user.email));

          final phone = _localPhone ??
              ((userData?.phone != null && userData!.phone.isNotEmpty)
                  ? userData.phone
                  : (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                      ? user.phoneNumber!
                      : 'Not provided');

          final joinedTimestamp = (userData?.createdAt != null && userData!.createdAt > 0)
              ? userData.createdAt
              : user.metadata.creationTime?.millisecondsSinceEpoch ?? 0;

          final dob = _localDob ?? (userData?.dateOfBirth.isNotEmpty == true ? userData!.dateOfBirth : 'Not provided');
          final gender = _localGender ?? (userData?.gender.isNotEmpty == true ? userData!.gender : 'Not provided');
          final address = _localAddress ?? (userData?.address.isNotEmpty == true ? userData!.address : 'Not provided');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.secondaryLightest,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, user, userData),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(height: 32),
                _buildProfileItem(Icons.phone, 'Phone', phone),
                _buildProfileItem(Icons.cake_outlined, 'Date of Birth', dob),
                _buildProfileItem(Icons.wc, 'Gender', gender),
                _buildProfileItem(Icons.home_outlined, 'Address', address),
                _buildProfileItem(Icons.calendar_today, 'Joined', _formatDate(joinedTimestamp)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  String _getFallbackNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return 'User';
    final namePart = email.split('@').first;
    return namePart[0].toUpperCase() + namePart.substring(1);
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
