import 'package:flutter/material.dart';

/// Grouped settings block with a section title and card-wrapped children.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _withDividers(
              children,
              theme.colorScheme.outlineVariant,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items, Color dividerColor) {
    if (items.isEmpty) {
      return items;
    }

    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result.add(
        Divider(
          height: 1,
          indent: 56,
          endIndent: 16,
          color: dividerColor,
        ),
      );
      result.add(items[i]);
    }
    return result;
  }
}
