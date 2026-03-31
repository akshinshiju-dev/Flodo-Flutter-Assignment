import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final filters = <TaskStatus?>[null, ...TaskStatus.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final status = filters[i];
          final isSelected = provider.filterStatus == status;
          final label = status?.label ?? 'All';

          Color chipColor;
          if (status == null) {
            chipColor = colors.primary;
          } else {
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
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => provider.setFilterStatus(status),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor
                      : chipColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? chipColor
                        : chipColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : chipColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
