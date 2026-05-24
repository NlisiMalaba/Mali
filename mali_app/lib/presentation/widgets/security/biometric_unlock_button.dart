import 'package:flutter/material.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/presentation/utils/biometric_labels.dart';

class BiometricUnlockButton extends StatelessWidget {
  const BiometricUnlockButton({
    required this.capability,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final BiometricCapability capability;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = capability.hasFace
        ? Icons.face_unlock_outlined
        : Icons.fingerprint;

    return OutlinedButton.icon(
      key: const Key('biometric-unlock-button'),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(icon),
      label: Text(BiometricLabels.unlockAction(capability)),
    );
  }
}
