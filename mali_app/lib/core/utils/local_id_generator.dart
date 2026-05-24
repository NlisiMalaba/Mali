/// Generates locally unique identifiers for offline-first entities.
class LocalIdGenerator {
  const LocalIdGenerator._();

  static String newId(String prefix) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$prefix-$timestamp';
  }
}
