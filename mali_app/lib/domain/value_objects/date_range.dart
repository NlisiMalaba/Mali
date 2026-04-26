class DateRange {
  DateRange({
    required DateTime start,
    required DateTime end,
  })  : start = _normalize(start),
        end = _normalize(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError.value(
        '$start - $end',
        'end',
        'End date must be on or after start date.',
      );
    }
  }

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  bool contains(DateTime date) {
    final candidate = _normalize(date);
    return !candidate.isBefore(start) && !candidate.isAfter(end);
  }

  DateRange copyWith({
    DateTime? start,
    DateTime? end,
  }) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  static DateTime _normalize(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
