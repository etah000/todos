import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/logs/domain/log_item.dart';

void main() {
  group('LogItem', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final item = LogItem(
        id: 'i1', name: 'weight', unit: 'kg', color: 0xFF3F51B5,
        createdAt: now, archived: false,
      );
      final back = LogItem.fromMap(item.toMap());
      expect(back, item);
    });

    test('fromMap tolerates null color and unit', () {
      final m = {
        'id': 'i1', 'name': 'mood', 'unit': null, 'color': null,
        'created_at': now.millisecondsSinceEpoch, 'archived': 0,
      };
      final item = LogItem.fromMap(m);
      expect(item.color, isNull);
      expect(item.unit, isNull);
    });
  });
}