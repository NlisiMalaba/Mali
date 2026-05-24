// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localTransactionRepository)
final localTransactionRepositoryProvider =
    LocalTransactionRepositoryProvider._();

final class LocalTransactionRepositoryProvider
    extends
        $FunctionalProvider<
          LocalTransactionRepository,
          LocalTransactionRepository,
          LocalTransactionRepository
        >
    with $Provider<LocalTransactionRepository> {
  LocalTransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localTransactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localTransactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalTransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalTransactionRepository create(Ref ref) {
    return localTransactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalTransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalTransactionRepository>(value),
    );
  }
}

String _$localTransactionRepositoryHash() =>
    r'1e915d6cb2d25d03ffb7800aa536e541c08e0121';

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          ITransactionRepository,
          ITransactionRepository,
          ITransactionRepository
        >
    with $Provider<ITransactionRepository> {
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ITransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ITransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'cade252a2ffa777b081b481c4d583b1e12943cd6';

@ProviderFor(remoteTransactionRepository)
final remoteTransactionRepositoryProvider =
    RemoteTransactionRepositoryProvider._();

final class RemoteTransactionRepositoryProvider
    extends
        $FunctionalProvider<
          IRemoteTransactionRepository,
          IRemoteTransactionRepository,
          IRemoteTransactionRepository
        >
    with $Provider<IRemoteTransactionRepository> {
  RemoteTransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteTransactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteTransactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<IRemoteTransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IRemoteTransactionRepository create(Ref ref) {
    return remoteTransactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRemoteTransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRemoteTransactionRepository>(value),
    );
  }
}

String _$remoteTransactionRepositoryHash() =>
    r'b3f5454fc38bbfea1b32353f35754534be500cf0';

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          IWalletRepository,
          IWalletRepository,
          IWalletRepository
        >
    with $Provider<IWalletRepository> {
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<IWalletRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IWalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IWalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IWalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'0fe0a1a88909de17b9a7bab63061cec63a865014';

@ProviderFor(budgetRepository)
final budgetRepositoryProvider = BudgetRepositoryProvider._();

final class BudgetRepositoryProvider
    extends
        $FunctionalProvider<
          IBudgetRepository,
          IBudgetRepository,
          IBudgetRepository
        >
    with $Provider<IBudgetRepository> {
  BudgetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetRepositoryHash();

  @$internal
  @override
  $ProviderElement<IBudgetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBudgetRepository create(Ref ref) {
    return budgetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBudgetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBudgetRepository>(value),
    );
  }
}

String _$budgetRepositoryHash() => r'6860e1ed19be3f02615634624e849d6d5904e123';

@ProviderFor(goalRepository)
final goalRepositoryProvider = GoalRepositoryProvider._();

final class GoalRepositoryProvider
    extends
        $FunctionalProvider<IGoalRepository, IGoalRepository, IGoalRepository>
    with $Provider<IGoalRepository> {
  GoalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalRepositoryHash();

  @$internal
  @override
  $ProviderElement<IGoalRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IGoalRepository create(Ref ref) {
    return goalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IGoalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IGoalRepository>(value),
    );
  }
}

String _$goalRepositoryHash() => r'a07c1304e3a87ad67fc291ffa31e85766750c54e';

@ProviderFor(exchangeRateRepository)
final exchangeRateRepositoryProvider = ExchangeRateRepositoryProvider._();

final class ExchangeRateRepositoryProvider
    extends
        $FunctionalProvider<
          IExchangeRateRepository,
          IExchangeRateRepository,
          IExchangeRateRepository
        >
    with $Provider<IExchangeRateRepository> {
  ExchangeRateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRateRepositoryHash();

  @$internal
  @override
  $ProviderElement<IExchangeRateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IExchangeRateRepository create(Ref ref) {
    return exchangeRateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExchangeRateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExchangeRateRepository>(value),
    );
  }
}

String _$exchangeRateRepositoryHash() =>
    r'ed11d02c35743c12f3dc9136274a55b9b73e476a';
