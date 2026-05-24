import 'package:mali_app/application/mappers/add_transaction_mapper.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_transaction_provider.g.dart';

@riverpod
class AddTransaction extends _$AddTransaction {
  @override
  FutureOr<void> build() {}

  Future<void> submit(AddTransactionInput input) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final transaction = AddTransactionMapper.toTransaction(input);
      final result = await ref.read(logTransactionUseCaseProvider)(transaction);

      result.fold(
        (failure) => throw failure,
        (_) => null,
      );
    });
  }
}

String addTransactionErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return 'Failed to save transaction.';
}
