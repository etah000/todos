// lib/core/database/schema.dart
class Tables {
  const Tables._();

  static const todos = 'todos';
  static const todoCompletions = 'todo_completions';
  static const logItems = 'log_items';
  static const logEntries = 'log_entries';
  static const goals = 'goals';
  static const goalActivities = 'goal_activities';
  static const activityCompletions = 'activity_completions';
  static const countdownEvents = 'countdown_events';
}

class TodoCols {
  const TodoCols._();
  static const id = 'id';
  static const title = 'title';
  static const notes = 'notes';
  static const dueDate = 'due_date';
  static const reminderTime = 'reminder_time';
  static const recurrenceType = 'recurrence_type';
  static const recurrenceConfig = 'recurrence_config';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const archived = 'archived';
}

class TodoCompletionCols {
  const TodoCompletionCols._();
  static const id = 'id';
  static const todoId = 'todo_id';
  static const periodStart = 'period_start';
  static const periodEnd = 'period_end';
  static const completedAt = 'completed_at';
  static const notes = 'notes';
}

class LogItemCols {
  const LogItemCols._();
  static const id = 'id';
  static const name = 'name';
  static const unit = 'unit';
  static const color = 'color';
  static const createdAt = 'created_at';
  static const archived = 'archived';
}

class LogEntryCols {
  const LogEntryCols._();
  static const id = 'id';
  static const logItemId = 'log_item_id';
  static const value = 'value';
  static const notes = 'notes';
  static const loggedAt = 'logged_at';
  static const createdAt = 'created_at';
}

class GoalCols {
  const GoalCols._();
  static const id = 'id';
  static const title = 'title';
  static const description = 'description';
  static const startDate = 'start_date';
  static const endDate = 'end_date';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const archived = 'archived';
}

class GoalActivityCols {
  const GoalActivityCols._();
  static const id = 'id';
  static const goalId = 'goal_id';
  static const title = 'title';
  static const recurrenceType = 'recurrence_type';
  static const recurrenceConfig = 'recurrence_config';
  static const createdAt = 'created_at';
}

class ActivityCompletionCols {
  const ActivityCompletionCols._();
  static const id = 'id';
  static const activityId = 'activity_id';
  static const periodStart = 'period_start';
  static const periodEnd = 'period_end';
  static const completedAt = 'completed_at';
  static const notes = 'notes';
}

class CountdownEventCols {
  const CountdownEventCols._();
  static const id = 'id';
  static const title = 'title';
  static const targetDate = 'target_date';
  static const notes = 'notes';
  static const createdAt = 'created_at';
  static const archived = 'archived';
}
