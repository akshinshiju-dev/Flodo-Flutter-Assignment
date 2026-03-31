import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../../../shared/widgets/loading_button.dart';

/// Draft persistence keys
const _kDraftTitle = 'draft_title';
const _kDraftDescription = 'draft_description';
const _kDraftDueDate = 'draft_due_date';
const _kDraftStatus = 'draft_status';
const _kDraftBlockedById = 'draft_blocked_by_id';

class TaskFormScreen extends StatefulWidget {
  /// If [task] is non-null, we are in Edit mode.
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskStatus _status = TaskStatus.todo;
  int? _blockedById;
  bool _isSaving = false;
  bool _draftLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    if (widget.isEditing) {
      // Populate fields from existing task
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _dueDate = t.dueDate;
      _status = t.status;
      _blockedById = t.blockedById;
      _draftLoaded = true;
    } else {
      // Load draft for new task creation
      _loadDraft();
    }

    // Auto-save draft on every keystroke (new tasks only)
    if (!widget.isEditing) {
      _titleCtrl.addListener(_saveDraft);
      _descCtrl.addListener(_saveDraft);
    }
  }

  // ─── Draft ────────────────────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleCtrl.text = prefs.getString(_kDraftTitle) ?? '';
      _descCtrl.text = prefs.getString(_kDraftDescription) ?? '';
      final savedDate = prefs.getString(_kDraftDueDate);
      if (savedDate != null) {
        _dueDate = DateTime.tryParse(savedDate) ?? _dueDate;
      }
      final savedStatus = prefs.getString(_kDraftStatus);
      if (savedStatus != null) {
        _status = TaskStatus.fromString(savedStatus);
      }
      final savedBlockedById = prefs.getInt(_kDraftBlockedById);
      _blockedById = savedBlockedById;
      _draftLoaded = true;
    });
  }

  Future<void> _saveDraft() async {
    if (widget.isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftTitle, _titleCtrl.text);
    await prefs.setString(_kDraftDescription, _descCtrl.text);
    await prefs.setString(_kDraftDueDate, _dueDate.toIso8601String());
    await prefs.setString(_kDraftStatus, _status.name);
    if (_blockedById != null) {
      await prefs.setInt(_kDraftBlockedById, _blockedById!);
    } else {
      await prefs.remove(_kDraftBlockedById);
    }
  }

  Future<void> _clearDraft() async {
    if (widget.isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftTitle);
    await prefs.remove(_kDraftDescription);
    await prefs.remove(_kDraftDueDate);
    await prefs.remove(_kDraftStatus);
    await prefs.remove(_kDraftBlockedById);
  }

  // ─── Date Picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).extension<AppColors>()!.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
      _saveDraft();
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<TaskProvider>();

      if (widget.isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedById: _blockedById,
        );
        await provider.updateTask(updated);
      } else {
        final newTask = Task(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedById: _blockedById,
        );
        await provider.createTask(newTask);
        await _clearDraft();
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<TaskProvider>();

    // Tasks available for "Blocked By" — exclude self
    final blockableOptions = provider.allTasks
        .where((t) => t.id != widget.task?.id)
        .toList();

    // If the previously selected blocker no longer exists (e.g. it was deleted),
    // clear it via a post-frame callback instead of directly in build().
    // Direct mutation in build() causes DropdownButton assertion errors because
    // the widget tree is mid-construction when the value/items mismatch is detected.
    if (_blockedById != null &&
        !blockableOptions.any((t) => t.id == _blockedById)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _blockedById = null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_draftLoaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Title ──────────────────────────────────────────────
                  _SectionLabel('Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'What needs to be done?',
                    ),
                    style: GoogleFonts.inter(fontSize: 15),
                    maxLength: 120,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────
                  _SectionLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add details (optional)',
                    ),
                    style: GoogleFonts.inter(fontSize: 15),
                    maxLines: 3,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 20),

                  // ── Due Date ───────────────────────────────────────────
                  _SectionLabel('Due Date'),
                  const SizedBox(height: 8),
                  _DatePickerField(
                    date: _dueDate,
                    onTap: _pickDate,
                  ),

                  const SizedBox(height: 20),

                  // ── Status ─────────────────────────────────────────────
                  _SectionLabel('Status'),
                  const SizedBox(height: 8),
                  _StatusDropdown(
                    value: _status,
                    onChanged: (s) {
                      if (s != null) {
                        setState(() => _status = s);
                        _saveDraft();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Blocked By ─────────────────────────────────────────
                  _SectionLabel('Blocked By'),
                  const SizedBox(height: 4),
                  Text(
                    'This task cannot start until the selected task is Done.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colors.muted),
                  ),
                  const SizedBox(height: 8),
                  _BlockedByDropdown(
                    tasks: blockableOptions,
                    selectedId: _blockedById,
                    onChanged: (id) {
                      setState(() => _blockedById = id);
                      _saveDraft();
                    },
                  ),

                  const SizedBox(height: 36),

                  // ── Save Button ────────────────────────────────────────
                  LoadingButton(
                    label: widget.isEditing ? 'Update Task' : 'Create Task',
                    icon: widget.isEditing ? Icons.check : Icons.add,
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_saveDraft);
    _descCtrl.removeListener(_saveDraft);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}

// ─── Helper sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.muted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: colors.primary),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(date),
              style: GoogleFonts.inter(fontSize: 15),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final TaskStatus value;
  final ValueChanged<TaskStatus?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.card,
          style: GoogleFonts.inter(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface),
          onChanged: onChanged,
          items: TaskStatus.values.map((s) {
            Color dotColor;
            switch (s) {
              case TaskStatus.todo:
                dotColor = colors.info;
                break;
              case TaskStatus.inProgress:
                dotColor = colors.warning;
                break;
              case TaskStatus.done:
                dotColor = colors.success;
                break;
            }
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(s.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BlockedByDropdown extends StatelessWidget {
  final List<Task> tasks;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _BlockedByDropdown({
    required this.tasks,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: colors.card,
          style: GoogleFonts.inter(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface),
          hint: Text('None (not blocked)',
              style: GoogleFonts.inter(
                  fontSize: 15, color: colors.muted)),
          onChanged: onChanged,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Row(children: [
                Icon(Icons.remove_circle_outline,
                    size: 16, color: colors.muted),
                const SizedBox(width: 8),
                Text('None (not blocked)',
                    style: GoogleFonts.inter(
                        fontSize: 15, color: colors.muted)),
              ]),
            ),
            ...tasks.map(
              (t) => DropdownMenuItem<int?>(
                value: t.id,
                child: Row(children: [
                  Icon(Icons.link, size: 16, color: colors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
