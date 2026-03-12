import 'package:flutter/material.dart';

/// Decorative M3-style tonal background.
///
/// Renders three soft translucent blobs using primaryContainer,
/// secondaryContainer and tertiaryContainer at low opacity.
/// Wrap this around the Scaffold body content via a Stack.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // ── Blobs ────────────────────────────────────────────────────────
        // Top-right — primary tint
        Positioned(
          right: -size.width * 0.25,
          top: -size.height * 0.08,
          child: _Blob(
            size: size.width * 0.85,
            color: scheme.primaryContainer.withValues(alpha: 0.45),
          ),
        ),

        // Left-center — secondary tint
        Positioned(
          left: -size.width * 0.30,
          top: size.height * 0.28,
          child: _Blob(
            size: size.width * 0.75,
            color: scheme.secondaryContainer.withValues(alpha: 0.30),
          ),
        ),

        // Bottom-right — tertiary tint
        Positioned(
          right: -size.width * 0.20,
          bottom: size.height * 0.05,
          child: _Blob(
            size: size.width * 0.60,
            color: scheme.tertiaryContainer.withValues(alpha: 0.25),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Radial gradient for a softer, more organic look
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
