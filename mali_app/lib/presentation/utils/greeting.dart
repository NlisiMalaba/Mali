class Greeting {
  const Greeting._();

  static String timeOfDay(DateTime now) {
    final hour = now.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  static String forUser({
    required String name,
    required DateTime now,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return timeOfDay(now);
    }
    return '${timeOfDay(now)}, $trimmed';
  }
}
