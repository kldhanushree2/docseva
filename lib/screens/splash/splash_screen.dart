import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    final minSplash = Future.delayed(const Duration(milliseconds: 1500));

    User? user;
    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      user = FirebaseAuth.instance.currentUser;
    }

    await minSplash;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150, errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 100, color: AppTheme.primaryColor)),
            const SizedBox(height: 20),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Doc', style: TextStyle(color: AppTheme.primaryColor)),
                  TextSpan(text: 'Seva', style: TextStyle(color: AppTheme.secondaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Apply smart. Track easy. Store safe.', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
