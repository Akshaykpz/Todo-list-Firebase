import 'package:flutter/material.dart';

import '../../domain/entities/todo.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.todo,
    required this.color,
    required this.setupLocked,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Todo todo;
  final Color color;
  final bool setupLocked;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final local = todo.createdAt.toLocal();
    final titleSize = MediaQuery.sizeOf(context).width < 380 ? 15.0 : 16.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: setupLocked ? null : onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isCompleted ? Colors.black87 : Colors.white70,
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: todo.isCompleted ? Colors.white : Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(local),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(isCompleted: todo.isCompleted),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: setupLocked ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit task',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: setupLocked ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete task',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFDAF0DF)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isCompleted ? 'Done' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCompleted ? const Color(0xFF2E8B57) : Colors.black54,
        ),
      ),
    );
  }
}
