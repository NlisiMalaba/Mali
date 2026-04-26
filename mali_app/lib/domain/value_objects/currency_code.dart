class CurrencyCode {
  const CurrencyCode._(this.value);

  factory CurrencyCode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (!_supportedCodes.contains(normalized)) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Unsupported currency code. Supported: ${_supportedCodes.join(', ')}',
      );
    }
    return CurrencyCode._(normalized);
  }

  static const Set<String> _supportedCodes = {'USD', 'ZWG', 'ZAR', 'BWP'};

  static const CurrencyCode usd = CurrencyCode._('USD');
  static const CurrencyCode zwg = CurrencyCode._('ZWG');
  static const CurrencyCode zar = CurrencyCode._('ZAR');
  static const CurrencyCode bwp = CurrencyCode._('BWP');

  static List<CurrencyCode> get values => const [usd, zwg, zar, bwp];

  final String value;

  bool get isUsd => this == usd;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CurrencyCode && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
