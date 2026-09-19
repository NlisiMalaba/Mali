import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
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
  bool _biometricEnabled = true;
  bool _cloudSyncEnabled = false;
  bool _darkModeEnabled = false;
  bool _pushNotificationsEnabled = true;
  bool _smsPermissionsEnabled = true;

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

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Text(
                  initial,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 2),
                  ),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          contact,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final displayCurrency = ref.watch(displayCurrencyProvider);

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
                padding: const EdgeInsets.only(bottom: 40),
                child: _profileHeader(user),
              );
            },
          ),
          SettingsSection(
            title: 'Security & Backup',
            children: [
              SettingsToggleTile(
                icon: Icons.fingerprint,
                title: 'Biometric Lock',
                subtitle: 'Use FaceID or TouchID to unlock',
                value: _biometricEnabled,
                onChanged: (value) {
                  setState(() => _biometricEnabled = value);
                  if (value) {
                    context.push('/settings/security');
                  }
                },
              ),
              SettingsToggleTile(
                icon: Icons.cloud_sync,
                title: 'Cloud Sync',
                subtitle: 'Backup ledger data to secure vault',
                value: _cloudSyncEnabled,
                onChanged: (value) {
                  setState(() => _cloudSyncEnabled = value);
                  _showComingSoon(context, 'Cloud sync');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Preferences',
            children: [
              SettingsToggleTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch to high-contrast dark theme',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                  _showComingSoon(context, 'Dark mode');
                },
              ),
              SettingsToggleTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Real-time alerts for transactions',
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() => _pushNotificationsEnabled = value);
                  context.push('/settings/notifications');
                },
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
                subtitle: displayCurrency.value,
                onTap: () => _showComingSoon(context, 'Display currency'),
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
            title: 'Integrations',
            children: [
              SettingsToggleTile(
                icon: Icons.sms_outlined,
                title: 'SMS Permissions',
                subtitle: 'Sync Ecocash & bank SMS alerts',
                value: _smsPermissionsEnabled,
                onChanged: (value) {
                  setState(() => _smsPermissionsEnabled = value);
                  _showComingSoon(context, 'SMS permissions');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'Data & Backup',
            children: [
              SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Export data',
                subtitle: 'Download your transactions as PDF or CSV',
                onTap: () => context.push(ExportScreen.location),
              ),
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'PIN & app lock',
                subtitle: 'Require PIN when opening Mali',
                onTap: () => context.push('/settings/security'),
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
                subtitle: 'Last updated October 2023',
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
            '${AppInfo.name} Sovereign v${AppInfo.version} • Built for Ledger',
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
