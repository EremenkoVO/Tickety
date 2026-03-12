import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pass_record.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'tickety.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE passes (
            id TEXT PRIMARY KEY,
            serial_number TEXT NOT NULL,
            pass_type_identifier TEXT NOT NULL,
            organization_name TEXT NOT NULL,
            description TEXT,
            barcode_message TEXT,
            barcode_format TEXT,
            expiration_date TEXT,
            venue_name TEXT,
            event_date TEXT,
            event_name TEXT,
            seats TEXT,
            price TEXT,
            refund_info TEXT,
            complaints_info TEXT,
            file_path TEXT NOT NULL,
            hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(pass_type_identifier, serial_number)
          )
        ''');
      },
    );
  }

  Future<void> upsertPass(PassRecord pass) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO passes (
        id, serial_number, pass_type_identifier, organization_name,
        description, barcode_message, barcode_format, expiration_date,
        venue_name, event_date, event_name, seats, price, refund_info,
        complaints_info, file_path, hash, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(pass_type_identifier, serial_number) DO UPDATE SET
        organization_name = excluded.organization_name,
        description = excluded.description,
        barcode_message = excluded.barcode_message,
        barcode_format = excluded.barcode_format,
        expiration_date = excluded.expiration_date,
        venue_name = excluded.venue_name,
        event_date = excluded.event_date,
        event_name = excluded.event_name,
        seats = excluded.seats,
        price = excluded.price,
        refund_info = excluded.refund_info,
        complaints_info = excluded.complaints_info,
        file_path = excluded.file_path,
        hash = excluded.hash
    ''', [
      pass.id,
      pass.serialNumber,
      pass.passTypeIdentifier,
      pass.organizationName,
      pass.description,
      pass.barcodeMessage,
      pass.barcodeFormat,
      pass.expirationDate,
      pass.venueName,
      pass.eventDate,
      pass.eventName,
      pass.seats,
      pass.price,
      pass.refundInfo,
      pass.complaintsInfo,
      pass.filePath,
      pass.hash,
      pass.createdAt,
    ]);
  }

  Future<List<PassRecord>> getAllPasses() async {
    final db = await database;
    final rows = await db.query('passes', orderBy: 'created_at DESC');
    return rows.map(PassRecord.fromMap).toList();
  }

  Future<PassRecord?> getPassById(String id) async {
    final db = await database;
    final rows = await db.query('passes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : PassRecord.fromMap(rows.first);
  }

  Future<PassRecord?> getPassByUniqueKey(
      String passTypeIdentifier, String serialNumber) async {
    final db = await database;
    final rows = await db.query(
      'passes',
      where: 'pass_type_identifier = ? AND serial_number = ?',
      whereArgs: [passTypeIdentifier, serialNumber],
    );
    return rows.isEmpty ? null : PassRecord.fromMap(rows.first);
  }

  Future<bool> deletePass(String id) async {
    final db = await database;
    final count =
        await db.delete('passes', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }
}
