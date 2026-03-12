// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get homeTitle => 'Билеты';

  @override
  String get homeAddTicket => 'Добавить билет';

  @override
  String get homeLoading => 'Загрузка…';

  @override
  String get homeEmptyTitle => 'Нет билетов';

  @override
  String get homeEmptyHint =>
      'Добавьте пропуск из Apple Wallet\nили загрузите файл .pkpass';

  @override
  String get homeErrorLoad => 'Не удалось загрузить список';

  @override
  String get homeError => 'Ошибка';

  @override
  String get passTicket => 'Билет';

  @override
  String get passNotFound => 'Билет не найден';

  @override
  String get passLoadError => 'Ошибка загрузки';

  @override
  String get passDeleteConfirmTitle => 'Удалить билет?';

  @override
  String passDeleteConfirmMessage(String name) {
    return 'Билет «$name» будет удалён из приложения.';
  }

  @override
  String get passCancel => 'Отмена';

  @override
  String get passDelete => 'Удалить';

  @override
  String get passDeleteError => 'Не удалось удалить билет';

  @override
  String get fieldDescription => 'Описание';

  @override
  String get fieldEvent => 'Мероприятие';

  @override
  String get fieldVenue => 'Место';

  @override
  String get fieldDateTime => 'Дата и время';

  @override
  String get fieldSeats => 'Места';

  @override
  String get fieldPrice => 'Цена';

  @override
  String get fieldRefund => 'Условия возврата';

  @override
  String get fieldComplaints => 'Остались вопросы?';

  @override
  String get fieldQrCode => 'QR-код для сканирования';

  @override
  String get fieldValidUntil => 'Действителен до';

  @override
  String notificationReminderTitle(String name) {
    return 'Напоминание: $name';
  }

  @override
  String get notificationIn3Days => 'До мероприятия осталось 3 дня';

  @override
  String get notificationToday => 'Мероприятие сегодня';

  @override
  String get notificationIn1Hour => 'До начала остался 1 час';
}
