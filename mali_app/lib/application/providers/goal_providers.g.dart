// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeGoals)
final activeGoalsProvider = ActiveGoalsProvider._();

final class ActiveGoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavingsGoal>>,
          List<SavingsGoal>,
          Stream<List<SavingsGoal>>
        >
    with
        $FutureModifier<List<SavingsGoal>>,
        $StreamProvider<List<SavingsGoal>> {
  ActiveGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGoalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGoalsHash();

  @$internal
  @override
  $StreamProviderElement<List<SavingsGoal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavingsGoal>> create(Ref ref) {
    return activeGoals(ref);
  }
}

String _$activeGoalsHash() => r'73ee2e0351982dab47ded028b7d29b4304d96d85';

@ProviderFor(goalContributions)
final goalContributionsProvider = GoalContributionsFamily._();

final class GoalContributionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalContribution>>,
          List<GoalContribution>,
          Stream<List<GoalContribution>>
        >
    with
        $FutureModifier<List<GoalContribution>>,
        $StreamProvider<List<GoalContribution>> {
  GoalContributionsProvider._({
    required GoalContributionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalContributionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalContributionsHash();

  @override
  String toString() {
    return r'goalContributionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GoalContribution>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GoalContribution>> create(Ref ref) {
    final argument = this.argument as String;
    return goalContributions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalContributionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalContributionsHash() => r'6dc6141431f760a135cc99628c70b17607af0546';

final class GoalContributionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GoalContribution>>, String> {
  GoalContributionsFamily._()
    : super(
        retry: null,
        name: r'goalContributionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoalContributionsProvider call(String goalId) =>
      GoalContributionsProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalContributionsProvider';
}
