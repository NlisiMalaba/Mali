import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/transaction.dart';

class AddTransactionInput {
  const AddTransactionInput({
    required this.userId,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.walletId,
    required this.title,
    required this.transactionDate,
    this.categoryId,
    this.exchangeRate,
    this.notes,
  });

  final String userId;
  final String type;
  final String amount;
  final String currencyCode;
  final String walletId;
  final String? categoryId;
  final String? exchangeRate;
  final String title;
  final String? notes;
  final DateTime transactionDate;
}

class AddTransactionMapper {
  const AddTransactionMapper._();

  static Transaction toTransaction(AddTransactionInput input) {
    final now = DateTime.now();
    final id = LocalIdGenerator.newId('tx');

    return Transaction(
      id: id,
      userId: input.userId,
      walletId: input.walletId,
      categoryId: input.categoryId,
      syncId: id,
      type: input.type,
      amount: input.amount,
      currencyCode: input.currencyCode,
      exchangeRate: input.exchangeRate,
      title: input.title,
      notes: input.notes,
      transactionDate: input.transactionDate,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
