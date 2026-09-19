enum GoalPreset {
  car,
  schoolFees,
  emergencyFund,
  house,
  vacation,
  wedding,
  device,
  custom;

  String get id => switch (this) {
        GoalPreset.car => 'car',
        GoalPreset.schoolFees => 'school_fees',
        GoalPreset.emergencyFund => 'emergency_fund',
        GoalPreset.house => 'house',
        GoalPreset.vacation => 'vacation',
        GoalPreset.wedding => 'wedding',
        GoalPreset.device => 'device',
        GoalPreset.custom => 'custom',
      };

  String get label => switch (this) {
        GoalPreset.car => 'Car',
        GoalPreset.schoolFees => 'School Fees',
        GoalPreset.emergencyFund => 'Emergency Fund',
        GoalPreset.house => 'House',
        GoalPreset.vacation => 'Vacation',
        GoalPreset.wedding => 'Wedding',
        GoalPreset.device => 'Device',
        GoalPreset.custom => 'Custom',
      };

  String get emoji => switch (this) {
        GoalPreset.car => '🚗',
        GoalPreset.schoolFees => '🎓',
        GoalPreset.emergencyFund => '🛟',
        GoalPreset.house => '🏠',
        GoalPreset.vacation => '✈️',
        GoalPreset.wedding => '💍',
        GoalPreset.device => '💻',
        GoalPreset.custom => '🎯',
      };

  static const List<String> extraEmojis = [
    '💰',
    '📈',
    '🍼',
    '🏥',
    '🎁',
    '📦',
  ];

  static List<String> get emojiChoices {
    final seen = <String>{};
    final choices = <String>[];
    for (final preset in GoalPreset.values) {
      if (seen.add(preset.emoji)) {
        choices.add(preset.emoji);
      }
    }
    for (final emoji in extraEmojis) {
      if (seen.add(emoji)) {
        choices.add(emoji);
      }
    }
    return choices;
  }

  static GoalPreset matching({required String name, String? emoji}) {
    for (final preset in GoalPreset.values) {
      if (preset == GoalPreset.custom) {
        continue;
      }
      if (preset.label == name || (emoji != null && preset.emoji == emoji)) {
        return preset;
      }
    }
    return GoalPreset.custom;
  }
}
