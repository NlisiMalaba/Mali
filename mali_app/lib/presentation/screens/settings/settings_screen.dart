import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/sync_providers.dart';
import 'package:mali_app/application/providers/sync_status_provider.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/settings/settings_section.dart';
import 'package:mali_app/presentation/widgets/settings/settings_tile.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const Key screenKey = Key('settings-screen');

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your data on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !context.mounted) {
      return;
    }

    await ref.read(authProvider.notifier).logout();
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon.')),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncing) {
      return;
    }
    setState(() => _isSyncing = true);
    final messenger = ScaffoldMessenger.of(context);

    String message;
    try {
      final result =
          await ref.read(backgroundSyncServiceProvider).runSyncIfOnline();
      message = switch (result.status) {
        BackgroundSyncStatus.succeeded => 'Your ledger is up to date.',
        BackgroundSyncStatus.skippedOffline =>
          'You\'re offline. Changes are saved and will sync later.',
        BackgroundSyncStatus.failed =>
          result.message ?? 'Sync failed. Try again in a moment.',
      };
    } catch (_) {
      message = 'Sync failed. Try again in a moment.';
    }

    ref.invalidate(lastSyncTimeProvider);
    if (!mounted) {
      return;
    }
    setState(() => _isSyncing = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _syncSubtitle(AsyncValue<DateTime?> lastSync) {
    if (_isSyncing) {
      return 'Syncing…';
    }
    return lastSync.when(
      loading: () => 'Checking…',
      error: (_, _) => 'Tap to sync now',
      data: (time) => time == null
          ? 'Never synced — tap to sync now'
          : 'Last synced ${_formatSyncTime(time)}',
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    final isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    if (isToday) {
      return 'today at ${DateFormat.jm().format(time)}';
    }
    return DateFormat('d MMM, HH:mm').format(time);
  }

  String _appLockSubtitle(AsyncValue<PinLockState> pinLock) {
    return pinLock.when(
      loading: () => 'Checking…',
      error: (_, _) => 'Manage PIN and biometrics',
      data: (state) {
        if (!state.isEnabled) {
          return 'Off';
        }
        return state.isBiometricEnabled ? 'PIN + biometrics' : 'PIN';
      },
    );
  }

  Future<void> _pickTheme(AppThemePreference current) async {
    final selected = await showModalBottomSheet<AppThemePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<AppThemePreference>(
          groupValue: current,
          onChanged: (value) => Navigator.of(sheetContext).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in AppThemePreference.values)
                RadioListTile<AppThemePreference>(
                  value: option,
                  title: Text(_themeLabel(option)),
                  subtitle: option == AppThemePreference.light
                      ? null
                      : const Text('Preview — some screens are still light'),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != current) {
      await ref
          .read(appPreferencesProvider.notifier)
          .setThemePreference(selected);
    }
  }

  String _themeLabel(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.light => 'Light',
      AppThemePreference.dark => 'Dark',
      AppThemePreference.system => 'Match system',
    };
  }

  Future<void> _pickDisplayCurrency(CurrencyCode current) async {
    final selected = await showModalBottomSheet<CurrencyCode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<CurrencyCode>(
          groupValue: current,
          onChanged: (value) => Navigator.of(sheetContext).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Net worth, digests and reminders are shown in this '
                  'currency. Your transactions keep their original currency.',
                ),
              ),
              for (final code in CurrencyCode.values)
                RadioListTile<CurrencyCode>(
                  value: code,
                  title: Text(code.value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != current) {
      await ref
          .read(appPreferencesProvider.notifier)
          .setDisplayCurrency(selected);
    }
  }

  Widget _profileHeader(User user) {
    final theme = Theme.of(context);
    final email = user.email?.trim();
    final phone = user.phone?.trim();
    final contact = (email != null && email.isNotEmpty)
        ? email
        : (phone != null && phone.isNotEmpty)
            ? phone
            : 'No contact on file';
    final initial = user.name.isNotEmpty
        ? user.name.characters.first.toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.heroCard(radius: AppDecorations.radiusXl),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.silver,
            child: Text(
              initial,
              style: AppTypography.money(fontSize: 22, color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onNavyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final preferences = ref.watch(appPreferencesProvider);
    final pinLock = ref.watch(pinLockControllerProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    return Scaffold(
      key: SettingsScreen.screenKey,
      appBar: const SovereignAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          auth.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Could not load profile: $error'),
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: _profileHeader(user),
              );
            },
          ),
          SettingsSection(
            title: 'Security & Sync',
            children: [
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'App lock',
                subtitle: _appLockSubtitle(pinLock),
                onTap: () => context.push('/settings/security'),
              ),
              SettingsTile(
                icon: Icons.cloud_sync,
                title: 'Sync now',
                subtitle: _syncSubtitle(lastSync),
                showChevron: false,
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isSyncing ? null : _syncNow,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Preferences',
            children: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: _themeLabel(preferences.themePreference),
                onTap: () => _pickTheme(preferences.themePreference),
              ),
              SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Budget alerts, weekly digest, goal reminders',
                onTap: () => context.push('/settings/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Currencies & Wallets',
            children: [
              SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallets',
                subtitle: 'Manage balances and currencies',
                onTap: () => context.go('/wallets'),
              ),
              SettingsTile(
                icon: Icons.currency_exchange,
                title: 'Display currency',
                subtitle: preferences.displayCurrency.value,
                onTap: () =>
                    _pickDisplayCurrency(preferences.displayCurrency),
              ),
              SettingsTile(
                icon: Icons.trending_up,
                title: 'Exchange rates',
                subtitle: 'View and edit conversion rates',
                onTap: () => context.push('/settings/exchange-rates'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Data',
            children: [
              SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Export data',
                subtitle: 'Download your transactions as PDF or CSV',
                onTap: () => context.push(ExportScreen.location),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Legal',
            children: [
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Coming soon',
                onTap: () => _showComingSoon(context, 'Terms of Service'),
              ),
              SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                subtitle: 'Your data is yours',
                onTap: () => _showComingSoon(context, 'Privacy Policy'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => _confirmSignOut(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.errorContainer.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${AppInfo.name} · v${AppInfo.version}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
