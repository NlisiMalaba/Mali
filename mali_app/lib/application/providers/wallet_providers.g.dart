// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeWallets)
final activeWalletsProvider = ActiveWalletsProvider._();

final class ActiveWalletsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Wallet>>,
          List<Wallet>,
          Stream<List<Wallet>>
        >
    with $FutureModifier<List<Wallet>>, $StreamProvider<List<Wallet>> {
  ActiveWalletsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWalletsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWalletsHash();

  @$internal
  @override
  $StreamProviderElement<List<Wallet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Wallet>> create(Ref ref) {
    return activeWallets(ref);
  }
}

String _$activeWalletsHash() => r'e7dc9c84557d8cabea89756bdd634b93dce2f93d';

@ProviderFor(walletById)
final walletByIdProvider = WalletByIdFamily._();

final class WalletByIdProvider
    extends $FunctionalProvider<AsyncValue<Wallet?>, Wallet?, FutureOr<Wallet?>>
    with $FutureModifier<Wallet?>, $FutureProvider<Wallet?> {
  WalletByIdProvider._({
    required WalletByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'walletByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$walletByIdHash();

  @override
  String toString() {
    return r'walletByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Wallet?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Wallet?> create(Ref ref) {
    final argument = this.argument as String;
    return walletById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletByIdHash() => r'59be0f71b30d4a527ffcd2f5b004d11fd357dbc0';

final class WalletByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Wallet?>, String> {
  WalletByIdFamily._()
    : super(
        retry: null,
        name: r'walletByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WalletByIdProvider call(String walletId) =>
      WalletByIdProvider._(argument: walletId, from: this);

  @override
  String toString() => r'walletByIdProvider';
}

@ProviderFor(walletTransactions)
final walletTransactionsProvider = WalletTransactionsFamily._();

final class WalletTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  WalletTransactionsProvider._({
    required WalletTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'walletTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$walletTransactionsHash();

  @override
  String toString() {
    return r'walletTransactionsProvider'
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
    final argument = this.argument as String;
    return walletTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletTransactionsHash() =>
    r'71e0240e913a2e93c807111d7794cbb31504edb7';

final class WalletTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Transaction>>, String> {
  WalletTransactionsFamily._()
    : super(
        retry: null,
        name: r'walletTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WalletTransactionsProvider call(String walletId) =>
      WalletTransactionsProvider._(argument: walletId, from: this);

  @override
  String toString() => r'walletTransactionsProvider';
}

@ProviderFor(needsWalletSetup)
final needsWalletSetupProvider = NeedsWalletSetupProvider._();

final class NeedsWalletSetupProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  NeedsWalletSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'needsWalletSetupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$needsWalletSetupHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return needsWalletSetup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$needsWalletSetupHash() => r'545d44110fa017455819c650536dd2f403fac4de';
