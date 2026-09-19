/// Optional narrowing applied to an export.
///
/// A null field means "no restriction on this dimension".
class ExportFilters {
  const ExportFilters({
    this.walletId,
    this.categoryId,
  });

  static const ExportFilters none = ExportFilters();

  final String? walletId;
  final String? categoryId;

  bool get isEmpty => walletId == null && categoryId == null;

  ExportFilters copyWith({
    String? walletId,
    String? categoryId,
    bool clearWalletId = false,
    bool clearCategoryId = false,
  }) {
    return ExportFilters(
      walletId: clearWalletId ? null : walletId ?? this.walletId,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportFilters &&
        other.walletId == walletId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(walletId, categoryId);
}
