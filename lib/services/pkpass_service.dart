import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/pass_record.dart';
import 'notification_service.dart';

const _uuid = Uuid();

const _venueKeys = [
  'venue', 'location', 'place', 'место', 'локация', 'адрес', 'arena', 'hall', 'venue_name'
];
const _dateTimeKeys = [
  'date', 'time', 'datetime', 'eventdate', 'event_date', 'session_date', 'время', 'дата', 'начало'
];
const _priceKeys = ['price', 'amount', 'cost', 'facevalue', 'цена', 'стоимость'];
const _refundKeys = [
  'refund', 'return', 'возврат', 'refundpolicy', 'refund_policy', 'условия возврата'
];
const _complaintsKeys = [
  'complaints', 'complaints_value', 'вопросы', 'жалобы', 'поддержка'
];

class PassImages {
  final String? strip;
  final String? logo;
  final String? icon;

  const PassImages({this.strip, this.logo, this.icon});
}

sealed class AddPassResult {}

class AddPassSuccess extends AddPassResult {
  final PassRecord pass;
  AddPassSuccess(this.pass);
}

class AddPassCancelled extends AddPassResult {}

class AddPassError extends AddPassResult {
  final String message;
  AddPassError(this.message);
}

Future<Directory> _getPassesDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final passesDir = Directory(p.join(appDir.path, 'passes'));
  if (!await passesDir.exists()) {
    await passesDir.create(recursive: true);
  }
  return passesDir;
}

Future<String> _copyToAppStorage(String sourcePath) async {
  final dir = await _getPassesDir();
  final id = _uuid.v4();
  final dest = p.join(dir.path, '$id.pkpass');
  await File(sourcePath).copy(dest);
  return dest;
}

String _computeHash(List<int> bytes) => sha256.convert(bytes).toString();

Archive _loadArchive(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

PassImages extractPassImages(List<int> bytes) {
  final archive = _loadArchive(bytes);

  String? extractImage(List<String> candidates) {
    for (final name in candidates) {
      final file = archive.findFile(name) ?? archive.findFile('en.lproj/$name');
      if (file != null && file.isFile) {
        final data = file.content as List<int>;
        return 'data:image/png;base64,${base64Encode(data)}';
      }
    }
    return null;
  }

  return PassImages(
    strip: extractImage(['strip@2x.png', 'strip.png']),
    logo: extractImage(['logo@2x.png', 'logo.png']),
    icon: extractImage(['icon@2x.png', 'icon.png']),
  );
}

Map<String, dynamic> _readPassJson(List<int> bytes) {
  final archive = _loadArchive(bytes);
  final passFile = archive.findFile('pass.json');
  if (passFile == null) throw Exception('pass.json not found in pkpass');
  final text = utf8.decode(passFile.content as List<int>);
  final json = jsonDecode(text) as Map<String, dynamic>;
  if (json['serialNumber'] == null ||
      json['passTypeIdentifier'] == null ||
      json['organizationName'] == null) {
    throw Exception('Invalid pass.json: missing required fields');
  }
  return json;
}

Map<String, String> _readPassStrings(List<int> bytes, Locale locale) {
  final archive = _loadArchive(bytes);
  final lang = locale.languageCode;
  final preferred = (lang == 'ru') ? 'ru' : 'en';
  final fallback = preferred == 'ru' ? 'en' : 'ru';

  ArchiveFile? tryLocale(String l) =>
      archive.findFile('$l.lproj/strings') ??
      archive.findFile('$l.lproj/pass.strings');

  final stringsFile = tryLocale(preferred) ?? tryLocale(fallback);
  if (stringsFile == null || !stringsFile.isFile) return {};
  final text = utf8.decode(stringsFile.content as List<int>);
  return _parseStringsFile(text);
}

Map<String, String> _parseStringsFile(String content) {
  final result = <String, String>{};
  final re = RegExp(r'"([^"]+)"\s*=\s*"');
  for (final match in re.allMatches(content)) {
    final key = match.group(1)!;
    final valueStart = match.end;
    final end = content.indexOf('";', valueStart);
    if (end == -1) continue;
    final value = content
        .substring(valueStart, end)
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .trim();
    result[key] = value;
  }
  return result;
}

String? _resolveString(String? raw, Map<String, String> strings) {
  if (raw == null || raw.isEmpty) return null;
  return strings[raw] ?? raw;
}

List<Map<String, dynamic>> _collectFields(Map<String, dynamic> json) {
  final block =
      (json['eventTicket'] ?? json['generic']) as Map<String, dynamic>?;
  if (block == null) return [];
  final result = <Map<String, dynamic>>[];
  for (final key in [
    'headerFields', 'primaryFields', 'secondaryFields',
    'auxiliaryFields', 'backFields'
  ]) {
    final list = block[key];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) result.add(item);
      }
    }
  }
  return result;
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

String? _stripHtml(String? text) {
  if (text == null || text.isEmpty) return text;
  return text
      // <a href="url">label</a> → "label url" (or just "url" if label == url)
      .replaceAllMapped(
        RegExp(
          r'''<a\b[^>]*\bhref=['"]([^'"]+)['"][^>]*>(.*?)</a>''',
          caseSensitive: false,
          dotAll: true,
        ),
        (m) {
          final href = m.group(1)!.trim();
          final label = m.group(2)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
          if (label.isEmpty || label == href) return href;
          return '$label $href';
        },
      )
      // Block-level tags → newline so paragraphs stay readable
      .replaceAll(
          RegExp(r'<(br|p|div|li|h[1-6])\b[^>]*/?>',
              caseSensitive: false),
          '\n')
      // Strip all remaining tags
      .replaceAll(RegExp(r'<[^>]+>'), '')
      // HTML entities
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      // Collapse runs of spaces (but keep newlines)
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}

String? _findFieldValue(
    List<Map<String, dynamic>> fields, List<String> keys) {
  for (final f in fields) {
    final key = _norm((f['key'] ?? '').toString());
    final label = _norm((f['label'] ?? '').toString());
    final value = (f['value'] ?? '').toString().trim();
    if (value.isEmpty) continue;
    for (final k in keys) {
      if (key.contains(_norm(k)) || label.contains(_norm(k))) return value;
    }
  }
  return null;
}

String? _findFieldValueByKey(
    List<Map<String, dynamic>> fields, String exactKey) {
  final keyNorm = exactKey.toLowerCase().trim();
  for (final f in fields) {
    if ((f['key'] ?? '').toString().toLowerCase() == keyNorm) {
      final v = (f['value'] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
  }
  return null;
}

Map<String, dynamic>? _findFieldByKey(
    List<Map<String, dynamic>> fields, String exactKey) {
  final keyNorm = exactKey.toLowerCase().trim();
  for (final f in fields) {
    if ((f['key'] ?? '').toString().toLowerCase() == keyNorm) return f;
  }
  return null;
}

String? _extractVenue(
    Map<String, dynamic> json, List<Map<String, dynamic>> fields) {
  final locations = json['locations'];
  if (locations is List && locations.isNotEmpty) {
    final texts = locations
        .whereType<Map>()
        .map((l) => (l['relevantText'] ?? '').toString().trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (texts.isNotEmpty) return texts.join(', ');
  }
  final venueName = _findFieldValueByKey(fields, 'venue_name') ??
      _findFieldValueByKey(fields, 'venue-name');
  final hall = _findFieldValueByKey(fields, 'hall');
  if (venueName != null && hall != null) return '$venueName, $hall';
  if (venueName != null) return venueName;
  if (hall != null) return hall;
  return _findFieldValue(fields, _venueKeys);
}

String? _formatPrice(Map<String, dynamic>? field) {
  if (field == null || field['value'] == null) return null;
  final raw = field['value'];
  final parsed = raw is double
      ? raw
      : raw is int
          ? raw.toDouble()
          : double.tryParse(raw.toString());
  if (parsed == null) return raw.toString();
  final currency = (field['currencyCode'] ?? '').toString().trim();
  if (currency.isNotEmpty) {
    final formatted = parsed.toStringAsFixed(0);
    return currency == 'RUB' ? '$formatted ₽' : '$formatted $currency';
  }
  return parsed.toStringAsFixed(2);
}

PassRecord _buildPassRecord(
  Map<String, dynamic> json,
  String uuid,
  String filePath,
  String hash,
  Map<String, String> strings,
) {
  final fields = _collectFields(json);
  final venueName = _extractVenue(json, fields);
  final eventDate = _findFieldValueByKey(fields, 'session_date') ??
      _findFieldValue(fields, _dateTimeKeys) ??
      json['relevantDate']?.toString();
  final eventName = _findFieldValueByKey(fields, 'event_name') ??
      _findFieldValueByKey(fields, 'event-name');
  final seats = _findFieldValueByKey(fields, 'seats') ??
      _findFieldValueByKey(fields, 'row') ??
      _findFieldValue(fields, ['seats', 'seat', 'места']);
  final priceField = _findFieldByKey(fields, 'price');
  final price = _formatPrice(priceField) ??
      _resolveString(_findFieldValue(fields, _priceKeys), strings);
  final refundInfo =
      _resolveString(_findFieldValue(fields, _refundKeys), strings);
  final complaintsInfo = _resolveString(
      _findFieldValueByKey(fields, 'complaints') ??
          _findFieldValue(fields, _complaintsKeys),
      strings);

  final barcode = json['barcode'] as Map<String, dynamic>?;

  return PassRecord(
    id: uuid,
    serialNumber: json['serialNumber'].toString(),
    passTypeIdentifier: json['passTypeIdentifier'].toString(),
    organizationName: _stripHtml(json['organizationName'].toString())!,
    description: _stripHtml(json['description']?.toString()),
    barcodeMessage: barcode?['message']?.toString(),
    barcodeFormat: barcode?['format']?.toString(),
    expirationDate: json['expirationDate']?.toString(),
    venueName: _stripHtml(_resolveString(venueName, strings)),
    eventDate: _resolveString(eventDate, strings),
    eventName: _stripHtml(_resolveString(eventName, strings)),
    seats: _stripHtml(_resolveString(seats, strings)),
    price: _stripHtml(price),
    refundInfo: _stripHtml(refundInfo),
    complaintsInfo: _stripHtml(complaintsInfo),
    filePath: filePath,
    hash: hash,
    createdAt: DateTime.now().toIso8601String(),
  );
}

Future<AddPassResult> _processPassFile(
    String sourcePath, Locale locale) async {
  final destPath = await _copyToAppStorage(sourcePath);
  final bytes = await File(destPath).readAsBytes();
  final json = _readPassJson(bytes);
  final strings = _readPassStrings(bytes, locale);
  final hash = _computeHash(bytes);
  final id = _uuid.v4();

  final pass = _buildPassRecord(json, id, destPath, hash, strings);
  await DatabaseHelper.instance.upsertPass(pass);

  final saved = await DatabaseHelper.instance
      .getPassByUniqueKey(pass.passTypeIdentifier, pass.serialNumber);
  final passToReturn = saved ?? pass;

  await NotificationService.instance.requestPermissions();
  await NotificationService.instance
      .schedulePassNotifications(passToReturn, locale);

  return AddPassSuccess(passToReturn);
}

Future<AddPassResult> addPassFromPicker(Locale locale) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pkpass'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return AddPassCancelled();

    final sourcePath = result.files.first.path;
    if (sourcePath == null) return AddPassError('Could not access file');

    return await _processPassFile(sourcePath, locale);
  } catch (e) {
    return AddPassError(e.toString());
  }
}

/// Import a .pkpass file that was already placed on disk (e.g. opened from
/// the file system via an intent / URL context).
Future<AddPassResult> addPassFromFile(String filePath, Locale locale) async {
  try {
    return await _processPassFile(filePath, locale);
  } catch (e) {
    return AddPassError(e.toString());
  }
}

Future<void> deletePassFile(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
