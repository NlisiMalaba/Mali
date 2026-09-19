enum ExportFormat {
  pdf('PDF'),
  csv('CSV');

  const ExportFormat(this.label);

  /// Short name shown in the format selector.
  final String label;
}
