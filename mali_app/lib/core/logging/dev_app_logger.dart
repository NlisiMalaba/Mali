import 'dart:developer' as developer;

import 'package:mali_app/core/logging/app_logger.dart';

/// Writes to the Dart developer log, which is captured by `flutter logs` and
/// platform log sinks such as logcat.
class DevAppLogger implements IAppLogger {
  const DevAppLogger({String name = defaultLoggerName}) : _name = name;

  static const String defaultLoggerName = 'mali';

  // Levels mirror package:logging so external log sinks classify entries.
  static const int _infoLevel = 800;
  static const int _warningLevel = 900;
  static const int _errorLevel = 1000;

  final String _name;

  @override
  void info(String message) {
    developer.log(message, name: _name, level: _infoLevel);
  }

  @override
  void warning(String message, {Object? error}) {
    developer.log(message, name: _name, level: _warningLevel, error: error);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: _errorLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
