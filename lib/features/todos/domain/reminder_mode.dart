enum ReminderMode {
  notification('notification', 'Notification'),
  alarm('alarm', 'Alarm'),
  notificationAndAlarm('notification_and_alarm', 'Notification + alarm');

  const ReminderMode(this.wire, this.label);

  final String wire;
  final String label;

  static ReminderMode parse(String? wire) {
    for (final mode in ReminderMode.values) {
      if (mode.wire == wire) return mode;
    }
    return ReminderMode.notificationAndAlarm;
  }
}
