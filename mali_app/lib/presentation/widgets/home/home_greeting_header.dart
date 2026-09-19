import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/greeting.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    required this.userName,
    super.key,
  });

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = Greeting.forUser(name: userName, now: DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting.toUpperCase(),
          style: AppTypography.sectionLabel(context).copyWith(
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sovereign Ledger',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
