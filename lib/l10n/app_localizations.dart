import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get homeTitle;

  /// No description provided for @homeAddTicket.
  ///
  /// In en, this message translates to:
  /// **'Add ticket'**
  String get homeAddTicket;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get homeLoading;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tickets'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a pass from Apple Wallet\nor load a .pkpass file'**
  String get homeEmptyHint;

  /// No description provided for @homeErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load list'**
  String get homeErrorLoad;

  /// No description provided for @homeError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get homeError;

  /// No description provided for @archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTitle;

  /// No description provided for @archiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get archiveEmptyTitle;

  /// No description provided for @archiveEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Past tickets will appear here automatically'**
  String get archiveEmptyHint;

  /// No description provided for @passTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get passTicket;

  /// No description provided for @passNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ticket not found'**
  String get passNotFound;

  /// No description provided for @passLoadError.
  ///
  /// In en, this message translates to:
  /// **'Load error'**
  String get passLoadError;

  /// No description provided for @passDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket?'**
  String get passDeleteConfirmTitle;

  /// No description provided for @passDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Ticket «{name}» will be removed from the app.'**
  String passDeleteConfirmMessage(String name);

  /// No description provided for @passCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get passCancel;

  /// No description provided for @passDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get passDelete;

  /// No description provided for @passDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete ticket'**
  String get passDeleteError;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get fieldEvent;

  /// No description provided for @fieldVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get fieldVenue;

  /// No description provided for @fieldDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get fieldDateTime;

  /// No description provided for @fieldSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get fieldSeats;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fieldPrice;

  /// No description provided for @fieldRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund policy'**
  String get fieldRefund;

  /// No description provided for @fieldComplaints.
  ///
  /// In en, this message translates to:
  /// **'Questions?'**
  String get fieldComplaints;

  /// No description provided for @fieldQrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code for scanning'**
  String get fieldQrCode;

  /// No description provided for @fieldValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get fieldValidUntil;

  /// No description provided for @notificationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {name}'**
  String notificationReminderTitle(String name);

  /// No description provided for @notificationIn3Days.
  ///
  /// In en, this message translates to:
  /// **'Event in 3 days'**
  String get notificationIn3Days;

  /// No description provided for @notificationToday.
  ///
  /// In en, this message translates to:
  /// **'Event is today'**
  String get notificationToday;

  /// No description provided for @notificationIn1Hour.
  ///
  /// In en, this message translates to:
  /// **'Starting in 1 hour'**
  String get notificationIn1Hour;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
