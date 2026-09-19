/// Logging boundary so services (including background isolates, where no UI is
/// available to surface errors) can record diagnostics without depending on a
/// concrete logging backend.
abstract interface class IAppLogger {
  void info(String message);

  void warning(String message, {Object? error});

  void error(String message, {Object? error, StackTrace? stackTrace});
}
