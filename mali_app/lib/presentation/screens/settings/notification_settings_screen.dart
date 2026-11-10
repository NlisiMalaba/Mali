import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/presentation/widgets/settings/settings_section.dart';
import 'package:mali_app/presentation/widgets/settings/settings_tile.dart';

/// Lets the user choose which local notifications Master of Coin sends.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const Key screenKey = Key('notification-settings-screen');
  static const String location = '/settings/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final controller = ref.read(appPreferencesProvider.notifier);

    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          SettingsSection(
            title: 'Alerts',
            children: [
              SettingsToggleTile(
                icon: Icons.warning_amber_rounded,
                title: 'Budget alerts',
                subtitle: 'When spending crosses a budget threshold',
                value: preferences.budgetAlertsEnabled,
                onChanged: controller.setBudgetAlertsEnabled,
              ),
              SettingsToggleTile(
                icon: Icons.insights_outlined,
                title: 'Weekly digest',
                subtitle: 'Sunday evening summary of your week',
                value: preferences.weeklyDigestEnabled,
                onChanged: controller.setWeeklyDigestEnabled,
              ),
              SettingsToggleTile(
                icon: Icons.savings_outlined,
                title: 'Goal reminders',
                subtitle: 'Monthly nudge to move surplus into a goal',
                value: preferences.goalRemindersEnabled,
                onChanged: controller.setGoalRemindersEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
