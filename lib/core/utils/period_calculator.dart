// lib/core/utils/period_calculator.dart
class PeriodCalculator {
  const PeriodCalculator._();

  static DateTime dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime dayEnd(DateTime t) =>
      DateTime(t.year, t.month, t.day, 23, 59, 59, 999);

  static DateTime weekStart(DateTime t) {
    final day = dayStart(t);
    // DateTime.weekday: Monday=1 ... Sunday=7.
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime weekEnd(DateTime t) {
    final start = weekStart(t);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
  }

  static DateTime monthStart(DateTime t) => DateTime(t.year, t.month, 1);

  static DateTime monthEnd(DateTime t) {
    // First day of next month, then one millisecond before that moment of next day,
    // then back to 23:59:59.999 of the last day of this month.
    final nextMonthStart = (t.month == 12)
        ? DateTime(t.year + 1, 1, 1)
        : DateTime(t.year, t.month + 1, 1);
    return nextMonthStart.subtract(const Duration(milliseconds: 1));
  }
}
