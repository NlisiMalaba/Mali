// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_list_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionListFiltersNotifier)
final transactionListFiltersProvider = TransactionListFiltersNotifierFamily._();

final class TransactionListFiltersNotifierProvider
    extends
        $NotifierProvider<
          TransactionListFiltersNotifier,
          TransactionListFilters
        > {
  TransactionListFiltersNotifierProvider._({
    required TransactionListFiltersNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'transactionListFiltersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionListFiltersNotifierHash();

  @override
  String toString() {
    return r'transactionListFiltersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionListFiltersNotifier create() => TransactionListFiltersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionListFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionListFilters>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionListFiltersNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionListFiltersNotifierHash() =>
    r'd28778bcd315af2f7eb787908a01194ebed9de14';

final class TransactionListFiltersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionListFiltersNotifier,
          TransactionListFilters,
          TransactionListFilters,
          TransactionListFilters,
          String?
        > {
  TransactionListFiltersNotifierFamily._()
    : super(
        retry: null,
        name: r'transactionListFiltersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionListFiltersNotifierProvider call(String? scopedWalletId) =>
      TransactionListFiltersNotifierProvider._(
        argument: scopedWalletId,
        from: this,
      );

  @override
  String toString() => r'transactionListFiltersProvider';
}

abstract class _$TransactionListFiltersNotifier
    extends $Notifier<TransactionListFilters> {
  late final _$args = ref.$arg as String?;
  String? get scopedWalletId => _$args;

  TransactionListFilters build(String? scopedWalletId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<TransactionListFilters, TransactionListFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionListFilters, TransactionListFilters>,
              TransactionListFilters,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
