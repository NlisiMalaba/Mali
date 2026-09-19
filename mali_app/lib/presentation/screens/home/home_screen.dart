import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/transaction_list_provider.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/presentation/widgets/home/goals_progress_row.dart';
import 'package:mali_app/presentation/widgets/home/home_greeting_header.dart';
import 'package:mali_app/presentation/widgets/home/home_section_header.dart';
import 'package:mali_app/presentation/widgets/home/month_summary_card.dart';
import 'package:mali_app/presentation/widgets/home/net_worth_card.dart';
import 'package:mali_app/presentation/widgets/home/wallet_balance_scroll.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref, BuildContext context) async {
    ref.invalidate(homeNetWorthProvider);
    ref.invalidate(homeMonthlySummaryDisplayProvider);
    ref.invalidate(homeRecentTransactionsProvider);
    ref.invalidate(homeTopBudgetsProvider);
    ref.invalidate(homeTopGoalsProvider);
    ref.invalidate(exchangeRatesLastUpdatedProvider);

    try {
      await ref.read(refreshTransactionsSyncProvider.future);
    } on Failure catch (failure) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userName = auth.maybeWhen(
      data: (user) => user?.name ?? '',
      orElse: () => '',
    );

    return Scaffold(
      key: const Key('home-screen'),
      appBar: SovereignAppBar(
        actions: [
          IconButton(
            key: const Key('home-analytics-button'),
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Analytics',
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref, context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              sliver: SliverToBoxAdapter(
                child: HomeGreetingHeader(userName: userName),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: NetWorthCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: HomeSectionHeader(
                      title: 'Your Wallets',
                      actionLabel: 'View All',
                      onAction: () => context.go('/wallets'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const WalletBalanceScroll(),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: MonthSummaryCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'Savings Goals',
                  actionLabel: 'View All',
                  onAction: () => context.go('/goals'),
                ),
              ),
            ),
            const SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              sliver: SliverToBoxAdapter(child: GoalsProgressRow()),
            ),
          ],
        ),
      ),
    );
  }
}
