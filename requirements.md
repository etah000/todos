## Overview

Implement a local-first Android app with Flutter. The app tracks everyday
tasks, numeric logs, goal activities, and countdown dates without requiring
accounts or cloud sync.

## Features

1. Todos
  - Support one-time todos.
  - Support periodic todos: daily, weekly, and monthly.
  - Support optional clock reminders through local notifications.
  - Allow a todo item to be finished in advance for the current recurrence
    period. Example: if rent is due before the 28th of each month, the user can
    finish it on the 26th or 27th and see it as completed for that month.
  - Keep one-time completed todos out of the active list after completion.
  - Keep recurring todos active and show whether they are completed in the
    current period.

2. Log data, no predefined goals
  - Let users create arbitrary log items, such as weight, mood score, or other
    numeric routines.
  - Let users add dated numeric entries for each item.
  - Visualize item changes for the current week or current month.

3. Track goals and plans
  - Let users set goals with a title, time range, and optional description.
  - Let users add periodic activities to a goal, such as workout or reading.
  - Support boolean, count, and duration activity tracking.
  - Track activity execution by recurrence period.
  - Logging count or duration activity progress counts as execution for that
    activity's current period.
  - Visualize current-period activity completion and weekly activity execution
    status.

4. Countdown
  - Let users create countdown events with a target date.
  - Show whole days remaining until the target date, including today and past
    dates.
