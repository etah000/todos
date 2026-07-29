import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';

void main() {
  test('wire strings round-trip through parse', () {
    for (final u in GoalTargetUnit.values) {
      expect(GoalTargetUnit.parse(u.wire), equals(u));
    }
  });

  test('unknown wire defaults to perPeriod', () {
    expect(GoalTargetUnit.parse('garbage'), GoalTargetUnit.perPeriod);
  });

  test('null wire defaults to perPeriod', () {
    expect(GoalTargetUnit.parse(null), GoalTargetUnit.perPeriod);
  });
}