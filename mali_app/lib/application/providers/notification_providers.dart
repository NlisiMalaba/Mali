import 'package:mali_app/core/notifications/local_notification_service.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
INotificationService notificationService(Ref ref) {
  return LocalNotificationService.instance;
}
