import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/budget_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';

class LogTransactionUseCase {
  const LogTransactionUseCase({
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
    required IBudgetRepository budgetRepository,
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository,
        _budgetRepository = budgetRepository;

  final ITransactionRepository _transactionRepository;
  final IWalletRepository _walletRepository;
  final IBudgetRepository _budgetRepository;

  Future<Either<Failure, LogTransactionResult>> call(Transaction transaction) async {
    final amount = _parseMoney(transaction.amount);
    if (amount == null || amount <= Decimal.zero) {
      return left(
        const ValidationFailure(
          message: 'Transaction amount must be greater than zero.',
          field: 'amount',
        ),
      );
    }

    final wallet = await _walletRepository.findById(transaction.walletId);
    if (wallet == null) {
      return left(
        const NotFoundFailure(
          message: 'Wallet not found.',
          resource: 'wallet',
        ),
      );
    }

    final walletBalance = _parseMoney(wallet.balance);
    if (walletBalance == null) {
      return left(
        const StorageFailure(message: 'Wallet balance is invalid.'),
      );
    }

    try {
      final updatedBalance = _calculateNextWalletBalance(
        currentBalance: walletBalance,
        amount: amount,
        transactionType: transaction.type,
      );

      await _walletRepository.updateBalance(
        walletId: wallet.id,
        balance: updatedBalance.toString(),
      );
      await _transactionRepository.save(transaction);

      BudgetThresholdAlert? alert;
      if (transaction.type == 'expense' && transaction.categoryId != null) {
        alert = await _updateBudgetAndCheckThreshold(
          wallet: wallet,
          transaction: transaction,
          expenseAmount: amount,
        );
      }

      return right(
        LogTransactionResult(
          updatedWallet: wallet.copyWith(balance: updatedBalance.toString()),
          budgetThresholdAlert: alert,
        ),
      );
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to persist transaction.',
          cause: error,
        ),
      );
    }
  }

  Decimal _calculateNextWalletBalance({
    required Decimal currentBalance,
    required Decimal amount,
    required String transactionType,
  }) {
    switch (transactionType) {
      case 'income':
        return currentBalance + amount;
      case 'expense':
      case 'transfer':
        return currentBalance - amount;
      default:
        throw const ValidationFailure(
          message: 'Unsupported transaction type.',
          field: 'type',
        );
    }
  }

  Future<BudgetThresholdAlert?> _updateBudgetAndCheckThreshold({
    required Wallet wallet,
    required Transaction transaction,
    required Decimal expenseAmount,
  }) async {
    final budgets = await _budgetRepository
        .watchMonthBudgets(
          year: transaction.transactionDate.year,
          month: transaction.transactionDate.month,
        )
        .first;

    final targetBudget = budgets.where((budget) {
      return budget.categoryId == transaction.categoryId &&
          budget.currencyCode == wallet.currencyCode;
    }).firstOrNull;

    if (targetBudget == null) {
      return null;
    }

    final budgetAmount = _parseMoney(targetBudget.amount);
    final spentAmount = _parseMoney(targetBudget.spentAmount);
    if (budgetAmount == null || spentAmount == null || budgetAmount <= Decimal.zero) {
      return null;
    }

    final nextSpent = spentAmount + expenseAmount;
    await _budgetRepository.updateSpentAmount(
      budgetId: targetBudget.id,
      spentAmount: nextSpent.toString(),
    );

    final previousAt100 = spentAmount >= budgetAmount;
    final currentAt100 = nextSpent >= budgetAmount;
    if (!previousAt100 && currentAt100) {
      return BudgetThresholdAlert(
        budget: targetBudget.copyWith(spentAmount: nextSpent.toString()),
        threshold: Decimal.parse('1'),
      );
    }
    final eightyPercentAmount = budgetAmount * Decimal.parse('0.8');
    final previousAt80 = spentAmount >= eightyPercentAmount;
    final currentAt80 = nextSpent >= eightyPercentAmount;
    if (!previousAt80 && currentAt80) {
      return BudgetThresholdAlert(
        budget: targetBudget.copyWith(spentAmount: nextSpent.toString()),
        threshold: Decimal.parse('0.8'),
      );
    }
    return null;
  }

  Decimal? _parseMoney(String value) {
    try {
      return Decimal.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class LogTransactionResult {
  const LogTransactionResult({
    required this.updatedWallet,
    this.budgetThresholdAlert,
  });

  final Wallet updatedWallet;
  final BudgetThresholdAlert? budgetThresholdAlert;
}

class BudgetThresholdAlert {
  const BudgetThresholdAlert({
    required this.budget,
    required this.threshold,
  });

  final Budget budget;
  final Decimal threshold;
}
