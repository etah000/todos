// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/countdown/presentation/pages/countdown_list_page.dart';
import 'features/goals/presentation/pages/goal_list_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/logs/presentation/pages/log_list_page.dart';
import 'features/todos/presentation/pages/todo_list_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/todos',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomePage(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/todos',
              builder: (c, s) => const TodoListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/logs',
              builder: (c, s) => const LogListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              builder: (c, s) => const GoalListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/countdown',
              builder: (c, s) => const CountdownListPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
