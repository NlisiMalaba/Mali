import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';

/// Glassmorphism top bar with profile avatar, Mali branding, and actions.
class SovereignAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SovereignAppBar({
    this.title,
    this.showBackButton = false,
    this.onNotificationTap,
    this.actions,
    super.key,
  });

  final String? title;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;
  final List<Widget>? actions;

  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final userName = auth.maybeWhen(
      data: (user) => user?.name ?? '',
      orElse: () => '',
    );
    final initial = userName.isNotEmpty
        ? userName.characters.first.toUpperCase()
        : 'M';

    return AppDecorations.glassBar(
      backgroundColor: isDark
          ? AppColors.darkSurface
          : AppColors.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: Text(
                      initial,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (!showBackButton)
                  Text(
                    'Mali',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                if (title != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (actions != null) ...actions!,
                IconButton(
                  key: const Key('sovereign-notifications-button'),
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppColors.primary,
                  tooltip: 'Settings',
                  onPressed:
                      onNotificationTap ?? () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
