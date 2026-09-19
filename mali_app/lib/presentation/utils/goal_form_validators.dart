import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/usecases/create_goal_usecase.dart';

class GoalFormValidators {
  const GoalFormValidators._();

  static String? goalName(String? value, {required bool touched}) {
    if (!touched) {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a goal name';
    }

    if (trimmed.length > CreateGoalUseCase.maxNameLength) {
      return 'Name must be ${CreateGoalUseCase.maxNameLength} characters or fewer';
    }

    return null;
  }

  static const int maxNoteLength = 200;

  static String? targetAmount(String? value, {required bool touched}) {
    return _positiveAmount(
      value,
      touched: touched,
      emptyMessage: 'Enter a target amount',
    );
  }

  static String? contributionAmount(String? value, {required bool touched}) {
    return _positiveAmount(
      value,
      touched: touched,
      emptyMessage: 'Enter a contribution amount',
    );
  }

  static String? contributionNote(String? value, {required bool touched}) {
    if (!touched) {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    if (trimmed.length > maxNoteLength) {
      return 'Note must be $maxNoteLength characters or fewer';
    }

    return null;
  }

  static String? _positiveAmount(
    String? value, {
    required bool touched,
    required String emptyMessage,
  }) {
    if (!touched) {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return emptyMessage;
    }

    try {
      if (Decimal.parse(trimmed) <= Decimal.zero) {
        return 'Enter an amount greater than zero';
      }
    } catch (_) {
      return 'Enter a valid amount';
    }

    return null;
  }
}
