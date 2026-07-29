class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.periodsElapsed,
    required this.periodsCompleted,
    required this.percent,
    required this.lifetimeTotal,
  });

  factory GoalProgressSnapshot.empty() => const GoalProgressSnapshot(
        periodsElapsed: 0,
        periodsCompleted: 0,
        percent: 0,
        lifetimeTotal: GoalLifetimeTotalBoolean(0),
      );

  final int periodsElapsed;
  final int periodsCompleted;
  final double percent;
  final GoalLifetimeTotal lifetimeTotal;
}

sealed class GoalLifetimeTotal {
  const GoalLifetimeTotal();
}

class GoalLifetimeTotalBoolean extends GoalLifetimeTotal {
  const GoalLifetimeTotalBoolean(this.count);
  final int count;
}

class GoalLifetimeTotalCount extends GoalLifetimeTotal {
  const GoalLifetimeTotalCount(this.total);
  final double total;
}

class GoalLifetimeTotalDuration extends GoalLifetimeTotal {
  const GoalLifetimeTotalDuration(this.totalSeconds);
  final int totalSeconds;
}
