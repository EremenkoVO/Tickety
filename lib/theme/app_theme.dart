import 'package:flutter/material.dart';

const _seed = Color(0xFF0A7EA4);

/// M3 shape corner radii
class M3Shape {
  static const extraSmall = Radius.circular(4);
  static const small = Radius.circular(8);
  static const medium = Radius.circular(12);
  static const large = Radius.circular(16);
  static const extraLarge = Radius.circular(28);

  static const mediumBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(medium));
  static const largeBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(large));
  static const extraLargeBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(extraLarge));
}

class AppTheme {
  static ThemeData light([ColorScheme? dynamic]) =>
      _build(Brightness.light, dynamic);
  static ThemeData dark([ColorScheme? dynamic]) =>
      _build(Brightness.dark, dynamic);

  static ThemeData _build(Brightness brightness, ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: brightness,
        );

    final tt = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: tt,

      // M3: scaffold uses colorScheme.surface (no hardcoded hex)
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ──────────────────────────────────────────────────────────
      // M3 top app bar: transparent at rest, surfaceContainer on scroll.
      // Title: titleLarge (22sp / w400) — NOT bold.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        foregroundColor: scheme.onSurface,
        titleTextStyle: tt.titleLarge?.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
        actionsIconTheme:
            IconThemeData(color: scheme.onSurfaceVariant, size: 24),
        shadowColor: Colors.transparent,
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      // M3 elevated card: surfaceContainerLow, elevation 1, shape medium (12dp)
      cardTheme: CardThemeData(
        elevation: 1,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: M3Shape.mediumBorder,
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Filled Button ────────────────────────────────────────────────────
      // M3: stadium shape, height 40, padding h:24, labelLarge text
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: tt.labelLarge,
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: tt.labelLarge,
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: tt.labelLarge,
        ),
      ),

      // ── Icon Button ──────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      // M3 FAB: primaryContainer / onPrimaryContainer, shape large (16dp)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: const StadiumBorder(),
        extendedPadding:
            const EdgeInsetsDirectional.only(start: 16, end: 20),
        extendedIconLabelSpacing: 8,
        extendedTextStyle: tt.labelLarge,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      // M3: extraLarge shape (28dp), surface color
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: M3Shape.extraLargeBorder,
        titleTextStyle:
            tt.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle:
            tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            tt.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(M3Shape.extraSmall),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(M3Shape.small),
        ),
        labelStyle: tt.labelLarge,
      ),

      // ── Page transitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// M3 type scale — exact spec values.
  ///
  /// Key rule: display/headline = w400 (regular);
  /// titleLarge = w400; titleM/S = w500; labels = w500; body = w400.
  static TextTheme _textTheme() => const TextTheme(
        // Display
        displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            height: 64 / 57,
            letterSpacing: -0.25),
        displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            height: 52 / 45,
            letterSpacing: 0),
        displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            height: 44 / 36,
            letterSpacing: 0),

        // Headline  ← w400 (regular), NOT bold
        headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 40 / 32,
            letterSpacing: 0),
        headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            height: 36 / 28,
            letterSpacing: 0),
        headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 32 / 24,
            letterSpacing: 0),

        // Title
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400, // w400 per M3 spec
            height: 28 / 22,
            letterSpacing: 0),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 24 / 16,
            letterSpacing: 0.15),
        titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
            letterSpacing: 0.1),

        // Body
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            letterSpacing: 0.5),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
            letterSpacing: 0.25),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: 0.4),

        // Label
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
            letterSpacing: 0.1),
        labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            letterSpacing: 0.5),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 16 / 11,
            letterSpacing: 0.5),
      );
}
