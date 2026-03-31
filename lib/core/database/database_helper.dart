import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Cross-platform storage backend using SharedPreferences + JSON.
/// Works on Web, Android, iOS, Windows, macOS, and Linux.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _kTasksKey = 'flodo_tasks';
  static const _kNextIdKey = 'flodo_next_id';

  /// No-op: kept for API compatibility with the old SQLite version.
  static void initFfiIfNeeded() {}

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<List<Task>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTasksKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveAll(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_kTasksKey, encoded);
  }

  Future<int> _nextId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt(_kNextIdKey) ?? 0) + 1;
    await prefs.setInt(_kNextIdKey, id);
    return id;
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<Task> insertTask(Task task) async {
    final tasks = await _loadAll();
    final maxOrder = tasks.isEmpty
        ? -1
        : tasks.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);
    final id = await _nextId();
    final newTask = task.copyWith(id: id, sortOrder: maxOrder + 1);
    tasks.add(newTask);
    await _saveAll(tasks);
    return newTask;
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  Future<List<Task>> getAllTasks() async {
    final tasks = await _loadAll();
    tasks.sort((a, b) {
      final orderCmp = a.sortOrder.compareTo(b.sortOrder);
      if (orderCmp != 0) return orderCmp;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return tasks;
  }

  Future<Task?> getTaskById(int id) async {
    final tasks = await _loadAll();
    try {
      return tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<Task> updateTask(Task task) async {
    final tasks = await _loadAll();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx] = task;
      await _saveAll(tasks);
    }
    return task;
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> deleteTask(int id) async {
    var tasks = await _loadAll();
    // Un-block any tasks blocked by this one
    tasks = tasks.map((t) {
      if (t.blockedById == id) return t.copyWith(blockedById: null);
      return t;
    }).toList();
    tasks.removeWhere((t) => t.id == id);
    await _saveAll(tasks);
  }

  // ─── REORDER ──────────────────────────────────────────────────────────────

  Future<void> reorderTasks(List<Task> tasks) async {
    final updated = <Task>[];
    for (var i = 0; i < tasks.length; i++) {
      updated.add(tasks[i].copyWith(sortOrder: i));
    }
    await _saveAll(updated);
  }
}
