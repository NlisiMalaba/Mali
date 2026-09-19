class CategoryMonthQuery {
  const CategoryMonthQuery({
    required this.categoryId,
    required this.year,
    required this.month,
  });

  factory CategoryMonthQuery.fromMonth({
    required String categoryId,
    required DateTime month,
  }) {
    return CategoryMonthQuery(
      categoryId: categoryId,
      year: month.year,
      month: month.month,
    );
  }

  final String categoryId;
  final int year;
  final int month;

  DateTime get start => DateTime(year, month, 1);

  DateTime get end => DateTime(year, month + 1, 0, 23, 59, 59, 999, 999);

  @override
  bool operator ==(Object other) {
    return other is CategoryMonthQuery &&
        other.categoryId == categoryId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(categoryId, year, month);
}
