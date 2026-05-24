// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_card_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletEquivalentLabel)
final walletEquivalentLabelProvider = WalletEquivalentLabelFamily._();

final class WalletEquivalentLabelProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  WalletEquivalentLabelProvider._({
    required WalletEquivalentLabelFamily super.from,
    required WalletEquivalentKey super.argument,
  }) : super(
         retry: null,
         name: r'walletEquivalentLabelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$walletEquivalentLabelHash();

  @override
  String toString() {
    return r'walletEquivalentLabelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as WalletEquivalentKey;
    return walletEquivalentLabel(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletEquivalentLabelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletEquivalentLabelHash() =>
    r'90607ff99930a5c4f36834922a1306a6a8834913';

final class WalletEquivalentLabelFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, WalletEquivalentKey> {
  WalletEquivalentLabelFamily._()
    : super(
        retry: null,
        name: r'walletEquivalentLabelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WalletEquivalentLabelProvider call(WalletEquivalentKey key) =>
      WalletEquivalentLabelProvider._(argument: key, from: this);

  @override
  String toString() => r'walletEquivalentLabelProvider';
}
