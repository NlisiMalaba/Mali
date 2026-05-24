import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/widgets/wallet/add_wallet_sheet.dart';
import 'package:mali_app/presentation/widgets/wallet/wallet_card.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  Future<void> _openAddWallet(BuildContext context) async {
    final created = await AddWalletSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet added.')),
      );
    }
  }

  Future<bool> _archiveWallet(
    WidgetRef ref,
    BuildContext context,
    Wallet wallet,
  ) async {
    final result = await ref.read(archiveWalletUseCaseProvider)(
      walletId: wallet.id,
    );

    if (!context.mounted) return false;

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${wallet.name} archived.')),
    );
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(activeWalletsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddWallet(context),
        tooltip: 'Add wallet',
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load wallets: $error'),
          ),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No wallets yet'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openAddWallet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first wallet'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return Dismissible(
                key: ValueKey(wallet.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) =>
                    _archiveWallet(ref, context, wallet),
                child: WalletCard(
                  wallet: wallet,
                  onTap: () => context.push('/wallets/${wallet.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
