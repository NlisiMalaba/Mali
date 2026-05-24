import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/domain/usecases/set_pin_usecase.dart';
import 'package:mali_app/presentation/widgets/security/pin_dots.dart';
import 'package:mali_app/presentation/widgets/security/pin_keypad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  static const Key screenKey = Key('pin-setup-screen');

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _buffer = StringBuffer();
  String? _firstPin;
  String? _errorMessage;
  bool _isSubmitting = false;

  String get _stepTitle {
    return _firstPin == null ? 'Create a PIN' : 'Confirm your PIN';
  }

  String get _stepSubtitle {
    return _firstPin == null
        ? 'Choose a 4-digit PIN to protect Mali'
        : 'Enter the same PIN again';
  }

  Future<void> _onDigit(String digit) async {
    if (_isSubmitting || _buffer.length >= PinLockConstants.pinLength) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _buffer.write(digit);
    });

    if (_buffer.length < PinLockConstants.pinLength) {
      return;
    }

    final pin = _buffer.toString();
    _buffer.clear();

    if (_firstPin == null) {
      setState(() => _firstPin = pin);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(setPinUseCaseProvider)(
      SetPinParams(pin: _firstPin!, confirmPin: pin),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _firstPin = null;
          _errorMessage = failure.message;
        });
      },
      (_) async {
        await ref.read(pinLockControllerProvider.notifier).onPinEnabled();
        if (!mounted) {
          return;
        }
        context.pop(true);
      },
    );
  }

  void _onBackspace() {
    if (_isSubmitting || _buffer.isEmpty) {
      return;
    }

    setState(() {
      _errorMessage = null;
      final value = _buffer.toString();
      _buffer
        ..clear()
        ..write(value.substring(0, value.length - 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enteredLength = _buffer.length;

    return Scaffold(
      key: PinSetupScreen.screenKey,
      appBar: AppBar(
        title: const Text('Set up PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _stepTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _stepSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinDots(enteredLength: enteredLength),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_isSubmitting) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              const Spacer(),
              PinKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
