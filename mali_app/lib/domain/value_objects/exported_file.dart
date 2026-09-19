/// A document that has been written to the device.
class ExportedFile {
  const ExportedFile({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.byteCount,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final int byteCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportedFile &&
        other.path == path &&
        other.fileName == fileName &&
        other.mimeType == mimeType &&
        other.byteCount == byteCount;
  }

  @override
  int get hashCode => Object.hash(path, fileName, mimeType, byteCount);
}
