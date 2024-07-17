import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<String> supportedLanguages = ['en', 'ru', 'ar', 'che'];

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'statistics': 'Statistics',
      'notifications': 'Notifications',
      'vibration': 'Vibration',
      'changeLanguage': 'Change Language',
      'about': 'About',
      'logout': 'Logout',
    },
    'ru': {
      'statistics': 'Статистика',
      'notifications': 'Уведомления',
      'vibration': 'Вибрация',
      'changeLanguage': 'Сменить язык',
      'about': 'О приложении',
      'logout': 'Выйти',
    },
    'ar': {
      'statistics': 'الإحصاءات',
      'notifications': 'الإخطارات',
      'vibration': 'الاهتزاز',
      'changeLanguage': 'تغيير اللغة',
      'about': 'حول',
      'logout': 'تسجيل الخروج',
    },
    'che': {
      'statistics': 'Статистика',
      'notifications': 'Билдари',
      'vibration': 'Вибрация',
      'changeLanguage': 'Шии даг',
      'about': 'Йоьхна',
      'logout': 'Чуг',
    },
  };

  String get statistics => _localizedStrings[locale.languageCode]!['statistics']!;
  String get notifications => _localizedStrings[locale.languageCode]!['notifications']!;
  String get vibration => _localizedStrings[locale.languageCode]!['vibration']!;
  String get changeLanguage => _localizedStrings[locale.languageCode]!['changeLanguage']!;
  String get about => _localizedStrings[locale.languageCode]!['about']!;
  String get logout => _localizedStrings[locale.languageCode]!['logout']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
