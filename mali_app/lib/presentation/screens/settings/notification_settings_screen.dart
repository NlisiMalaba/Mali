import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/mali_logo.dart';

/// Lets the user choose which local notifications Master of Coin sends.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({
    this.clock = DateTime.now,
    super.key,
  });

  static const Key screenKey = Key('notification-settings-screen');
  static const Key previewKey = Key('notification-preview-hero');
  static const Key budgetAlertsKey = Key('notification-budget-alerts');
  static const Key weeklyDigestKey = Key('notification-weekly-digest');
  static const Key goalRemindersKey = Key('notification-goal-reminders');
  static const String location = '/settings/notifications';

  /// Injectable so widget tests can pin the lock-screen time.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final controller = ref.read(appPreferencesProvider.notifier);

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  _PreviewHero(now: clock()),
                  const SizedBox(height: 16),
                  _TogglesCard(
                    budgetAlertsEnabled: preferences.budgetAlertsEnabled,
                    weeklyDigestEnabled: preferences.weeklyDigestEnabled,
                    goalRemindersEnabled: preferences.goalRemindersEnabled,
                    onBudgetAlertsChanged: controller.setBudgetAlertsEnabled,
                    onWeeklyDigestChanged: controller.setWeeklyDigestEnabled,
                    onGoalRemindersChanged: controller.setGoalRemindersEnabled,
                  ),
                  const SizedBox(height: 28),
                  const _PrivacyNote(),
                ],
              ),
            ),
          ],
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
              'Notifications',
              style: AppTypography.money(
                fontSize: 26,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(now.toLocal());

    return Container(
      key: NotificationSettingsScreen.previewKey,
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: AppDecorations.heroCard(radius: 26),
      child: Column(
        children: [
          Text(
            timeLabel,
            style: AppTypography.money(
              fontSize: 30,
              color: const Color(0xFF3B5394),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const MaliLogo(
                    size: 18,
                    showWordmark: false,
                    showTile: false,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Master of Coin',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            'now',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transport is at 94%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '\$9 left for the next 20 days.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3A4560),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglesCard extends StatelessWidget {
  const _TogglesCard({
    required this.budgetAlertsEnabled,
    required this.weeklyDigestEnabled,
    required this.goalRemindersEnabled,
    required this.onBudgetAlertsChanged,
    required this.onWeeklyDigestChanged,
    required this.onGoalRemindersChanged,
  });

  final bool budgetAlertsEnabled;
  final bool weeklyDigestEnabled;
  final bool goalRemindersEnabled;
  final ValueChanged<bool> onBudgetAlertsChanged;
  final ValueChanged<bool> onWeeklyDigestChanged;
  final ValueChanged<bool> onGoalRemindersChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _ToggleRow(
            key: NotificationSettingsScreen.budgetAlertsKey,
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warningText,
            iconBackground: AppColors.warningContainer,
            title: 'Budget alerts',
            subtitle: 'When spending crosses a budget limit',
            value: budgetAlertsEnabled,
            onChanged: onBudgetAlertsChanged,
            showDivider: true,
          ),
          _ToggleRow(
            key: NotificationSettingsScreen.weeklyDigestKey,
            icon: Icons.show_chart_rounded,
            iconColor: AppColors.info,
            iconBackground: AppColors.infoContainer,
            title: 'Weekly digest',
            subtitle: 'Sunday evening summary of your week',
            value: weeklyDigestEnabled,
            onChanged: onWeeklyDigestChanged,
            showDivider: true,
          ),
          _ToggleRow(
            key: NotificationSettingsScreen.goalRemindersKey,
            icon: Icons.track_changes_outlined,
            iconColor: AppColors.success,
            iconBackground: AppColors.successContainer,
            title: 'Goal reminders',
            subtitle: 'Monthly nudge to move surplus into a goal',
            value: goalRemindersEnabled,
            onChanged: onGoalRemindersChanged,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
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
          padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
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
                        height: 1.25,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.settingsDivider,
          ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Notifications are made on your phone from your own data. '
      'Nothing is sent to us.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
