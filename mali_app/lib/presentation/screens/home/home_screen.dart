import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/transaction_list_provider.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/home/budget_overview_row.dart';
import 'package:mali_app/presentation/widgets/home/home_greeting_header.dart';
import 'package:mali_app/presentation/widgets/home/home_section_header.dart';
import 'package:mali_app/presentation/widgets/home/money_flow_cards.dart';
import 'package:mali_app/presentation/widgets/home/net_worth_card.dart';
import 'package:mali_app/presentation/widgets/home/recent_transactions_section.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _onRefresh(ref, context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 0,
                    child: HomeGreetingHeader(
                      userName: userName,
                      hasNotificationDot: true,
                      onNotificationsTap: () =>
                          context.push('/settings/notifications'),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 1,
                    child: const NetWorthCard(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 2,
                    child: const MoneyFlowCards(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.surfaceCard(
                        radius: 22,
                        withShadow: false,
                      ),
                      child: Column(
                        children: [
                          HomeSectionHeader(
                            title: 'Budgets',
                            actionLabel: 'See all',
                            onAction: () => context.push('/budgets'),
                          ),
                          const SizedBox(height: 14),
                          const BudgetOverviewRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 4,
                    child: Material(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: () => context.push('/transactions'),
                        borderRadius: BorderRadius.circular(22),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: RecentTransactionsSection(maxItems: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
