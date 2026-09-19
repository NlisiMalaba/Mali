import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/widgets/settings/settings_section.dart';
import 'package:mali_app/presentation/widgets/settings/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Key screenKey = Key('settings-screen');

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

  List<Widget> _profileSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> auth,
  ) {
    return auth.when(
      loading: () => [
        const SettingsSection(
          title: 'Profile',
          children: [
            ListTile(
              title: Text('Loading profile…'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      ],
      error: (error, _) => [
        SettingsSection(
          title: 'Profile',
          children: [
            ListTile(title: Text('Could not load profile: $error')),
          ],
        ),
      ],
      data: (user) {
        if (user == null) {
          return const <Widget>[];
        }

        final email = user.email?.trim();
        final phone = user.phone?.trim();
        final contact = (email != null && email.isNotEmpty)
            ? email
            : (phone != null && phone.isNotEmpty)
                ? phone
                : 'No contact on file';

        return [
          SettingsSection(
            title: 'Profile',
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.characters.first.toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(contact),
              ),
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit profile',
                onTap: () => _showComingSoon(context, 'Profile editing'),
              ),
              SettingsTile(
                icon: Icons.logout,
                title: 'Sign out',
                showChevron: false,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final displayCurrency = ref.watch(displayCurrencyProvider);

    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ..._profileSection(context, ref, auth),
          SettingsSection(
            title: 'Currencies & Wallets',
            children: [
              SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallets',
                subtitle: 'Manage balances and currencies',
                onTap: () => context.push('/wallets'),
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
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Budget alerts',
                subtitle: 'Notify at 80% and 100% of budget',
                onTap: () => context.push('/settings/notifications'),
              ),
            ],
          ),
          SettingsSection(
            title: 'Security',
            children: [
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'PIN & app lock',
                subtitle: 'Require PIN when opening Mali',
                onTap: () => context.push('/settings/security'),
              ),
            ],
          ),
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
                icon: Icons.sync,
                title: 'Sync',
                subtitle: 'Transactions sync when you are online',
                onTap: () => _showComingSoon(context, 'Sync settings'),
              ),
            ],
          ),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: AppInfo.name,
                subtitle: 'Version ${AppInfo.version}',
                showChevron: false,
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & privacy',
                onTap: () => _showComingSoon(context, 'Legal documents'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
