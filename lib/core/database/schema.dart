// lib/core/database/schema.dart
class Tables {
  const Tables._();

  static const todos = 'todos';
  static const todoCompletions = 'todo_completions';
  static const finishedTodos = 'finished_todos';
  static const logItems = 'log_items';
  static const logEntries = 'log_entries';
  static const categories = 'categories';
  static const goalActivities = 'goal_activities';
  static const goalLogs = 'goal_logs';
  static const countdownEvents = 'countdown_events';
}

class TodoCols {
  const TodoCols._();
  static const id = 'id';
  static const title = 'title';
  static const notes = 'notes';
  static const dueDate = 'due_date';
  static const reminderTime = 'reminder_time';
  static const reminderMode = 'reminder_mode';
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

class FinishedTodoCols {
  const FinishedTodoCols._();
  static const id = 'id';
  static const todoId = 'todo_id';
  static const title = 'title';
  static const completedAt = 'completed_at';
  static const recurrenceType = 'recurrence_type';
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

class CategoryCols {
  const CategoryCols._();
  static const id = 'id';
  static const title = 'title';
  static const description = 'description';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const archived = 'archived';
}

class GoalActivityCols {
  const GoalActivityCols._();
  static const id = 'id';
  static const categoryId = 'category_id';
  static const title = 'title';
  static const recurrenceType = 'recurrence_type';
  static const recurrenceConfig = 'recurrence_config';
  static const startDate = 'start_date';
  static const targetValue = 'target_value';
  static const targetUnit = 'target_unit';
  static const metric = 'metric';
  static const createdAt = 'created_at';
}

class GoalLogCols {
  const GoalLogCols._();
  static const id = 'id';
  static const goalActivityId = 'goal_activity_id';
  static const value = 'value';
  static const notes = 'notes';
  static const loggedAt = 'logged_at';
  static const createdAt = 'created_at';
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
