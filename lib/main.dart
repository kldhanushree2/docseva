import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the API key from .env before anything else uses it.
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notification scheduling isn't supported on Flutter Web, so only
  // initialize on real Android/iOS builds.
  if (!kIsWeb) {
    await NotificationService.instance.init();
  }

  // Load the saved Light / Dark / System choice before the first frame so
  // the app never flashes the wrong theme.
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(DocSevaApp(themeProvider: themeProvider));
}
class DocSevaApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const DocSevaApp({super.key, required this.themeProvider});

  /// Dark version of the app theme, built from the same brand colour as the
  /// light theme. If your light theme uses a different font, change the
  /// text theme line below to match.
  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryColor,
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        // Start from the saved Firebase user so screens never briefly think
        // the user is logged out while the session loads.
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: FirebaseAuth.instance.currentUser,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'DocSeva',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: _buildDarkTheme(),
            themeMode: theme.mode,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}