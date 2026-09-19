import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/services/goal_funding.dart';
import 'package:mali_app/domain/services/goal_priority.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/money.dart';

/// Aggregates the last seven days of local spending plus the highest-priority
/// savings goal into the payload behind the weekly digest notification.
class BuildWeeklyDigestUseCase {
  const BuildWeeklyDigestUseCase({
    required ITransactionRepository transactionRepository,
    required IGoalRepository goalRepository,
    required ConvertMoneyUseCase convertMoney,
  })  : _transactionRepository = transactionRepository,
        _goalRepository = goalRepository,
        _convertMoney = convertMoney;

  /// Length of the digest window, in calendar days, inclusive of today.
  static const int windowDays = 7;

  /// Upper bound on rows pulled for a single week; large enough that realistic
  /// usage is never truncated.
  static const int transactionLimit = 5000;

  static const String _expenseType = 'expense';

  final ITransactionRepository _transactionRepository;
  final IGoalRepository _goalRepository;
  final ConvertMoneyUseCase _convertMoney;

  Future<Either<Failure, WeeklyDigest>> call({
    required DateTime now,
    required CurrencyCode displayCurrency,
  }) async {
    final window = windowEndingAt(now);

    try {
      final expenses = await _transactionRepository.list(
        query: TransactionQuery(
          dateFrom: window.start,
          dateTo: window.end,
          type: _expenseType,
          limit: transactionLimit,
        ),
      );

      final spending = await _aggregateSpending(
        expenses: expenses,
        displayCurrency: displayCurrency,
      );
      final goal = await _topGoalProgress();

      return right(
        WeeklyDigest(
          window: window,
          totalSpent: Money(
            amount: spending.total,
            currency: displayCurrency,
          ),
          expenseCount: expenses.length,
          topCategory: spending.topCategory,
          topGoal: goal,
        ),
      );
    } on Failure catch (failure) {
      return left(failure);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to build the weekly digest.',
          cause: error,
        ),
      );
    }
  }

  /// The [windowDays] calendar days ending on the day of [now].
  static DateRange windowEndingAt(DateTime now) {
    final start = DateTime(now.year, now.month, now.day - (windowDays - 1));
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
      999,
    );
    return DateRange(start: start, end: end);
  }

  Future<_SpendingAggregate> _aggregateSpending({
    required List<Transaction> expenses,
    required CurrencyCode displayCurrency,
  }) async {
    var total = Decimal.zero;
    final byCategory = <String, Decimal>{};

    for (final expense in expenses) {
      final amount = await _convertToDisplayCurrency(
        transaction: expense,
        displayCurrency: displayCurrency,
      );
      total += amount;

      final categoryId = expense.categoryId;
      if (categoryId != null) {
        byCategory[categoryId] = (byCategory[categoryId] ?? Decimal.zero) + amount;
      }
    }

    return _SpendingAggregate(
      total: total,
      topCategory: _rankTopCategory(
        byCategory: byCategory,
        displayCurrency: displayCurrency,
      ),
    );
  }

  Future<Decimal> _convertToDisplayCurrency({
    required Transaction transaction,
    required CurrencyCode displayCurrency,
  }) async {
    final amount = Decimal.tryParse(transaction.amount);
    if (amount == null || amount <= Decimal.zero) {
      return Decimal.zero;
    }

    final result = await _convertMoney(
      money: Money(
        amount: amount,
        currency: CurrencyCode(transaction.currencyCode),
      ),
      targetCurrency: displayCurrency,
    );

    return result.fold(
      (failure) => throw failure,
      (converted) => converted.amount,
    );
  }

  /// Highest spend wins; ties break on category id so the digest is stable
  /// across runs with identical data.
  DigestCategorySpend? _rankTopCategory({
    required Map<String, Decimal> byCategory,
    required CurrencyCode displayCurrency,
  }) {
    DigestCategorySpend? top;
    for (final entry in byCategory.entries) {
      if (entry.value <= Decimal.zero) {
        continue;
      }
      if (top == null ||
          entry.value > top.amount.amount ||
          (entry.value == top.amount.amount &&
              entry.key.compareTo(top.categoryId) < 0)) {
        top = DigestCategorySpend(
          categoryId: entry.key,
          amount: Money(amount: entry.value, currency: displayCurrency),
        );
      }
    }
    return top;
  }

  Future<DigestGoalProgress?> _topGoalProgress() async {
    final top = GoalPriority.topFundable(
      await _goalRepository.listActiveGoals(),
    );
    if (top == null) {
      return null;
    }

    return DigestGoalProgress(
      goalId: top.id,
      name: top.name,
      percentFunded: GoalFunding.percentFunded(top),
    );
  }
}

class _SpendingAggregate {
  const _SpendingAggregate({
    required this.total,
    required this.topCategory,
  });

  final Decimal total;
  final DigestCategorySpend? topCategory;
}

class WeeklyDigest {
  const WeeklyDigest({
    required this.window,
    required this.totalSpent,
    required this.expenseCount,
    required this.topCategory,
    required this.topGoal,
  });

  final DateRange window;
  final Money totalSpent;
  final int expenseCount;
  final DigestCategorySpend? topCategory;
  final DigestGoalProgress? topGoal;

  /// True when there is nothing worth interrupting the user for.
  bool get hasNothingToReport => expenseCount == 0 && topGoal == null;
}

class DigestCategorySpend {
  const DigestCategorySpend({
    required this.categoryId,
    required this.amount,
  });

  final String categoryId;
  final Money amount;
}

class DigestGoalProgress {
  const DigestGoalProgress({
    required this.goalId,
    required this.name,
    required this.percentFunded,
  });

  final String goalId;
  final String name;
  final int percentFunded;
}
