import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/presentation/screens/settings/security_settings_screen.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';

class _FakePinLockController extends PinLockController {
  _FakePinLockController(this._initial);

  final PinLockState _initial;

  @override
  Future<PinLockState> build() async => _initial;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required PinLockState pinLock,
  AppLockGrace grace = AppLockGrace.immediately,
  BiometricCapability? capability,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pinLockControllerProvider.overrideWith(
          () => _FakePinLockController(pinLock),
        ),
        biometricCapabilityProvider.overrideWith(
          (ref) async =>
              capability ??
              const BiometricCapability(
                isAvailable: true,
                hasFace: false,
                hasFingerprint: true,
                hasIris: false,
              ),
        ),
        initialAppPreferencesProvider.overrideWithValue(
          AppPreferences(appLockGrace: grace),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SecuritySettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows locked hero, toggles, and lock-after chips', (tester) async {
    await _pumpScreen(
      tester,
      pinLock: const PinLockState(
        isEnabled: true,
        isUnlocked: true,
        isBiometricEnabled: true,
      ),
    );

    expect(find.byKey(SecuritySettingsScreen.screenKey), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.byKey(SecuritySettingsScreen.statusHeroKey), findsOneWidget);
    expect(find.text('Your ledger is locked'), findsOneWidget);
    expect(
      find.text('PIN + fingerprint · locks immediately'),
      findsOneWidget,
    );
    expect(find.text('Require PIN to open'), findsOneWidget);
    expect(find.text('Unlock with fingerprint'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('LOCK AFTER LEAVING THE APP'), findsOneWidget);
    expect(find.text('Immediately'), findsOneWidget);
    expect(find.text('After 1 min'), findsOneWidget);
    expect(find.text('After 5 min'), findsOneWidget);
    expect(
      find.textContaining('salted hash on this phone only'),
      findsOneWidget,
    );
  });

  testWidgets('open ledger when PIN is off', (tester) async {
    await _pumpScreen(
      tester,
      pinLock: const PinLockState(
        isEnabled: false,
        isUnlocked: true,
        isBiometricEnabled: false,
      ),
    );

    expect(find.text('Your ledger is open'), findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
    expect(find.text('LOCK AFTER LEAVING THE APP'), findsNothing);
  });

  testWidgets('selecting grace updates hero copy', (tester) async {
    await _pumpScreen(
      tester,
      pinLock: const PinLockState(
        isEnabled: true,
        isUnlocked: true,
        isBiometricEnabled: false,
      ),
    );

    await tester.tap(find.text('After 1 min'));
    await tester.pumpAndSettle();

    expect(find.text('PIN · locks after 1 min'), findsOneWidget);
  });
}
