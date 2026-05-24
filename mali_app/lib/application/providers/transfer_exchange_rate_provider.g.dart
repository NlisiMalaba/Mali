// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_exchange_rate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(suggestedTransferExchangeRate)
final suggestedTransferExchangeRateProvider =
    SuggestedTransferExchangeRateFamily._();

final class SuggestedTransferExchangeRateProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  SuggestedTransferExchangeRateProvider._({
    required SuggestedTransferExchangeRateFamily super.from,
    required TransferRateKey super.argument,
  }) : super(
         retry: null,
         name: r'suggestedTransferExchangeRateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suggestedTransferExchangeRateHash();

  @override
  String toString() {
    return r'suggestedTransferExchangeRateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as TransferRateKey;
    return suggestedTransferExchangeRate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedTransferExchangeRateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suggestedTransferExchangeRateHash() =>
    r'2062d808472cca8e2bb85494e1701af89ee1afe2';

final class SuggestedTransferExchangeRateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, TransferRateKey> {
  SuggestedTransferExchangeRateFamily._()
    : super(
        retry: null,
        name: r'suggestedTransferExchangeRateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SuggestedTransferExchangeRateProvider call(TransferRateKey key) =>
      SuggestedTransferExchangeRateProvider._(argument: key, from: this);

  @override
  String toString() => r'suggestedTransferExchangeRateProvider';
}
