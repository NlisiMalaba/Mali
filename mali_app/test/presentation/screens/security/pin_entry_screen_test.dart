import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/presentation/screens/security/pin_entry_screen.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';

class _TestAuth extends Auth {
  @override
  Future<User?> build() async {
    return User(
      id: 'u1',
      name: 'Tendai Moyo',
      createdAt: DateTime(2026, 1, 1),
    );
  }
}

class _FakePinLockController extends PinLockController {
  _FakePinLockController(this._initial);

  final PinLockState _initial;
  final List<String> unlockPins = <String>[];

  @override
  Future<PinLockState> build() async => _initial;

  @override
  Future<String?> unlock(String pin) async {
    unlockPins.add(pin);
    if (pin == '1234') {
      markUnlocked();
      return null;
    }
    return 'Incorrect PIN.';
  }

  @override
  Future<String?> unlockWithBiometric() async => null;
}

Future<void> _pump(
  WidgetTester tester, {
  required PinLockState pinLock,
  BiometricCapability? capability,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakePinLockController(pinLock);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_TestAuth.new),
        pinLockControllerProvider.overrideWith(() => controller),
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
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const PinEntryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('shows navy unlock layout with greeting and keypad', (tester) async {
    await _pump(
      tester,
      pinLock: const PinLockState(
        isEnabled: true,
        isUnlocked: false,
        isBiometricEnabled: true,
      ),
    );

    expect(find.byKey(PinEntryScreen.screenKey), findsOneWidget);
    expect(find.byKey(const Key('pin-entry-greeting')), findsOneWidget);
    expect(find.text('Hi Tendai'), findsOneWidget);
    expect(
      find.text('Enter your PIN to open Master of Coin'),
      findsOneWidget,
    );
    expect(find.text('Forgot PIN?'), findsOneWidget);
    expect(find.byKey(const Key('biometric-unlock-button')), findsOneWidget);
    expect(find.byKey(const Key('pin-key-1')), findsOneWidget);
    expect(find.byKey(const Key('pin-keypad-backspace')), findsOneWidget);
  });

  testWidgets('hides biometric button when biometrics are off', (tester) async {
    await _pump(
      tester,
      pinLock: const PinLockState(
        isEnabled: true,
        isUnlocked: false,
        isBiometricEnabled: false,
      ),
    );

    expect(find.byKey(const Key('biometric-unlock-button')), findsNothing);
    expect(find.text('Forgot PIN?'), findsOneWidget);
  });

  testWidgets('submits PIN after four digits', (tester) async {
    late _FakePinLockController controller;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    controller = _FakePinLockController(
      const PinLockState(
        isEnabled: true,
        isUnlocked: false,
        isBiometricEnabled: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuth.new),
          pinLockControllerProvider.overrideWith(() => controller),
          biometricCapabilityProvider.overrideWith(
            (ref) async => const BiometricCapability(
              isAvailable: false,
              hasFace: false,
              hasFingerprint: false,
              hasIris: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const PinEntryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('pin-key-1')));
    await tester.tap(find.byKey(const Key('pin-key-2')));
    await tester.tap(find.byKey(const Key('pin-key-3')));
    await tester.tap(find.byKey(const Key('pin-key-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.unlockPins, ['1234']);
  });
}
