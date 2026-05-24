abstract interface class INotificationService {
  Future<void> initialize();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}
