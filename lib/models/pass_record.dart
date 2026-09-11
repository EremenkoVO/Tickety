class PassRecord {
  final String id;
  final String serialNumber;
  final String passTypeIdentifier;
  final String organizationName;
  final String? description;
  final String? barcodeMessage;
  final String? barcodeFormat;
  final String? expirationDate;
  final String? venueName;
  final String? eventDate;
  final String? eventName;
  final String? seats;
  final String? price;
  final String? refundInfo;
  final String? complaintsInfo;
  final String filePath;
  final String hash;
  final String createdAt;

  const PassRecord({
    required this.id,
    required this.serialNumber,
    required this.passTypeIdentifier,
    required this.organizationName,
    this.description,
    this.barcodeMessage,
    this.barcodeFormat,
    this.expirationDate,
    this.venueName,
    this.eventDate,
    this.eventName,
    this.seats,
    this.price,
    this.refundInfo,
    this.complaintsInfo,
    required this.filePath,
    required this.hash,
    required this.createdAt,
  });

  /// Date used to decide when this pass should move to the archive.
  ///
  /// A date without a time remains active until the end of that local day.
  DateTime? get archiveDate {
    for (final rawDate in [eventDate, expirationDate]) {
      if (rawDate == null || rawDate.isEmpty) continue;
      final date = DateTime.tryParse(rawDate);
      if (date == null) continue;

      final isDateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate);
      return isDateOnly ? date.add(const Duration(days: 1)) : date;
    }
    return null;
  }

  /// The pass is archived automatically once its archive date has passed.
  bool isArchivedAt(DateTime now) => archiveDate?.isAfter(now) == false;

  Map<String, dynamic> toMap() => {
        'id': id,
        'serial_number': serialNumber,
        'pass_type_identifier': passTypeIdentifier,
        'organization_name': organizationName,
        'description': description,
        'barcode_message': barcodeMessage,
        'barcode_format': barcodeFormat,
        'expiration_date': expirationDate,
        'venue_name': venueName,
        'event_date': eventDate,
        'event_name': eventName,
        'seats': seats,
        'price': price,
        'refund_info': refundInfo,
        'complaints_info': complaintsInfo,
        'file_path': filePath,
        'hash': hash,
        'created_at': createdAt,
      };

  factory PassRecord.fromMap(Map<String, dynamic> map) => PassRecord(
        id: map['id'] as String,
        serialNumber: map['serial_number'] as String,
        passTypeIdentifier: map['pass_type_identifier'] as String,
        organizationName: map['organization_name'] as String,
        description: map['description'] as String?,
        barcodeMessage: map['barcode_message'] as String?,
        barcodeFormat: map['barcode_format'] as String?,
        expirationDate: map['expiration_date'] as String?,
        venueName: map['venue_name'] as String?,
        eventDate: map['event_date'] as String?,
        eventName: map['event_name'] as String?,
        seats: map['seats'] as String?,
        price: map['price'] as String?,
        refundInfo: map['refund_info'] as String?,
        complaintsInfo: map['complaints_info'] as String?,
        filePath: map['file_path'] as String,
        hash: map['hash'] as String,
        createdAt: map['created_at'] as String,
      );
}
