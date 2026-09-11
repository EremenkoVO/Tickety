import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../models/pass_record.dart';
import 'pkpass_service.dart';

class WidgetService {
  static Future<void> update() async {
    await HomeWidget.setAppGroupId('group.com.tickety.tickety');
    final passes = await DatabaseHelper.instance.getAllPasses();
    final nearest = _findNearestEvent(passes);
    if (nearest == null) {
      await _saveNoEvent();
    } else {
      await _saveEvent(nearest);
    }
    await HomeWidget.updateWidget(androidName: 'TicketyWidgetProvider');
  }

  static PassRecord? _findNearestEvent(List<PassRecord> passes) {
    final now = DateTime.now();
    PassRecord? nearest;
    DateTime? nearestDate;

    for (final p in passes) {
      final date = p.archiveDate;
      if (p.eventDate == null || date == null || p.isArchivedAt(now)) continue;
      if (nearestDate == null || date.isBefore(nearestDate)) {
        nearest = p;
        nearestDate = date;
      }
    }
    return nearest;
  }

  static Future<void> _saveNoEvent() async {
    await HomeWidget.saveWidgetData<String>('widget_has_event', 'false');
    await HomeWidget.saveWidgetData<String>('widget_image_path', '');
  }

  static Future<void> _saveEvent(PassRecord pass) async {
    String? imagePath;
    try {
      final bytes = await File(pass.filePath).readAsBytes();
      final images = extractPassImages(bytes);
      if (images.strip != null) {
        final dataUri = images.strip!;
        final base64Data = dataUri.contains(',') ? dataUri.split(',').last : dataUri;
        final imageBytes = base64Decode(base64Data);
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/widget_strip.png');
        await file.writeAsBytes(imageBytes);
        imagePath = file.path;
      }
    } catch (_) {}

    await HomeWidget.saveWidgetData<String>('widget_has_event', 'true');
    await HomeWidget.saveWidgetData<String>(
        'widget_event_name', pass.eventName ?? pass.organizationName);
    await HomeWidget.saveWidgetData<String>(
        'widget_date_formatted', _formatDate(pass.eventDate));
    await HomeWidget.saveWidgetData<String>('widget_venue', pass.venueName ?? '');
    await HomeWidget.saveWidgetData<String>('widget_image_path', imagePath ?? '');
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    final lang = PlatformDispatcher.instance.locale.languageCode;
    if (lang == 'ru') {
      const months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
      ];
      final month = months[date.month - 1];
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '${date.day} $month ${date.year}, $time';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final month = months[date.month - 1];
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '$month ${date.day}, ${date.year}, $time';
    }
  }
}
