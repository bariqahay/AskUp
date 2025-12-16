import 'package:flutter/material.dart';

class AccountButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final bool isLogout;
  final VoidCallback onTap;

  const AccountButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.iconColor,
    this.isLogout = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isLogout 
              ? (isDark ? Colors.red[900]!.withOpacity(0.2) : Colors.red[50]) 
              : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLogout 
                ? Colors.red.withOpacity(0.3) 
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Colors.red : textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isLogout ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
