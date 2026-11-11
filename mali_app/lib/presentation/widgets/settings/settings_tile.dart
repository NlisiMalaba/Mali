import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Settings row matching the HTML redesign (54px tall, trailing meta + chevron).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.iconColor,
    this.iconBackground,
    this.subtitleInline = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final Color? iconColor;
  final Color? iconBackground;
  final bool subtitleInline;

  static const double rowHeight = 54;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? AppColors.secondary;
    final resolvedIconBg =
        iconBackground ?? AppColors.secondary.withValues(alpha: 0.12);
    final inlineSubtitle =
        subtitleInline && subtitle != null && trailing == null;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: inlineSubtitle
                    ? Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
              ),
              if (inlineSubtitle)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              trailing ??
                  (showChevron && onTap != null
                      ? const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        )
                      : null) ??
                  const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      subtitleInline: false,
      showChevron: false,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
