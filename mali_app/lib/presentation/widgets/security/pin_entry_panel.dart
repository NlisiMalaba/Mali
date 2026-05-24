import 'package:flutter/material.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/presentation/widgets/security/pin_dots.dart';
import 'package:mali_app/presentation/widgets/security/pin_keypad.dart';

/// Returns an error message to display, or null when the PIN was accepted.
typedef PinCompletedCallback = Future<String?> Function(String pin);

class PinEntryPanel extends StatefulWidget {
  const PinEntryPanel({
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    super.key,
  });

  final String title;
  final String subtitle;
  final PinCompletedCallback onCompleted;

  @override
  State<PinEntryPanel> createState() => _PinEntryPanelState();
}

class _PinEntryPanelState extends State<PinEntryPanel> {
  final _buffer = StringBuffer();
  String? _errorMessage;
  bool _isSubmitting = false;

  void _onDigit(String digit) {
    if (_isSubmitting || _buffer.length >= PinLockConstants.pinLength) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _buffer.write(digit);
    });

    if (_buffer.length == PinLockConstants.pinLength) {
      _submit();
    }
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final pin = _buffer.toString();
    final errorMessage = await widget.onCompleted(pin);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _buffer.clear();
      _errorMessage = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PinDots(enteredLength: _buffer.length),
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
    );
  }
}
