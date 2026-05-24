// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionListWatch)
final transactionListWatchProvider = TransactionListWatchFamily._();

final class TransactionListWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  TransactionListWatchProvider._({
    required TransactionListWatchFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'transactionListWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionListWatchHash();

  @override
  String toString() {
    return r'transactionListWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String?;
    return transactionListWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionListWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionListWatchHash() =>
    r'c31697cb6da975054f3c276dd61ed5a4f7bd5468';

final class TransactionListWatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Transaction>>, String?> {
  TransactionListWatchFamily._()
    : super(
        retry: null,
        name: r'transactionListWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionListWatchProvider call(String? scopedWalletId) =>
      TransactionListWatchProvider._(argument: scopedWalletId, from: this);

  @override
  String toString() => r'transactionListWatchProvider';
}

@ProviderFor(TransactionListController)
final transactionListControllerProvider = TransactionListControllerFamily._();

final class TransactionListControllerProvider
    extends $NotifierProvider<TransactionListController, TransactionListState> {
  TransactionListControllerProvider._({
    required TransactionListControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'transactionListControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionListControllerHash();

  @override
  String toString() {
    return r'transactionListControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionListController create() => TransactionListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionListControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionListControllerHash() =>
    r'a89c71be06f912233074d156eaa361ae96817825';

final class TransactionListControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionListController,
          TransactionListState,
          TransactionListState,
          TransactionListState,
          String?
        > {
  TransactionListControllerFamily._()
    : super(
        retry: null,
        name: r'transactionListControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionListControllerProvider call(String? scopedWalletId) =>
      TransactionListControllerProvider._(argument: scopedWalletId, from: this);

  @override
  String toString() => r'transactionListControllerProvider';
}

abstract class _$TransactionListController
    extends $Notifier<TransactionListState> {
  late final _$args = ref.$arg as String?;
  String? get scopedWalletId => _$args;

  TransactionListState build(String? scopedWalletId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TransactionListState, TransactionListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionListState, TransactionListState>,
              TransactionListState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(refreshTransactionsSync)
final refreshTransactionsSyncProvider = RefreshTransactionsSyncProvider._();

final class RefreshTransactionsSyncProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  RefreshTransactionsSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refreshTransactionsSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refreshTransactionsSyncHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return refreshTransactionsSync(ref);
  }
}

String _$refreshTransactionsSyncHash() =>
    r'4ba5c259a4f7cac679690b522997027a961a73d3';
