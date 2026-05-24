// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_transaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddTransaction)
final addTransactionProvider = AddTransactionProvider._();

final class AddTransactionProvider
    extends $AsyncNotifierProvider<AddTransaction, void> {
  AddTransactionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addTransactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addTransactionHash();

  @$internal
  @override
  AddTransaction create() => AddTransaction();
}

String _$addTransactionHash() => r'b0c495fbffcc9e85fed801a1a70f28d224c6bb1c';

abstract class _$AddTransaction extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
