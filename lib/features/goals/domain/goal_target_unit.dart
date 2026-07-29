enum GoalTargetUnit {
  perDay('per_day'),
  perWeek('per_week'),
  perMonth('per_month'),
  perPeriod('per_period');

  const GoalTargetUnit(this.wire);
  final String wire;

  static GoalTargetUnit parse(String? wire) {
    for (final u in GoalTargetUnit.values) {
      if (u.wire == wire) return u;
    }
    return GoalTargetUnit.perPeriod;
  }
}