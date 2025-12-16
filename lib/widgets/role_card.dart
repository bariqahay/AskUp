import 'package:flutter/material.dart';

class RoleCard extends StatelessWidget {
  final Widget iconPlaceholder;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const RoleCard({
    Key? key,
    required this.iconPlaceholder,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            iconPlaceholder,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
