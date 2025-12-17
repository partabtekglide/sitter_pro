import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(String, bool) onTaskToggle;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final completedTasks =
        tasks.where((task) => task['status'] == 'completed').length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with progress
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: const Color(0xFF1976D2),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Tasks',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$completedTasks of $totalTasks completed',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1976D2),
                  ),
                  strokeWidth: 4.w,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Progress Bar
            Container(
              height: 8.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1976D2),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Task List
            ...tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return _buildTaskItem(task, index == tasks.length - 1);
            }),

            if (progress == 1.0) ...[
              SizedBox(height: 16.h),

              // Completion Message
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Tasks Completed!',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Great job! You\'ve completed all required tasks for this service.',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, bool isLast) {
    final isCompleted = task['status'] == 'completed';
    final isRequired = task['is_required'] == true;
    final taskName = task['task_name'] ?? '';
    final taskDescription = task['task_description'] ?? '';
    final taskId = task['id'] ?? '';

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? const Color(0xFF4CAF50).withAlpha(13)
                    : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border:
                isRequired
                    ? Border.all(
                      color:
                          isCompleted
                              ? const Color(0xFF4CAF50).withAlpha(77)
                              : const Color(0xFFFF9800).withAlpha(77),
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => onTaskToggle(taskId, !isCompleted),
                child: Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color:
                        isCompleted
                            ? const Color(0xFF4CAF50)
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          isCompleted
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                          : null,
                ),
              ),

              SizedBox(width: 12.w),

              // Task Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            taskName,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isCompleted
                                      ? Colors.grey[600]
                                      : Colors.grey[800],
                              decoration:
                                  isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'REQUIRED',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (taskDescription.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        taskDescription,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color:
                              isCompleted ? Colors.grey[500] : Colors.grey[600],
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],

                    if (isCompleted && task['completed_at'] != null) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12.sp,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Completed ${_formatCompletionTime(task['completed_at'])}',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action Button
              if (!isCompleted)
                IconButton(
                  onPressed:
                      () => _showTaskDetails(taskId, taskName, taskDescription),
                  icon: Icon(
                    Icons.info_outline,
                    color: Colors.grey[400],
                    size: 20.sp,
                  ),
                ),
            ],
          ),
        ),

        if (!isLast) SizedBox(height: 12.h),
      ],
    );
  }

  void _showTaskDetails(
    String taskId,
    String taskName,
    String taskDescription,
  ) {
    // Could show a bottom sheet with more task details, photo upload, etc.
    print('Show details for task: $taskName');
  }

  String _formatCompletionTime(String? completedAt) {
    if (completedAt == null) return '';

    final time = DateTime.tryParse(completedAt);
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}