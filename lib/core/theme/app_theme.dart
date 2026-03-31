import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color Palette ────────────────────────────────────────────────────────
  static const _primaryHue = Color(0xFF6C63FF);   // Soft indigo/purple
  static const _primaryLight = Color(0xFF9F97FF);
  static const _accent = Color(0xFFFF6584);        // Coral accent
  static const _success = Color(0xFF4CAF7D);       // Green for Done
  static const _warning = Color(0xFFFFB74D);       // Amber for In Progress
  static const _info = Color(0xFF64B5F6);          // Blue for To-Do
  static const _danger = Color(0xFFEF5350);        // Red for delete / blocked

  // Dark surface tokens
  static const _darkBg = Color(0xFF0F0F1A);
  static const _darkSurface = Color(0xFF1A1A2E);
  static const _darkCard = Color(0xFF22223A);
  static const _darkBorder = Color(0xFF2E2E50);
  static const _darkMuted = Color(0xFF8888AA);

  // Light surface tokens
  static const _lightBg = Color(0xFFF4F4FC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightCard = Color(0xFFF0F0FA);
  static const _lightBorder = Color(0xFFDDDDF0);
  static const _lightMuted = Color(0xFF9898B8);

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const statusColors = {
    'todo': _info,
    'inProgress': _warning,
    'done': _success,
  };

  static Color statusColor(String statusName) =>
      statusColors[statusName] ?? _info;

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: _primaryHue,
        secondary: _accent,
        surface: _darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: _danger,
      ),
      scaffoldBackgroundColor: _darkBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryHue, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: _darkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: _darkMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryHue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkCard,
        selectedColor: _primaryHue,
        side: const BorderSide(color: _darkBorder),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
      extensions: const [AppColors.dark],
    );
  }

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: _primaryHue,
        secondary: _accent,
        surface: _lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1A1A2E),
        error: _danger,
      ),
      scaffoldBackgroundColor: _lightBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1A1A2E),
        displayColor: const Color(0xFF1A1A2E),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      cardTheme: CardTheme(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryHue, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: _lightMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: _lightMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryHue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightCard,
        selectedColor: _primaryHue,
        side: const BorderSide(color: _lightBorder),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF1A1A2E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme:
          const DividerThemeData(color: _lightBorder, thickness: 1),
      extensions: const [AppColors.light],
    );
  }
}

// ─── Theme Extension ──────────────────────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color muted;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final Color blockedOverlay;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.muted,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.blockedOverlay,
  });

  static const dark = AppColors(
    bg: Color(0xFF0F0F1A),
    surface: Color(0xFF1A1A2E),
    card: Color(0xFF22223A),
    border: Color(0xFF2E2E50),
    muted: Color(0xFF8888AA),
    primary: Color(0xFF6C63FF),
    primaryLight: Color(0xFF9F97FF),
    accent: Color(0xFFFF6584),
    success: Color(0xFF4CAF7D),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
    danger: Color(0xFFEF5350),
    blockedOverlay: Color(0x99000000),
  );

  static const light = AppColors(
    bg: Color(0xFFF4F4FC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF0F0FA),
    border: Color(0xFFDDDDF0),
    muted: Color(0xFF9898B8),
    primary: Color(0xFF6C63FF),
    primaryLight: Color(0xFF9F97FF),
    accent: Color(0xFFFF6584),
    success: Color(0xFF4CAF7D),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
    danger: Color(0xFFEF5350),
    blockedOverlay: Color(0x55FFFFFF),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? border,
    Color? muted,
    Color? primary,
    Color? primaryLight,
    Color? accent,
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? blockedOverlay,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      blockedOverlay: blockedOverlay ?? this.blockedOverlay,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      blockedOverlay: Color.lerp(blockedOverlay, other.blockedOverlay, t)!,
    );
  }
}
