import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/logs/domain/log_entry.dart';

void main() {
  group('LogEntry', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final e = LogEntry(
        id: 'e1',
        logItemId: 'i1',
        value: 80.5,
        notes: 'after lunch',
        loggedAt: at,
        createdAt: at,
      );
      final back = LogEntry.fromMap(e.toMap());
      expect(back, e);
    });
  });
}
