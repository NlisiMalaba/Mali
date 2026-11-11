import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/sync_providers.dart';
import 'package:mali_app/application/providers/sync_status_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';
import 'package:mali_app/presentation/widgets/settings/settings_section.dart';
import 'package:mali_app/presentation/widgets/settings/settings_tile.dart';

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
      loading: () => '…',
      error: (_, _) => 'Tap to sync',
      data: (time) => time == null ? 'Never' : _formatSyncTime(time),
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
      loading: () => '…',
      error: (_, _) => 'Manage',
      data: (state) {
        if (!state.isEnabled) {
          return 'Off';
        }
        return state.isBiometricEnabled ? 'PIN + fingerprint' : 'PIN';
      },
    );
  }

  String _notificationsSubtitle(AppPreferences preferences) {
    final onCount = [
      preferences.budgetAlertsEnabled,
      preferences.weeklyDigestEnabled,
      preferences.goalRemindersEnabled,
    ].where((enabled) => enabled).length;
    return '$onCount on';
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onNavyMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.navyRaised,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile editing coming soon.')),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.silver,
                  size: 18,
                ),
              ),
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
    final walletsAsync = ref.watch(activeWalletsProvider);
    final budgetsAsync = ref.watch(homeTopBudgetsProvider);
    final ratesUpdatedAsync = ref.watch(exchangeRatesLastUpdatedProvider);

    final walletCount = walletsAsync.asData?.value.length ?? 0;
    final budgetCount = budgetsAsync.asData?.value.length ?? 0;
    final ratesLabel = ratesUpdatedAsync.when(
      data: (updatedAt) {
        if (updatedAt == null) {
          return 'Not set';
        }
        final raw =
            ExchangeRateLabels.lastUpdated(updatedAt, DateTime.now());
        final detail =
            raw.replaceFirst('Exchange rates last updated: ', '');
        if (detail.contains('hour') ||
            detail.contains('minute') ||
            detail == 'just now') {
          return 'Updated today';
        }
        return 'Updated $detail';
      },
      loading: () => '…',
      error: (_, _) => 'View rates',
    );

    return Scaffold(
      key: SettingsScreen.screenKey,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: AppTypography.money(
                      fontSize: 30,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmSignOut(context, ref),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Sign out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            auth.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Could not load profile: $error'),
              data: (user) {
                if (user == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _profileHeader(user),
                );
              },
            ),
            SettingsSection(
              title: 'Security & Alerts',
              children: [
                SettingsTile(
                  icon: Icons.lock_outline,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successContainer,
                  title: 'App lock',
                  subtitle: _appLockSubtitle(pinLock),
                  onTap: () => context.push('/settings/security'),
                ),
                SettingsTile(
                  icon: Icons.sync_rounded,
                  iconColor: AppColors.info,
                  iconBackground: AppColors.infoContainer,
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
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.moneyOut,
                  iconBackground: AppColors.warningContainer,
                  title: 'Notifications',
                  subtitle: _notificationsSubtitle(preferences),
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsSection(
              title: 'Money & Data',
              children: [
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successContainer,
                  title: 'Wallets',
                  subtitle: walletCount == 1
                      ? '1 wallet'
                      : '$walletCount wallets',
                  onTap: () => context.push('/wallets'),
                ),
                SettingsTile(
                  icon: Icons.pie_chart_outline,
                  iconColor: AppColors.budgetChipInk,
                  iconBackground: AppColors.budgetChip,
                  title: 'Budgets',
                  subtitle: budgetCount == 0
                      ? 'None this month'
                      : '$budgetCount this month',
                  onTap: () => context.push('/budgets'),
                ),
                SettingsTile(
                  icon: Icons.attach_money_rounded,
                  iconColor: AppColors.info,
                  iconBackground: AppColors.infoContainer,
                  title: 'Display currency',
                  showChevron: false,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      preferences.displayCurrency.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  onTap: () =>
                      _pickDisplayCurrency(preferences.displayCurrency),
                ),
                SettingsTile(
                  icon: Icons.currency_exchange,
                  iconColor: AppColors.ratesChipInk,
                  iconBackground: AppColors.ratesChip,
                  title: 'Exchange rates',
                  subtitle: ratesLabel,
                  onTap: () => context.push('/settings/exchange-rates'),
                ),
                SettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: AppColors.exportInk,
                  iconBackground: AppColors.surfaceContainer,
                  title: 'Export data',
                  subtitle: 'PDF or CSV',
                  onTap: () => context.push(ExportScreen.location),
                ),
              ],
            ),
            const SizedBox(height: 28),
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
      ),
    );
  }
}
