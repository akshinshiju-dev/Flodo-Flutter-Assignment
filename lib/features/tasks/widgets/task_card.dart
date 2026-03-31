import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<TaskProvider>();
    final blocked = provider.isBlocked(task);
    final blocker = provider.blockerOf(task);
    final isDone = task.status == TaskStatus.done;
    final dateStr = DateFormat('MMM d, yyyy').format(task.dueDate);
    final isOverdue =
        task.dueDate.isBefore(DateTime.now()) && !isDone;

    return AnimatedOpacity(
      opacity: blocked ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + status chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: HighlightedText(
                            text: task.title,
                            highlight: searchQuery,
                            maxLines: 2,
                            baseStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? colors.muted
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            highlightColor: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: task.status),
                      ],
                    ),

                    // Description
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Footer: due date + actions
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: isOverdue ? colors.danger : colors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isOverdue ? colors.danger : colors.muted,
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Overdue',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Delete button
                        _ActionButton(
                          icon: Icons.delete_outline,
                          color: colors.danger,
                          onTap: onDelete,
                          tooltip: 'Delete task',
                        ),
                      ],
                    ),

                    // Blocked by label
                    if (blocker != null && blocked) ...[
                      const SizedBox(height: 8),
                      _BlockedByBanner(blockerTitle: blocker.title),
                    ],
                  ],
                ),
              ),

              // Blocked overlay stripe (top-left corner tag)
              if (blocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _LockedBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    Color chipColor;
    switch (status) {
      case TaskStatus.todo:
        chipColor = colors.info;
        break;
      case TaskStatus.inProgress:
        chipColor = colors.warning;
        break;
      case TaskStatus.done:
        chipColor = colors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

// ─── Action Button ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─── Blocked By Banner ───────────────────────────────────────────────────────

class _BlockedByBanner extends StatelessWidget {
  final String blockerTitle;
  const _BlockedByBanner({required this.blockerTitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 13, color: colors.danger),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Blocked by: $blockerTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Locked Badge ─────────────────────────────────────────────────────────────

class _LockedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.danger,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'BLOCKED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
