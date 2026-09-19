import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/services/goal_funding.dart';
import 'package:mali_app/domain/services/goal_priority.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

/// Works out whether the previous calendar month left the user with money to
/// allocate, and which goal should receive it.
class BuildContributionReminderUseCase {
  const BuildContributionReminderUseCase({
    required GetMonthlySummaryUseCase monthlySummary,
    required IGoalRepository goalRepository,
    required ConvertMoneyUseCase convertMoney,
  })  : _monthlySummary = monthlySummary,
        _goalRepository = goalRepository,
        _convertMoney = convertMoney;

  final GetMonthlySummaryUseCase _monthlySummary;
  final IGoalRepository _goalRepository;
  final ConvertMoneyUseCase _convertMoney;

  Future<Either<Failure, ContributionReminder>> call({
    required DateTime now,
    required CurrencyCode displayCurrency,
  }) async {
    final month = previousMonthOf(now);

    final summaryResult = await _monthlySummary(
      year: month.year,
      month: month.month,
    );
    final summaryFailure = summaryResult.getLeft().toNullable();
    if (summaryFailure != null) {
      return left(summaryFailure);
    }
    final summary = summaryResult.getOrElse(
      (_) => throw StateError('expected monthly summary'),
    );

    try {
      final surplus = await _surplusIn(
        summary: summary,
        displayCurrency: displayCurrency,
      );
      final topGoal = GoalPriority.topFundable(
        await _goalRepository.listActiveGoals(),
      );

      return right(
        ContributionReminder(
          month: month,
          surplus: Money(amount: surplus, currency: displayCurrency),
          topGoal: topGoal == null
              ? null
              : ReminderGoal(
                  goalId: topGoal.id,
                  name: topGoal.name,
                  percentFunded: GoalFunding.percentFunded(topGoal),
                ),
        ),
      );
    } on Failure catch (failure) {
      return left(failure);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to build the contribution reminder.',
          cause: error,
        ),
      );
    }
  }

  /// First day of the calendar month preceding [now].
  static DateTime previousMonthOf(DateTime now) {
    return DateTime(now.year, now.month - 1);
  }

  /// Net of income minus expenses across every currency, expressed in
  /// [displayCurrency]. Deficits in one currency offset surpluses in another.
  Future<Decimal> _surplusIn({
    required MonthlySummary summary,
    required CurrencyCode displayCurrency,
  }) async {
    var surplus = Decimal.zero;

    for (final totals in summary.totalsByCurrency) {
      final net = totals.net;
      if (net == Decimal.zero) {
        continue;
      }

      final sourceCurrency = CurrencyCode(totals.currencyCode);
      if (sourceCurrency == displayCurrency) {
        surplus += net;
        continue;
      }

      // Convert the magnitude so the sign survives the exchange rate lookup.
      final converted = await _convertMoney(
        money: Money(amount: net.abs(), currency: sourceCurrency),
        targetCurrency: displayCurrency,
      );
      final amount = converted.fold(
        (failure) => throw failure,
        (money) => money.amount,
      );
      surplus += net < Decimal.zero ? -amount : amount;
    }

    return surplus;
  }
}

class ContributionReminder {
  const ContributionReminder({
    required this.month,
    required this.surplus,
    required this.topGoal,
  });

  /// First day of the month the surplus was earned in.
  final DateTime month;
  final Money surplus;
  final ReminderGoal? topGoal;

  /// Only worth prompting when there is money left over and somewhere to put
  /// it.
  bool get shouldPrompt =>
      topGoal != null && surplus.amount > Decimal.zero;
}

class ReminderGoal {
  const ReminderGoal({
    required this.goalId,
    required this.name,
    required this.percentFunded,
  });

  final String goalId;
  final String name;
  final int percentFunded;
}
