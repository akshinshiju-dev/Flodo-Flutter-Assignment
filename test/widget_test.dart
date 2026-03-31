import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flodo_task_manager/core/models/task.dart';
import 'package:flodo_task_manager/core/theme/app_theme.dart';
import 'package:flodo_task_manager/features/tasks/providers/task_provider.dart';
import 'package:flodo_task_manager/features/tasks/widgets/task_card.dart';
import 'package:flodo_task_manager/features/tasks/widgets/highlighted_text.dart';
import 'package:flodo_task_manager/features/tasks/widgets/status_filter_chips.dart';
import 'package:flodo_task_manager/shared/widgets/loading_button.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] with the providers and theme required by Flodo widgets.
Widget _wrap(Widget child, {TaskProvider? provider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>.value(
        value: provider ?? TaskProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

// ---------------------------------------------------------------------------
// Task model tests
// ---------------------------------------------------------------------------

void main() {
  group('Task model', () {
    final task = Task(
      id: 1,
      title: 'Write tests',
      description: 'Cover the main logic',
      dueDate: DateTime(2025, 6, 1),
      status: TaskStatus.todo,
    );

    test('copyWith preserves values when no args passed', () {
      final copy = task.copyWith();
      expect(copy.id, task.id);
      expect(copy.title, task.title);
      expect(copy.status, task.status);
      expect(copy.blockedById, isNull);
    });

    test('copyWith can set blockedById to null explicitly', () {
      final blocked = task.copyWith(blockedById: 99);
      expect(blocked.blockedById, 99);
      final unblocked = blocked.copyWith(blockedById: null);
      expect(unblocked.blockedById, isNull);
    });

    test('toMap / fromMap round-trip', () {
      final map = task.toMap();
      final restored = Task.fromMap({...map, 'id': 1});
      expect(restored.title, task.title);
      expect(restored.status, task.status);
      expect(restored.dueDate.year, task.dueDate.year);
    });

    test('TaskStatus.fromString returns correct enum', () {
      expect(TaskStatus.fromString('todo'), TaskStatus.todo);
      expect(TaskStatus.fromString('inProgress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('done'), TaskStatus.done);
      expect(TaskStatus.fromString('unknown'), TaskStatus.todo); // default
    });

    test('equality is id-based', () {
      final a = task.copyWith(title: 'Different title');
      expect(a, equals(task)); // same id → equal
    });
  });

  // -------------------------------------------------------------------------
  // TaskProvider unit tests (no DB – uses in-memory state only)
  // -------------------------------------------------------------------------
  group('TaskProvider – blocked logic', () {
    test('isBlocked returns false when blockedById is null', () {
      final provider = TaskProvider();
      final t = Task(
        id: 1,
        title: 'Free',
        description: '',
        dueDate: DateTime.now(),
      );
      expect(provider.isBlocked(t), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Widget tests
  // -------------------------------------------------------------------------
  group('HighlightedText widget', () {
    testWidgets('renders plain text when highlight is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Hello World',
              highlight: '',
              highlightColor: Colors.purple,
            ),
          ),
        ),
      );
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('uses RichText when highlight is non-empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Hello World',
              highlight: 'World',
              highlightColor: Colors.purple,
            ),
          ),
        ),
      );
      // RichText is used instead of plain Text
      expect(find.byType(RichText), findsWidgets);
    });
  });

  group('LoadingButton widget', () {
    testWidgets('shows label when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LoadingButton(
              label: 'Save',
              isLoading: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner and disables button when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LoadingButton(
              label: 'Save',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(); // allow AnimatedSwitcher to finish
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving…'), findsOneWidget);

      // Button must be disabled (onPressed = null when isLoading=true)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('StatusFilterChips widget', () {
    testWidgets('renders 4 chips (All + 3 statuses)', (tester) async {
      await tester.pumpWidget(_wrap(const StatusFilterChips()));
      await tester.pump();

      // Labels: All, To-Do, In Progress, Done
      expect(find.text('All'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('TaskCard widget', () {
    final dueDate = DateTime(2030, 12, 31);
    final task = Task(
      id: 42,
      title: 'My Test Task',
      description: 'Some details here',
      dueDate: dueDate,
      status: TaskStatus.inProgress,
    );

    testWidgets('displays title and description', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TaskCard(
            task: task,
            searchQuery: '',
            onTap: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('My Test Task'), findsWidgets);
      expect(find.textContaining('Some details here'), findsOneWidget);
    });

    testWidgets('shows In Progress status chip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TaskCard(
            task: task,
            searchQuery: '',
            onTap: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('BLOCKED badge hidden for unblocked task', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TaskCard(
            task: task,
            searchQuery: '',
            onTap: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('BLOCKED'), findsNothing);
    });

    testWidgets('delete icon triggers callback', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _wrap(
          TaskCard(
            task: task,
            searchQuery: '',
            onTap: () {},
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);
    });
  });
}
