import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DocSeva brand palette — a blue + green system used consistently across
/// every screen (headers, buttons, links, active states, icons, highlights).
///
/// Semantic exception: `warning` (amber/orange) and `error` (red) are kept
/// outside the blue-green family on purpose. They flag "needs an in-person
/// visit" / destructive actions, and swapping them for blue or green would
/// remove a status cue users rely on and would fail WCAG contrast on our
/// light backgrounds. Every other color in the app maps to this palette.
class AppTheme {
  // Core brand colors — sampled directly from the DocSeva logo artwork.
  static const primaryColor = Color(0xFF2571C0); // Logo Blue — primary actions, links, headers
  static const secondaryColor = Color(0xFF379348); // Logo Green — success/positive, secondary actions
  static const accentColor = Color(0xFF379348);

  // Tonal ramps derived from the two brand colors, used to replace the old
  // ad-hoc Colors.blue[NNN] / Colors.green[NNN] shades throughout the app.
  static const primaryLightest = Color(0xFFE9F1F9); // chip/banner backgrounds
  static const primaryLight = Color(0xFFB3CDE9); // borders, subtle fills
  static const primaryDark = Color(0xFF1A4F86); // emphasis text/icons on light bg

  static const secondaryLightest = Color(0xFFEBF4ED); // chip/banner backgrounds
  static const secondaryLight = Color(0xFFB9D9BF); // borders, subtle fills
  static const secondaryDark = Color(0xFF266732); // emphasis text/icons on light bg

  // Blue → green blend, for gradients / hover states on brand surfaces.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // Semantic colors kept intentionally outside the blue-green system.
  static const warningColor = Color(0xFFED6C02); // "needs in-person visit"
  static const warningLightest = Color(0xFFFFF1E0);
  static const warningLight = Color(0xFFFFD8A8);
  static const errorColor = Color(0xFFD32F2F); // destructive actions

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLightest,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryColor : Colors.grey[600],
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            color: states.contains(WidgetState.selected) ? primaryColor : Colors.grey[600],
          );
        }),
      ),
    );
  }
}
