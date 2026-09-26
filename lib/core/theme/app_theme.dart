import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DocSeva brand palette — Blue + Green + Teal, matching the project's
/// design spec. **No red is used anywhere in this app.** Destructive
/// actions (delete, logout) use a neutral dark gray instead of red, and
/// anywhere an "alert" color would normally be red, blue or green is used
/// instead, per the design spec.
class AppTheme {
  // ---- Blue family (primary — actions, links, headers, "Services") ----
  static const primaryBlue = Color(0xFF1565C0);
  static const darkBlue = Color(0xFF0D47A1);
  static const secondaryBlue = Color(0xFF1976D2);
  static const lightBlue = Color(0xFFE3F2FD);

  // ---- Green family (secondary — success, "Track", positive states) ----
  static const primaryGreen = Color(0xFF2E7D32);
  static const secondaryGreen = Color(0xFF43A047);
  static const lightGreen = Color(0xFFE8F5E9);

  // ---- Teal (tertiary accent — "Documents"/vault) ----
  static const teal = Color(0xFF00897B);
  static const tealDark = Color(0xFF00695C);
  static const lightTeal = Color(0xFFE0F2F1);

  // ---- Neutrals ----
  static const backgroundColor = Color(0xFFF4F8FC);
  static const cardColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF12304A);
  static const textSecondary = Color(0xFF607D8B);
  static const borderColor = Color(0xFFD9E3EC);

  // ---- Status ----
  static const successColor = Color(0xFF2E7D32);
  static const warningColor = Color(0xFFED6C02); // "needs in-person visit" — amber, not red
  static const warningLightest = Color(0xFFFFF1E0);
  static const warningLight = Color(0xFFFFD8A8);

  /// Neutral dark gray for destructive actions (Delete, Logout) and their
  /// confirmation dialogs. Deliberately not red, per the design spec.
  static const destructiveColor = Color(0xFF546575);
  static const destructiveLightest = Color(0xFFECEFF1);

  // ---------------------------------------------------------------------
  // Back-compatible aliases — existing screens reference these names.
  // Keeping them means the whole app repaints from this one file.
  // ---------------------------------------------------------------------
  static const primaryColor = primaryBlue;
  static const primaryLightest = lightBlue;
  static const primaryLight = secondaryBlue;
  static const primaryDark = darkBlue;

  static const secondaryColor = primaryGreen;
  static const secondaryLightest = lightGreen;
  static const secondaryLight = secondaryGreen;
  static const secondaryDark = Color(0xFF1B5E20); // darker green for emphasis text/icons

  static const accentColor = teal;

  /// Kept for any old call site still referencing `errorColor` for a
  /// generic "something's wrong" icon/message — intentionally blue, not
  /// red, per the design spec ("if an alert is required, use blue or
  /// green"). Actual destructive actions use `destructiveColor` instead.
  static const errorColor = darkBlue;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryGreen],
  );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      secondary: primaryGreen,
      tertiary: teal,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black12,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryBlue),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryBlue),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: lightBlue,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryBlue : textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            color: states.contains(WidgetState.selected) ? primaryBlue : textSecondary,
          );
        }),
      ),
    );
  }
}
