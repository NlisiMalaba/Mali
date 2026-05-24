import 'package:flutter/material.dart';
import 'package:mali_app/presentation/utils/greeting.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    required this.userName,
    super.key,
  });

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      Greeting.forUser(name: userName, now: DateTime.now()),
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
