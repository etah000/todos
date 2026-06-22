import 'package:flutter_test/flutter_test.dart';
import 'package:todos/core/notifications/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('scheduled id is stable for the same key', () {
      final a = NotificationService.idForKey('todo:abc');
      final b = NotificationService.idForKey('todo:abc');
      expect(a, b);
    });

    test('scheduled id differs for different keys', () {
      expect(
        NotificationService.idForKey('todo:abc'),
        isNot(NotificationService.idForKey('todo:def')),
      );
    });

    test('idForKey returns a positive 32-bit int', () {
      final v = NotificationService.idForKey('any-key');
      expect(v, greaterThan(0));
      expect(v, lessThan(1 << 31));
    });
  });
}
