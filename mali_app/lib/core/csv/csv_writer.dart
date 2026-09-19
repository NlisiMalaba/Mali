/// Minimal RFC 4180 CSV encoder.
class CsvWriter {
  const CsvWriter._();

  static const String fieldSeparator = ',';

  /// RFC 4180 mandates CRLF, which also keeps Excel from joining rows.
  static const String lineTerminator = '\r\n';

  static const String _quote = '"';

  /// Characters that force a field to be quoted.
  static const List<String> _mustQuote = [
    fieldSeparator,
    _quote,
    '\r',
    '\n',
  ];

  /// Encodes [rows] into a CSV body, including a trailing line terminator.
  static String encode(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.write(row.map(escapeField).join(fieldSeparator));
      buffer.write(lineTerminator);
    }
    return buffer.toString();
  }

  /// Quotes [value] when required, doubling any embedded quotes.
  ///
  /// Leading or trailing whitespace is also quoted, so it survives parsers
  /// that trim unquoted fields.
  static String escapeField(String value) {
    final needsQuoting = _mustQuote.any(value.contains) ||
        value.trim().length != value.length;
    if (!needsQuoting) {
      return value;
    }

    final escaped = value.replaceAll(_quote, '$_quote$_quote');
    return '$_quote$escaped$_quote';
  }
}
