import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/core/storage/app_preferences_store.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

final appPreferencesStoreProvider = Provider<AppPreferencesStore>(
  (ref) => const AppPreferencesStore(),
);

/// Preferences loaded before `runApp`; overridden in `main.dart`.
///
/// Defaults keep tests and previews working without a file on disk.
final initialAppPreferencesProvider = Provider<AppPreferences>(
  (ref) => const AppPreferences(),
);

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
  AppPreferencesController.new,
);

class AppPreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.read(initialAppPreferencesProvider);

  Future<void> setThemePreference(AppThemePreference value) =>
      _update(state.copyWith(themePreference: value));

  Future<void> setDisplayCurrency(CurrencyCode value) =>
      _update(state.copyWith(displayCurrency: value));

  Future<void> setBudgetAlertsEnabled(bool value) =>
      _update(state.copyWith(budgetAlertsEnabled: value));

  Future<void> setWeeklyDigestEnabled(bool value) =>
      _update(state.copyWith(weeklyDigestEnabled: value));

  Future<void> setGoalRemindersEnabled(bool value) =>
      _update(state.copyWith(goalRemindersEnabled: value));

  /// Updates the UI immediately; the write happens after so a slow disk
  /// never makes a toggle feel laggy.
  Future<void> _update(AppPreferences next) async {
    state = next;
    await ref.read(appPreferencesStoreProvider).write(next);
  }
}
