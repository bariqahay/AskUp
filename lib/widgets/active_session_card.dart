import 'package:flutter/material.dart';

class ActiveSessionCard extends StatelessWidget {
  final String title;
  final String code;
  final int currentStudents;
  final int totalStudents;
  final Color statusColor;
  final List<Color> progressColors;

  const ActiveSessionCard({
    Key? key,
    required this.title,
    required this.code,
    required this.currentStudents,
    required this.totalStudents,
    required this.statusColor,
    required this.progressColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalStudents == 0 ? 0 : currentStudents / totalStudents,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation(
                progressColors.isNotEmpty ? progressColors.first : Colors.blue,
              ),
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ),

          const SizedBox(height: 8),

          // Student count text
          Text(
            '$currentStudents of $totalStudents students',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
