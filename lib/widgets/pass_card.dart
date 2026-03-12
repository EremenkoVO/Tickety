import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/pass_record.dart';
import '../services/pkpass_service.dart';

// Deterministic hue from org name — used for strip placeholder
int _stringToHue(String s) {
  int h = 0;
  for (final c in s.codeUnits) {
    h = ((h << 5) - h + c) & 0xFFFFFFFF;
  }
  return h.abs() % 360;
}

Color _stripPlaceholder(String org, ColorScheme scheme) {
  final hue = _stringToHue(org);
  // Blend hue with primary container for a tonal feel
  final base = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.55).toColor();
  return Color.lerp(base, scheme.primaryContainer, 0.4)!;
}

class PassCard extends StatefulWidget {
  final PassRecord pass;
  final VoidCallback onTap;

  const PassCard({super.key, required this.pass, required this.onTap});

  @override
  State<PassCard> createState() => _PassCardState();
}

class _PassCardState extends State<PassCard> {
  PassImages? _images;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(PassCard old) {
    super.didUpdateWidget(old);
    if (old.pass.filePath != widget.pass.filePath) _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final bytes = await File(widget.pass.filePath).readAsBytes();
      if (!mounted) return;
      setState(() => _images = extractPassImages(bytes));
    } catch (_) {}
  }

  String _formatDate(String raw, Locale locale) {
    try {
      final d = DateTime.parse(raw);
      final isRu = locale.languageCode == 'ru';
      final months = isRu
          ? ['янв', 'фев', 'мар', 'апр', 'май', 'июн',
             'июл', 'авг', 'сен', 'окт', 'ноя', 'дек']
          : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
    } catch (_) {
      return raw;
    }
  }

  String _semanticsLabel(Locale locale) {
    final parts = <String>[widget.pass.organizationName];
    if (widget.pass.eventName != null) parts.add(widget.pass.eventName!);
    if (widget.pass.venueName != null) parts.add(widget.pass.venueName!);
    if (widget.pass.eventDate != null) {
      parts.add(_formatDate(widget.pass.eventDate!, locale));
    }
    return parts.join(', ');
  }

  // M3: icon container uses secondaryContainer / onSecondaryContainer
  Widget _buildLeadingIcon(ColorScheme scheme) {
    if (_images?.logo != null) {
      return ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), // M3 small shape
          child: SizedBox(
            width: 40,
            height: 40,
            child: _DataUriImage(dataUri: _images!.logo!, fit: BoxFit.contain),
          ),
        ),
      );
    }
    if (_images?.icon != null) {
      return ExcludeSemantics(
        child: _IconContainer(
          color: scheme.secondaryContainer,
          child: _DataUriImage(
              dataUri: _images!.icon!, fit: BoxFit.contain),
        ),
      );
    }
    return ExcludeSemantics(
      child: _IconContainer(
        color: scheme.secondaryContainer,
        child: Icon(Icons.confirmation_number_rounded,
            color: scheme.onSecondaryContainer, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);

    return Semantics(
      button: true,
      label: _semanticsLabel(locale),
      onTap: widget.onTap,
      excludeSemantics: false,
      // M3 elevated Card — color/shape/elevation come from CardTheme
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Strip banner (decorative) ─────────────────────────
              ExcludeSemantics(
                child: SizedBox(
                  height: 72,
                  child: _images?.strip != null
                      ? _DataUriImage(
                          dataUri: _images!.strip!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: _stripPlaceholder(
                              widget.pass.organizationName, scheme)),
                ),
              ),

              // ── Content ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLeadingIcon(scheme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // org name — titleMedium (16/w500)
                          Text(
                            widget.pass.organizationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(
                                color: scheme.onSurface),
                          ),
                          if (widget.pass.venueName != null) ...[
                            const SizedBox(height: 4),
                            _MetaRow(
                              icon: Icons.location_on_outlined,
                              text: widget.pass.venueName!,
                              scheme: scheme,
                              tt: tt,
                            ),
                          ],
                          if (widget.pass.eventDate != null) ...[
                            const SizedBox(height: 2),
                            _MetaRow(
                              icon: Icons.schedule_outlined,
                              text: _formatDate(
                                  widget.pass.eventDate!, locale),
                              scheme: scheme,
                              tt: tt,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small square container for logo/icon — M3 small shape (8dp)
class _IconContainer extends StatelessWidget {
  final Color color;
  final Widget child;

  const _IconContainer({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        child: child,
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme scheme;
  final TextTheme tt;

  const _MetaRow({
    required this.icon,
    required this.text,
    required this.scheme,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // bodySmall (12/w400) for supporting text per M3
              style:
                  tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      );
}

class _DataUriImage extends StatelessWidget {
  final String dataUri;
  final BoxFit fit;

  const _DataUriImage({required this.dataUri, required this.fit});

  @override
  Widget build(BuildContext context) {
    final comma = dataUri.indexOf(',');
    if (comma == -1) return const SizedBox.shrink();
    final bytes = base64Decode(dataUri.substring(comma + 1));
    return Image.memory(Uint8List.fromList(bytes), fit: fit);
  }
}
