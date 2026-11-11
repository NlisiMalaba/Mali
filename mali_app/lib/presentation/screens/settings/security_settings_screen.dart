import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/pin_lock_store_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/domain/usecases/set_biometric_unlock_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/biometric_labels.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/security/pin_entry_panel.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  static const Key screenKey = Key('security-settings-screen');
  static const Key statusHeroKey = Key('security-status-hero');
  static const Key lockGraceGroupKey = Key('security-lock-grace-group');

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.75,
          child: PinEntryPanel(
            title: 'Enter current PIN',
            subtitle: 'Confirm to turn off app lock',
            onCompleted: (entered) async {
              Navigator.of(sheetContext).pop(entered);
              return null;
            },
          ),
        );
      },
    );

    if (pin == null || !context.mounted) {
      return;
    }

    final result = await ref.read(disablePinLockUseCaseProvider)(pin);
    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) async {
        await ref.read(pinLockControllerProvider.notifier).onPinDisabled();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN lock turned off.')),
        );
      },
    );
  }

  Future<void> _setBiometricUnlock(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final result = await ref.read(setBiometricUnlockUseCaseProvider)(
      SetBiometricUnlockParams(enabled: enabled),
    );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ref
            .read(pinLockControllerProvider.notifier)
            .onBiometricEnabledChanged(enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Biometric unlock enabled.'
                  : 'Biometric unlock disabled.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _enablePin(BuildContext context, WidgetRef ref) async {
    final created = await context.push<bool>('/settings/security/pin-setup');
    if (created != true || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN lock enabled.')),
    );
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.75,
          child: PinEntryPanel(
            title: 'Enter current PIN',
            subtitle: 'Then choose a new PIN',
            onCompleted: (entered) async {
              final valid =
                  await ref.read(pinLockRepositoryProvider).verifyPin(entered);
              if (!valid) {
                return 'Incorrect PIN.';
              }
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop(true);
              }
              return null;
            },
          ),
        );
      },
    );

    if (verified == true && context.mounted) {
      final changed = await context.push<bool>('/settings/security/pin-setup');
      if (changed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN updated.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinLockAsync = ref.watch(pinLockControllerProvider);
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final preferences = ref.watch(appPreferencesProvider);

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: pinLockAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load security: $error'),
            ),
          ),
          data: (pinLock) {
            final capability = capabilityAsync.asData?.value;
            return Column(
              children: [
                const FadeSlideIn(child: _Header()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    children: [
                      FadeSlideIn(
                        index: 1,
                        child: _StatusHero(
                          isEnabled: pinLock.isEnabled,
                          isBiometricEnabled: pinLock.isBiometricEnabled,
                          grace: preferences.appLockGrace,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        index: 2,
                        child: _ControlsCard(
                          pinEnabled: pinLock.isEnabled,
                          biometricEnabled: pinLock.isBiometricEnabled,
                          capability: capability,
                          capabilityLoading: capabilityAsync.isLoading,
                          onPinChanged: (enabled) async {
                            if (enabled) {
                              await _enablePin(context, ref);
                            } else {
                              await _disablePin(context, ref);
                            }
                          },
                          onBiometricChanged: (enabled) => _setBiometricUnlock(
                            context,
                            ref,
                            enabled: enabled,
                          ),
                          onChangePin: () => _changePin(context, ref),
                        ),
                      ),
                      if (pinLock.isEnabled) ...[
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCK AFTER LEAVING THE APP',
                                style: AppTypography.sectionLabel(context)
                                    .copyWith(
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _LockGraceSelector(
                                selected: preferences.appLockGrace,
                                onChanged: (grace) {
                                  ref
                                      .read(appPreferencesProvider.notifier)
                                      .setAppLockGrace(grace);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const FadeSlideIn(
                        index: 4,
                        child: _PinPrivacyNote(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
            ),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Security',
              style: AppTypography.money(
                fontSize: 26,
                color: AppColors.onSurface,
              ).copyWith(letterSpacing: -0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHero extends StatefulWidget {
  const _StatusHero({
    required this.isEnabled,
    required this.isBiometricEnabled,
    required this.grace,
  });

  final bool isEnabled;
  final bool isBiometricEnabled;
  final AppLockGrace grace;

  @override
  State<_StatusHero> createState() => _StatusHeroState();
}

class _StatusHeroState extends State<_StatusHero>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final Animation<double> _entranceCurve;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: AppMotion.celebration,
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    _entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: AppMotion.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
      if (_ambient.isAnimating) {
        _ambient.stop();
      }
      _ambient.value = 0;
      return;
    }
    if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
    if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isEnabled ? 'Your ledger is locked' : 'Your ledger is open';
    final method = !widget.isEnabled
        ? 'Turn on a PIN to protect balances'
        : widget.isBiometricEnabled
            ? 'PIN + fingerprint'
            : 'PIN';
    final subtitle =
        widget.isEnabled ? '$method · ${widget.grace.heroPhrase}' : method;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCurve, _ambient]),
      builder: (context, _) {
        final enter = reduceMotion ? 1.0 : _entranceCurve.value;
        final orbit = reduceMotion ? 0.0 : _ambient.value * math.pi * 2;
        final float = reduceMotion
            ? 0.0
            : math.sin(_ambient.value * math.pi * 2) * 2.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(0, (1 - enter) * 18 + float * 0.4, 0, 1)
            ..rotateX(-0.04 + (1 - enter) * 0.1),
          child: Opacity(
            opacity: enter.clamp(0.0, 1.0),
            child: Container(
              key: SecuritySettingsScreen.statusHeroKey,
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.heroCard(radius: 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: orbit,
                          child: CustomPaint(
                            size: const Size(72, 72),
                            painter: _OrbitPainter(
                              accent: widget.isEnabled
                                  ? AppColors.silver
                                  : AppColors.onNavyMuted,
                            ),
                          ),
                        ),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..translateByDouble(0, float, 0, 1)
                            ..rotateY(
                              reduceMotion
                                  ? 0
                                  : math.sin(orbit + 0.8) * 0.08,
                            ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.navyRaised,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.silver.withValues(
                                    alpha: widget.isEnabled ? 0.18 : 0.06,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isEnabled
                                  ? Icons.shield_outlined
                                  : Icons.lock_open_outlined,
                              color: AppColors.silver,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.money(
                            fontSize: 20,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.onNavyMuted,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;

    final dash = Paint()
      ..color = const Color(0xFF2B4580)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashCount = 24;
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) {
        continue;
      }
      final start = (i / dashCount) * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        0.14,
        false,
        dash,
      );
    }

    final dot = Paint()..color = accent;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      3.5,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.capability,
    required this.capabilityLoading,
    required this.onPinChanged,
    required this.onBiometricChanged,
    required this.onChangePin,
  });

  final bool pinEnabled;
  final bool biometricEnabled;
  final BiometricCapability? capability;
  final bool capabilityLoading;
  final ValueChanged<bool> onPinChanged;
  final ValueChanged<bool> onBiometricChanged;
  final VoidCallback onChangePin;

  @override
  Widget build(BuildContext context) {
    final showBiometric = pinEnabled &&
        (capabilityLoading || (capability?.isAvailable ?? false));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _ToggleRow(
            key: const Key('pin-lock-switch'),
            title: 'Require PIN to open',
            subtitle: 'Ask for your 4-digit PIN every time',
            value: pinEnabled,
            onChanged: onPinChanged,
            showDivider: showBiometric || pinEnabled,
          ),
          if (showBiometric)
            capabilityLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Unlock with biometrics',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  )
                : _ToggleRow(
                    key: const Key('biometric-unlock-switch'),
                    title: BiometricLabels.settingsTitle(capability!),
                    subtitle: 'Faster than typing your PIN',
                    value: biometricEnabled,
                    onChanged: onBiometricChanged,
                    showDivider: pinEnabled,
                  ),
          if (pinEnabled)
            PressableScale(
              onTap: onChangePin,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Change PIN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.success,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFEDF0F6),
          ),
      ],
    );
  }
}

class _LockGraceSelector extends StatelessWidget {
  const _LockGraceSelector({
    required this.selected,
    required this.onChanged,
  });

  final AppLockGrace selected;
  final ValueChanged<AppLockGrace> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: SecuritySettingsScreen.lockGraceGroupKey,
      children: [
        for (var i = 0; i < AppLockGrace.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _GraceChip(
              label: AppLockGrace.values[i].chipLabel,
              selected: AppLockGrace.values[i] == selected,
              onTap: () => onChanged(AppLockGrace.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _GraceChip extends StatelessWidget {
  const _GraceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.navy : const Color(0xFFE1E5EE),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.silver : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PinPrivacyNote extends StatelessWidget {
  const _PinPrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your PIN is stored as a salted hash on this phone only. '
      'Nobody at Master of Coin can see it.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
