import 'package:flutter_test/flutter_test.dart';
import 'package:tickety/models/pass_record.dart';

void main() {
  group('PassRecord archive status', () {
    final now = DateTime(2026, 9, 11, 12);

    test('archives a pass after its event time', () {
      final pass = _pass(eventDate: '2026-09-11T11:59:59');

      expect(pass.isArchivedAt(now), isTrue);
    });

    test('keeps a date-only pass active through that day', () {
      final pass = _pass(eventDate: '2026-09-11');

      expect(pass.isArchivedAt(now), isFalse);
      expect(pass.isArchivedAt(DateTime(2026, 9, 12)), isTrue);
    });

    test('falls back to the expiration date', () {
      final pass = _pass(expirationDate: '2026-09-10T18:00:00');

      expect(pass.isArchivedAt(now), isTrue);
    });

    test('keeps undated and invalid passes in the active list', () {
      expect(_pass().isArchivedAt(now), isFalse);
      expect(_pass(eventDate: 'not-a-date').isArchivedAt(now), isFalse);
    });
  });
}

PassRecord _pass({String? eventDate, String? expirationDate}) => PassRecord(
  id: 'id',
  serialNumber: 'serial',
  passTypeIdentifier: 'type',
  organizationName: 'Organizer',
  eventDate: eventDate,
  expirationDate: expirationDate,
  filePath: '/tmp/pass.pkpass',
  hash: 'hash',
  createdAt: '2026-09-01T00:00:00',
);
