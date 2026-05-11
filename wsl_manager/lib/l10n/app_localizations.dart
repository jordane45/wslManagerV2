import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _values = {
    'en': {
      'settings.title': 'Settings',
      'settings.storage': 'Storage',
      'settings.templatesDir': 'Templates folder',
      'settings.snapshotsDir': 'Snapshots folder',
      'settings.backup': 'Backup',
      'settings.exportConfig': 'Export full configuration',
      'settings.exportConfigSubtitle': 'Templates, snapshots and JSON files',
      'settings.exportDialogTitle': 'Export configuration',
      'settings.exportSuccess': 'Configuration exported',
      'settings.exportError': 'Export error',
      'settings.monitoring': 'Monitoring',
      'settings.refreshInterval': 'Refresh interval',
      'settings.appearance': 'Appearance',
      'settings.system': 'System',
      'settings.light': 'Light',
      'settings.dark': 'Dark',
      'settings.language': 'Language',
      'settings.french': 'French',
      'settings.english': 'English',
      'settings.behavior': 'Behavior',
      'settings.minimizeToTray': 'Minimize to tray on close',
      'settings.launchAtStartup': 'Launch at Windows startup',
      'settings.about': 'About',
      'settings.version': 'Version',
      'common.browse': 'Browse',
      'common.chooseFolder': 'Choose folder',
    },
    'fr': {
      'settings.title': 'Paramètres',
      'settings.storage': 'Stockage',
      'settings.templatesDir': 'Dossier des templates',
      'settings.snapshotsDir': 'Dossier des snapshots',
      'settings.backup': 'Sauvegarde',
      'settings.exportConfig': 'Exporter la configuration complète',
      'settings.exportConfigSubtitle': 'Templates, snapshots et fichiers JSON',
      'settings.exportDialogTitle': 'Exporter la configuration',
      'settings.exportSuccess': 'Configuration exportée',
      'settings.exportError': 'Erreur export',
      'settings.monitoring': 'Surveillance',
      'settings.refreshInterval': 'Intervalle de rafraîchissement',
      'settings.appearance': 'Apparence',
      'settings.system': 'Système',
      'settings.light': 'Clair',
      'settings.dark': 'Sombre',
      'settings.language': 'Langue',
      'settings.french': 'Français',
      'settings.english': 'Anglais',
      'settings.behavior': 'Comportement',
      'settings.minimizeToTray': 'Minimiser dans le systray à la fermeture',
      'settings.launchAtStartup': 'Lancer au démarrage Windows',
      'settings.about': 'À propos',
      'settings.version': 'Version',
      'common.browse': 'Parcourir',
      'common.chooseFolder': 'Choisir le dossier',
    },
  };

  String get settingsTitle => _text('settings.title');
  String get settingsStorage => _text('settings.storage');
  String get settingsTemplatesDir => _text('settings.templatesDir');
  String get settingsSnapshotsDir => _text('settings.snapshotsDir');
  String get settingsBackup => _text('settings.backup');
  String get settingsExportConfig => _text('settings.exportConfig');
  String get settingsExportConfigSubtitle =>
      _text('settings.exportConfigSubtitle');
  String get settingsExportDialogTitle => _text('settings.exportDialogTitle');
  String get settingsExportSuccess => _text('settings.exportSuccess');
  String get settingsExportError => _text('settings.exportError');
  String get settingsMonitoring => _text('settings.monitoring');
  String get settingsRefreshInterval => _text('settings.refreshInterval');
  String get settingsAppearance => _text('settings.appearance');
  String get settingsSystem => _text('settings.system');
  String get settingsLight => _text('settings.light');
  String get settingsDark => _text('settings.dark');
  String get settingsLanguage => _text('settings.language');
  String get settingsFrench => _text('settings.french');
  String get settingsEnglish => _text('settings.english');
  String get settingsBehavior => _text('settings.behavior');
  String get settingsMinimizeToTray => _text('settings.minimizeToTray');
  String get settingsLaunchAtStartup => _text('settings.launchAtStartup');
  String get settingsAbout => _text('settings.about');
  String get settingsVersion => _text('settings.version');
  String get commonBrowse => _text('common.browse');
  String get commonChooseFolder => _text('common.chooseFolder');

  String _text(String key) {
    final language =
        _values.containsKey(locale.languageCode) ? locale.languageCode : 'en';
    return _values[language]?[key] ?? _values['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
