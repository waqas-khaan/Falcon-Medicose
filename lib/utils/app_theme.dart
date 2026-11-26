import 'package:flutter/material.dart';

class AppColors {
  // Falcon Brand Identity
  static const Color primary = Color(0xFF0F243A); // Falcon Executive Navy
  static const Color primaryLight = Color(0xFF0284C7); // Falcon Crisp Blue
  static const Color primaryDark = Color(0xFF071524); // Midnight Dark Navy
  static const Color secondary = Color(0xFF0EA5E9); // Sky Cyan Accent
  static const Color accent = Color(0xFFF58220); // Falcon Brand Orange
  
  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50 Clean Canvas
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBg = Colors.white;
  
  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  
  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  
  // Modern Status Tokens
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color danger = Color(0xFFEF4444); // Rose 500
  static const Color info = Color(0xFF3B82F6); // Royal Blue 500

  // Brand Gradients
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F243A), Color(0xFF1A3B5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryActionGradient = LinearGradient(
    colors: [Color(0xFF0F243A), Color(0xFF0284C7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy backward compatibility mappings
  static const Color deepTeal = primary;
  static const Color teal = primaryLight;
  static const Color gold = accent;
  static const Color bg = background;
  static const Color ink = textPrimary;
}

class AppDecor {
  static final BoxShadow cardShadow = BoxShadow(
    color: const Color(0xFF0F243A).withAlpha(14),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static final BoxShadow subtleShadow = BoxShadow(
    color: const Color(0xFF0F243A).withAlpha(8),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static final BoxShadow floatingShadow = BoxShadow(
    color: const Color(0xFF0F243A).withAlpha(24),
    blurRadius: 24,
    offset: const Offset(0, 8),
  );

  static InputDecoration input(
    String label, {
    IconData? icon,
    String? hint,
    Widget? suffix,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primaryLight, size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
    );
  }

  static BoxDecoration card = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: [cardShadow],
  );

  static BoxDecoration subtleCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: [subtleShadow],
  );

  static AppBar appBar(
    String title, {
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Widget? leading,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
  }

  static Widget badge({
    required String text,
    required Color color,
    IconData? icon,
    double fontSize = 11,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
  );
}
