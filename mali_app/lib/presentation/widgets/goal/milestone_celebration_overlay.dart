import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/goal_milestone_messages.dart';
import 'package:mali_app/presentation/widgets/goal/milestone_confetti.dart';

class MilestoneCelebrationOverlay extends StatefulWidget {
  const MilestoneCelebrationOverlay({
    required this.milestone,
    super.key,
  });

  static const Key overlayKey = Key('milestone-celebration-overlay');
  static const Duration autoDismissDuration = Duration(seconds: 3);
  static const Duration transitionDuration = Duration(milliseconds: 200);
  static const Duration scaleDuration = Duration(milliseconds: 550);
  static const double cardMaxWidth = 320;
  static const double emojiFontSize = 48;

  final GoalMilestone milestone;

  /// Presents the celebration dialog with a confetti burst.
  /// Auto-dismisses after [autoDismissDuration].
  static Future<void> show(
    BuildContext context, {
    required GoalMilestone milestone,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    var isOpen = true;
    late final Timer timer;
    final future = showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss celebration',
      barrierColor: Colors.black54,
      transitionDuration: transitionDuration,
      pageBuilder: (context, _, _) {
        return MilestoneCelebrationOverlay(milestone: milestone);
      },
    ).whenComplete(() {
      isOpen = false;
      timer.cancel();
    });
    timer = Timer(autoDismissDuration, () {
      if (!isOpen) {
        return;
      }
      navigator.pop();
    });
    return future;
  }

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MilestoneCelebrationOverlay.scaleDuration,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = GoalMilestoneMessages.forMilestone(widget.milestone);
    final emoji = GoalMilestoneMessages.emojiFor(widget.milestone);

    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: MilestoneConfetti(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: MilestoneCelebrationOverlay.cardMaxWidth,
                  ),
                  child: Material(
                    key: MilestoneCelebrationOverlay.overlayKey,
                    color: theme.colorScheme.surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(
                              fontSize:
                                  MilestoneCelebrationOverlay.emojiFontSize,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            key: const Key('milestone-celebration-message'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
