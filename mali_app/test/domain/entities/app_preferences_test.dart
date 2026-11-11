import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

void main() {
  group('AppPreferences', () {
    test('round-trips through JSON', () {
      const prefs = AppPreferences(
        themePreference: AppThemePreference.dark,
        displayCurrency: CurrencyCode.zar,
        budgetAlertsEnabled: false,
        weeklyDigestEnabled: false,
        goalRemindersEnabled: true,
        appLockGrace: AppLockGrace.after5Min,
      );

      final restored = AppPreferences.fromJson(prefs.toJson());

      expect(restored.themePreference, AppThemePreference.dark);
      expect(restored.displayCurrency, CurrencyCode.zar);
      expect(restored.budgetAlertsEnabled, isFalse);
      expect(restored.weeklyDigestEnabled, isFalse);
      expect(restored.goalRemindersEnabled, isTrue);
      expect(restored.appLockGrace, AppLockGrace.after5Min);
    });

    test('falls back to defaults for unknown or malformed values', () {
      final restored = AppPreferences.fromJson({
        'theme': 'neon',
        'displayCurrency': 'XYZ',
        'budgetAlerts': 'yes',
        'appLockGrace': 'sometime',
      });

      expect(restored.themePreference, AppThemePreference.light);
      expect(restored.displayCurrency, CurrencyCode.usd);
      expect(restored.budgetAlertsEnabled, isTrue);
      expect(restored.appLockGrace, AppLockGrace.immediately);
    });
  });
}
