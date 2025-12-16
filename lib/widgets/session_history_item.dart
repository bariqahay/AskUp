import 'package:flutter/material.dart';

class SessionHistoryItem extends StatelessWidget {
  final String title;
  final String time;
  final String students;
  final bool hasSummary;
  final String? summaryPreview;

  const SessionHistoryItem({
    super.key,
    required this.title,
    required this.time,
    required this.students,
    this.hasSummary = false,
    this.summaryPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600]; // ⬅️ adaptive color
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (hasSummary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ Summary',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: subtitleColor), // ⬅️ adaptive
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: subtitleColor), // ⬅️ adaptive
              ),
              const SizedBox(width: 16),
              Icon(Icons.people_outline, size: 14, color: subtitleColor), // ⬅️ adaptive
              const SizedBox(width: 4),
              Text(
                students,
                style: TextStyle(fontSize: 12, color: subtitleColor), // ⬅️ adaptive
              ),
            ],
          ),
          if (hasSummary && summaryPreview != null && summaryPreview!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                summaryPreview!.length > 80 
                    ? '${summaryPreview!.substring(0, 80)}...'
                    : summaryPreview!,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor, // ⬅️ adaptive
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}