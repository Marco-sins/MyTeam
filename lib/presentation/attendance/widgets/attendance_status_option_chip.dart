import 'package:flutter/material.dart';

class AttendanceStatusOptionChip extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const AttendanceStatusOptionChip({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected ? selectedColor : Colors.grey.shade200,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
          child: IconTheme.merge(
            data: IconThemeData(size: 16, color: fg),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
