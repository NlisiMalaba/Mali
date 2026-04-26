class ExchangeRate {
  const ExchangeRate({
    required this.id,
    required this.baseCurrencyCode,
    required this.quoteCurrencyCode,
    required this.rate,
    required this.isManual,
    required this.rateDate,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String baseCurrencyCode;
  final String quoteCurrencyCode;
  final String rate;
  final bool isManual;
  final DateTime rateDate;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExchangeRate copyWith({
    String? id,
    String? baseCurrencyCode,
    String? quoteCurrencyCode,
    String? rate,
    bool? isManual,
    DateTime? rateDate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExchangeRate(
      id: id ?? this.id,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      quoteCurrencyCode: quoteCurrencyCode ?? this.quoteCurrencyCode,
      rate: rate ?? this.rate,
      isManual: isManual ?? this.isManual,
      rateDate: rateDate ?? this.rateDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExchangeRate &&
        other.id == id &&
        other.baseCurrencyCode == baseCurrencyCode &&
        other.quoteCurrencyCode == quoteCurrencyCode &&
        other.rate == rate &&
        other.isManual == isManual &&
        other.rateDate == rateDate &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        baseCurrencyCode,
        quoteCurrencyCode,
        rate,
        isManual,
        rateDate,
        isSynced,
        createdAt,
        updatedAt,
      );
}
