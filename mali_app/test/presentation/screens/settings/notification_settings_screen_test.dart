import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/presentation/screens/settings/notification_settings_screen.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  AppPreferences preferences = const AppPreferences(),
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialAppPreferencesProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: NotificationSettingsScreen(
          clock: () => DateTime(2026, 11, 11, 18, 30),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows preview, toggles, and privacy note', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.byKey(NotificationSettingsScreen.screenKey),
      findsOneWidget,
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.byKey(NotificationSettingsScreen.previewKey),
      findsOneWidget,
    );
    expect(find.text('18:30'), findsOneWidget);
    expect(find.text('Master of Coin'), findsOneWidget);
    expect(find.text('Transport is at 94%'), findsOneWidget);
    expect(find.text('Budget alerts'), findsOneWidget);
    expect(find.text('Weekly digest'), findsOneWidget);
    expect(find.text('Goal reminders'), findsOneWidget);
    expect(
      find.textContaining('Nothing is sent to us'),
      findsOneWidget,
    );
  });

  testWidgets('toggling budget alerts updates preferences', (tester) async {
    await _pumpScreen(tester);

    final switchFinder = find.descendant(
      of: find.byKey(NotificationSettingsScreen.budgetAlertsKey),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
  });
}
