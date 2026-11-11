import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/greeting.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    required this.userName,
    this.onNotificationsTap,
    this.hasNotificationDot = false,
    super.key,
  });

  final String userName;
  final VoidCallback? onNotificationsTap;
  final bool hasNotificationDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = Greeting.timeOfDay(DateTime.now());
    final firstName = _firstName(userName);
    final initial = firstName.isNotEmpty
        ? firstName.characters.first.toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.navy,
          child: Text(
            initial,
            style: AppTypography.money(
              fontSize: 18,
              color: AppColors.silver,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              Text(
                firstName.isEmpty ? 'there' : firstName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE1E5EE)),
          ),
          child: InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  if (hasNotificationDot)
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.notificationOrange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceContainerLowest,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
