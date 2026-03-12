import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../models/pass_record.dart';
import '../services/notification_service.dart';
import '../services/pkpass_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class PassDetailScreen extends StatefulWidget {
  final String passId;

  const PassDetailScreen({super.key, required this.passId});

  @override
  State<PassDetailScreen> createState() => _PassDetailScreenState();
}

class _PassDetailScreenState extends State<PassDetailScreen> {
  PassRecord? _pass;
  PassImages? _images;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pass = await DatabaseHelper.instance.getPassById(widget.passId);
      if (pass == null) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context)!.passNotFound;
            _isLoading = false;
          });
        }
        return;
      }
      final bytes = await File(pass.filePath).readAsBytes();
      final images = extractPassImages(bytes);
      if (mounted) {
        setState(() {
          _pass = pass;
          _images = images;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePass() async {
    final l = AppLocalizations.of(context)!;
    final pass = _pass;
    if (pass == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.passDeleteConfirmTitle),
        content: Text(l.passDeleteConfirmMessage(pass.organizationName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.passCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.passDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await deletePassFile(pass.filePath);
      await DatabaseHelper.instance.deletePass(pass.id);
    } catch (_) {
      if (mounted) {
        final l2 = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l2.homeError),
            content: Text(l2.passDeleteError),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() => _isDeleting = false);
      }
      return;
    }
    try {
      await NotificationService.instance.cancelPassNotifications(pass.id);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  String _formatDate(String? iso, Locale locale) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      final isRu = locale.languageCode == 'ru';
      final months = isRu
          ? ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
             'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря']
          : ['January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatDateTime(String? raw, Locale locale) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw);
      final isRu = locale.languageCode == 'ru';
      final months = isRu
          ? ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
             'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря']
          : ['January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'];
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header: close — title — delete
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l.passTicket,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!_isLoading && _pass != null)
                    _isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Semantics(
                            button: true,
                            label: l.passDelete,
                            child: IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: scheme.error),
                              tooltip: l.passDelete,
                              onPressed: _deletePass,
                            ),
                          )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Semantics(
                        label: l.homeLoading,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : _error != null || _pass == null
                      ? _buildError(l, scheme)
                      : _buildContent(l, scheme, locale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l, ColorScheme scheme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _error ?? l.passNotFound,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  Widget _buildContent(
      AppLocalizations l, ColorScheme scheme, Locale locale) {
    final pass = _pass!;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ── Pass card ────────────────────────────────────────────────
          // M3 outlined card variant for the main pass body
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.all(M3Shape.medium),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Strip — decorative, no semantics
                if (_images?.strip != null)
                  ExcludeSemantics(
                    child: AspectRatio(
                      aspectRatio: 375 / 96, // M3 hero image ratio
                      child: _DataUriImage(
                          dataUri: _images!.strip!, fit: BoxFit.cover),
                    ),
                  ),

                // Header: logo + org name
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _buildLogoWidget(scheme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pass.organizationName,
                          // titleLarge per M3 (22/w400)
                          style: tt.titleLarge
                              ?.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),

                // QR code — full-width section
                if (pass.barcodeMessage != null)
                  _QrSection(
                    message: pass.barcodeMessage!,
                    label: l.fieldQrCode,
                    scheme: scheme,
                    tt: tt,
                    dividerColor: scheme.outlineVariant,
                  ),

                // Info fields
                if (pass.description != null)
                  _InfoField(
                    label: l.fieldDescription,
                    value: pass.description!,
                    scheme: scheme,
                    tt: tt,
                  ),
                if (pass.eventName != null)
                  _InfoField(
                    label: l.fieldEvent,
                    value: pass.eventName!,
                    scheme: scheme,
                    tt: tt,
                  ),
                if (pass.venueName != null)
                  _InfoField(
                    label: l.fieldVenue,
                    value: pass.venueName!,
                    scheme: scheme,
                    tt: tt,
                    icon: Icons.location_on_outlined,
                  ),
                if (pass.eventDate != null)
                  _InfoField(
                    label: l.fieldDateTime,
                    value: _formatDateTime(pass.eventDate, locale),
                    scheme: scheme,
                    tt: tt,
                    icon: Icons.schedule_outlined,
                  ),
                if (pass.seats != null)
                  _InfoField(
                    label: l.fieldSeats,
                    value: pass.seats!,
                    scheme: scheme,
                    tt: tt,
                    icon: Icons.chair_outlined,
                  ),
                if (pass.price != null)
                  _InfoField(
                    label: l.fieldPrice,
                    value: pass.price!,
                    scheme: scheme,
                    tt: tt,
                    icon: Icons.sell_outlined,
                  ),
                if (pass.refundInfo != null)
                  _InfoField(
                    label: l.fieldRefund,
                    value: pass.refundInfo!,
                    scheme: scheme,
                    tt: tt,
                  ),
                if (pass.complaintsInfo != null)
                  _InfoField(
                    label: l.fieldComplaints,
                    value: pass.complaintsInfo!,
                    scheme: scheme,
                    tt: tt,
                  ),
                if (pass.expirationDate != null)
                  _InfoField(
                    label: l.fieldValidUntil,
                    value: _formatDate(pass.expirationDate, locale),
                    scheme: scheme,
                    tt: tt,
                    icon: Icons.event_available_outlined,
                    isLast: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWidget(ColorScheme scheme) {
    if (_images?.logo != null) {
      return ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: _DataUriImage(dataUri: _images!.logo!, fit: BoxFit.contain),
          ),
        ),
      );
    }
    final imgData = _images?.icon;
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        child: imgData != null
            ? _DataUriImage(dataUri: imgData, fit: BoxFit.contain)
            : Icon(Icons.confirmation_number_rounded,
                color: scheme.onSecondaryContainer, size: 22),
      ),
    );
  }
}

// ── QR Section ──────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  final String message;
  final String label;
  final ColorScheme scheme;
  final TextTheme tt;
  final Color dividerColor;

  const _QrSection({
    required this.message,
    required this.label,
    required this.scheme,
    required this.tt,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $message',
        child: Column(
          children: [
            Divider(color: dividerColor, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // M3 labelSmall (11/w500) as overline
                  Text(
                    label.toUpperCase(),
                    style: tt.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  // QR container — M3 surface with medium shape
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.all(M3Shape.medium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: message,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Barcode value — labelMedium (monospaced feel)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SelectableText(
                      message,
                      style: tt.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Info field ───────────────────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  final TextTheme tt;
  final IconData? icon;
  final bool isLast;

  const _InfoField({
    required this.label,
    required this.value,
    required this.scheme,
    required this.tt,
    this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: scheme.outlineVariant, height: 1, thickness: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 16 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 16,
                        color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _LinkText(text: value, scheme: scheme, tt: tt),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Link-aware text ──────────────────────────────────────────────────────────

class _LinkText extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  final TextTheme tt;

  const _LinkText(
      {required this.text, required this.scheme, required this.tt});

  // Group 1 — URL, group 2 — email, group 3 — phone (+… international)
  static final _regex = RegExp(
    r'(https?://\S+)'
    r'|([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})'
    r'|(\+\d[\d\s()\-]{6,14}\d)',
  );

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in _regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final raw = m.group(0)!;
      final Uri uri;
      if (m.group(1) != null) {
        uri = Uri.parse(raw);
      } else if (m.group(2) != null) {
        uri = Uri.parse('mailto:$raw');
      } else {
        uri = Uri.parse('tel:${raw.replaceAll(RegExp(r'[^\d+]'), '')}');
      }
      spans.add(TextSpan(
        text: raw,
        style: TextStyle(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(uri),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return RichText(
      text: TextSpan(
        style: tt.bodyLarge?.copyWith(color: scheme.onSurface),
        children: spans,
      ),
    );
  }
}

// ── Image helper ─────────────────────────────────────────────────────────────

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
