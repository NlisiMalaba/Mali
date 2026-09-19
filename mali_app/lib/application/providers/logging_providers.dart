import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/core/logging/dev_app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logging_providers.g.dart';

@Riverpod(keepAlive: true)
IAppLogger appLogger(Ref ref) {
  return const DevAppLogger();
}
