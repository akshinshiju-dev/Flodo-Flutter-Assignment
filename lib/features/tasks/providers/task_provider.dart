import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/task.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskStatus? _filterStatus; // null = show all
  bool _isLoading = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TaskStatus? get filterStatus => _filterStatus;

  /// All tasks (unfiltered), used for "blocked by" dropdown
  List<Task> get allTasks => List.unmodifiable(_tasks);

  /// Filtered + searched list shown in the UI
  List<Task> get filteredTasks {
    var result = _tasks;

    // Apply status filter
    if (_filterStatus != null) {
      result = result.where((t) => t.status == _filterStatus).toList();
    }

    // Apply search (case-insensitive title match)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  /// Map of id → Task for quick lookup (blocked-by resolution)
  Map<int, Task> get _taskMap =>
      {for (final t in _tasks) if (t.id != null) t.id!: t};

  /// Returns true if [task] is actively blocked (blocker exists & not done)
  bool isBlocked(Task task) {
    if (task.blockedById == null) return false;
    final blocker = _taskMap[task.blockedById!];
    if (blocker == null) return false;
    return blocker.status != TaskStatus.done;
  }

  /// Returns the blocking task for [task], or null
  Task? blockerOf(Task task) {
    if (task.blockedById == null) return null;
    return _taskMap[task.blockedById!];
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _db.getAllTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<Task> createTask(Task task) async {
    // Simulate 2-second network delay as required
    await Future.delayed(const Duration(seconds: 2));
    final created = await _db.insertTask(task);
    _tasks.add(created);
    notifyListeners();
    return created;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<Task> updateTask(Task task) async {
    // Simulate 2-second network delay as required
    await Future.delayed(const Duration(seconds: 2));
    final updated = await _db.updateTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = updated;
    }
    notifyListeners();
    return updated;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    // Also clear any in-memory blocked_by references
    _tasks = _tasks.map((t) {
      if (t.blockedById == id) return t.copyWith(blockedById: null);
      return t;
    }).toList();
    notifyListeners();
  }

  // ─── Search & Filter ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(TaskStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // ─── Reorder ──────────────────────────────────────────────────────────────

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    notifyListeners();
    await _db.reorderTasks(_tasks);
  }
}
