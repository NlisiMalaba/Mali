import 'package:mali_app/domain/value_objects/currency_code.dart';

/// How the app chooses between the light and dark themes.
enum AppThemePreference { light, dark, system }

/// How long Mali waits after leaving the app before requiring unlock again.
enum AppLockGrace {
  immediately,
  after1Min,
  after5Min;

  Duration get delay => switch (this) {
        AppLockGrace.immediately => Duration.zero,
        AppLockGrace.after1Min => const Duration(minutes: 1),
        AppLockGrace.after5Min => const Duration(minutes: 5),
      };

  String get chipLabel => switch (this) {
        AppLockGrace.immediately => 'Immediately',
        AppLockGrace.after1Min => 'After 1 min',
        AppLockGrace.after5Min => 'After 5 min',
      };

  String get heroPhrase => switch (this) {
        AppLockGrace.immediately => 'locks immediately',
        AppLockGrace.after1Min => 'locks after 1 min',
        AppLockGrace.after5Min => 'locks after 5 min',
      };
}

/// User-level app settings that live on this device only.
///
/// Kept free of Flutter types so background isolates and the domain layer can
/// read it without a widget tree.
class AppPreferences {
  const AppPreferences({
    this.themePreference = AppThemePreference.light,
    this.displayCurrency = CurrencyCode.usd,
    this.budgetAlertsEnabled = true,
    this.weeklyDigestEnabled = true,
    this.goalRemindersEnabled = true,
    this.appLockGrace = AppLockGrace.immediately,
  });

  final AppThemePreference themePreference;
  final CurrencyCode displayCurrency;
  final bool budgetAlertsEnabled;
  final bool weeklyDigestEnabled;
  final bool goalRemindersEnabled;
  final AppLockGrace appLockGrace;

  AppPreferences copyWith({
    AppThemePreference? themePreference,
    CurrencyCode? displayCurrency,
    bool? budgetAlertsEnabled,
    bool? weeklyDigestEnabled,
    bool? goalRemindersEnabled,
    AppLockGrace? appLockGrace,
  }) {
    return AppPreferences(
      themePreference: themePreference ?? this.themePreference,
      displayCurrency: displayCurrency ?? this.displayCurrency,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      appLockGrace: appLockGrace ?? this.appLockGrace,
    );
  }

  Map<String, Object> toJson() => {
        'theme': themePreference.name,
        'displayCurrency': displayCurrency.value,
        'budgetAlerts': budgetAlertsEnabled,
        'weeklyDigest': weeklyDigestEnabled,
        'goalReminders': goalRemindersEnabled,
        'appLockGrace': appLockGrace.name,
      };

  /// Unknown or malformed values fall back to defaults so a bad file can
  /// never stop the app from starting.
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    const defaults = AppPreferences();

    final themeName = json['theme'];
    final theme = AppThemePreference.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => defaults.themePreference,
    );

    var currency = defaults.displayCurrency;
    final rawCurrency = json['displayCurrency'];
    if (rawCurrency is String) {
      try {
        currency = CurrencyCode(rawCurrency);
      } on ArgumentError {
        currency = defaults.displayCurrency;
      }
    }

    bool readBool(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    final graceName = json['appLockGrace'];
    final appLockGrace = AppLockGrace.values.firstWhere(
      (value) => value.name == graceName,
      orElse: () => defaults.appLockGrace,
    );

    return AppPreferences(
      themePreference: theme,
      displayCurrency: currency,
      budgetAlertsEnabled:
          readBool('budgetAlerts', defaults.budgetAlertsEnabled),
      weeklyDigestEnabled:
          readBool('weeklyDigest', defaults.weeklyDigestEnabled),
      goalRemindersEnabled:
          readBool('goalReminders', defaults.goalRemindersEnabled),
      appLockGrace: appLockGrace,
    );
  }
}
