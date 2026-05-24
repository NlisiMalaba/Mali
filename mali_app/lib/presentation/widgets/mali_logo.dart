import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

class MaliLogo extends StatelessWidget {
  const MaliLogo({
    this.size = 96,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.tealPrimaryLight : AppColors.tealPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.5,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        SizedBox(height: size * 0.2),
        Text(
          'Mali',
          style: theme.textTheme.displaySmall?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
