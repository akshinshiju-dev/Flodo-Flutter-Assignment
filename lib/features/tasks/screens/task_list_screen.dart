import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/status_filter_chips.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // Load tasks on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  // ─── Debounced search: 300ms after user stops typing ──────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<TaskProvider>().setSearchQuery(value);
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    context.read<TaskProvider>().setSearchQuery('');
  }

  // ─── Navigate to form ─────────────────────────────────────────────────────
  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task created ✓'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openEdit(Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task updated ✓'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Task?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: colors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteTask(task.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted'),
            backgroundColor:
                Theme.of(context).extension<AppColors>()!.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<TaskProvider>();
    final tasks = provider.filteredTasks;
    final searchQuery = provider.searchQuery;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, colors, isDark),
      floatingActionButton: _buildFAB(colors),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          _SearchBar(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          const SizedBox(height: 12),

          // Filter chips
          const StatusFilterChips(),
          const SizedBox(height: 12),

          // Stats row
          _StatsRow(provider: provider),
          const SizedBox(height: 8),

          // Task list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? _EmptyState(hasSearch: searchQuery.isNotEmpty)
                    : _TaskList(
                        tasks: tasks,
                        searchQuery: searchQuery,
                        onTap: _openEdit,
                        onDelete: _deleteTask,
                      ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
      BuildContext context, AppColors colors, bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Flodo Tasks',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, fontSize: 20)),
        ],
      ),
      actions: [
        // Theme toggle
        IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onPressed: () {
            final notifier = context.read<ThemeModeNotifier>();
            // toggle() is async (persists to SharedPreferences) — fire & forget
            unawaited(notifier.toggle());
          },
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFAB(AppColors colors) {
    return ScaleTransition(
      scale: CurvedAnimation(
          parent: _fabController, curve: Curves.easeOutBack),
      child: FloatingActionButton.extended(
        heroTag: 'fab-create',
        onPressed: _openCreate,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: Text('New Task',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _fabController.dispose();
    super.dispose();
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // ValueListenableBuilder ensures the clear button shows/hides
      // reactively as the user types — a StatelessWidget reading
      // controller.text directly would only evaluate it once at build time.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks…',
              prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: colors.muted, size: 18),
                      onPressed: onClear,
                    )
                  : null,
            ),
            style: GoogleFonts.inter(fontSize: 14),
          );
        },
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TaskProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final all = provider.allTasks;
    final todo = all.where((t) => t.status == TaskStatus.todo).length;
    final inProg =
        all.where((t) => t.status == TaskStatus.inProgress).length;
    final done = all.where((t) => t.status == TaskStatus.done).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatBadge(count: todo, label: 'To-Do', color: colors.info),
          const SizedBox(width: 8),
          _StatBadge(count: inProg, label: 'In Progress', color: colors.warning),
          const SizedBox(width: 8),
          _StatBadge(count: done, label: 'Done', color: colors.success),
          const Spacer(),
          Text(
            '${provider.filteredTasks.length} task${provider.filteredTasks.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(fontSize: 12, color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─── Task List ────────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String searchQuery;
  final void Function(Task) onTap;
  final void Function(Task) onDelete;

  const _TaskList({
    required this.tasks,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return TaskCard(
          key: ValueKey(task.id),
          task: task,
          searchQuery: searchQuery,
          onTap: () => onTap(task),
          onDelete: () => onDelete(task),
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.task_alt,
                size: 36,
                color: colors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'No results found' : 'No tasks yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Tap the + button to create your first task',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Theme Mode Notifier ──────────────────────────────────────────────────────

class ThemeModeNotifier extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode_dark';

  ThemeModeNotifier._internal(this._mode);

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Loads the persisted preference and returns an initialized notifier.
  static Future<ThemeModeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemeMode) ?? true; // default: dark
    return ThemeModeNotifier._internal(
      isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeMode, _mode == ThemeMode.dark);
  }
}
