// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeTitle => 'Tickets';

  @override
  String get homeAddTicket => 'Add ticket';

  @override
  String get homeLoading => 'Loading…';

  @override
  String get homeEmptyTitle => 'No tickets';

  @override
  String get homeEmptyHint =>
      'Add a pass from Apple Wallet\nor load a .pkpass file';

  @override
  String get homeErrorLoad => 'Failed to load list';

  @override
  String get homeError => 'Error';

  @override
  String get passTicket => 'Ticket';

  @override
  String get passNotFound => 'Ticket not found';

  @override
  String get passLoadError => 'Load error';

  @override
  String get passDeleteConfirmTitle => 'Delete ticket?';

  @override
  String passDeleteConfirmMessage(String name) {
    return 'Ticket «$name» will be removed from the app.';
  }

  @override
  String get passCancel => 'Cancel';

  @override
  String get passDelete => 'Delete';

  @override
  String get passDeleteError => 'Failed to delete ticket';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldEvent => 'Event';

  @override
  String get fieldVenue => 'Venue';

  @override
  String get fieldDateTime => 'Date & time';

  @override
  String get fieldSeats => 'Seats';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldRefund => 'Refund policy';

  @override
  String get fieldComplaints => 'Questions?';

  @override
  String get fieldQrCode => 'QR code for scanning';

  @override
  String get fieldValidUntil => 'Valid until';

  @override
  String notificationReminderTitle(String name) {
    return 'Reminder: $name';
  }

  @override
  String get notificationIn3Days => 'Event in 3 days';

  @override
  String get notificationToday => 'Event is today';

  @override
  String get notificationIn1Hour => 'Starting in 1 hour';
}
