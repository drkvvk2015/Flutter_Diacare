import 'package:flutter/material.dart';

class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({
    required this.currentColor, required this.onColorSelected, super.key,
  });
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  static const List<Color> accentColors = [
    Color(0xFF43CEA2),
    Color(0xFF185A9D),
    Color(0xFFe57373),
    Color(0xFF64b5f6),
    Color(0xFFffd54f),
    Color(0xFF81c784),
    Color(0xFFba68c8),
    Color(0xFFff8a65),
    Color(0xFF90a4ae),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Accent Color'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: accentColors.map((color) {
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == currentColor ? Colors.black : Colors.white,
                    width: color == currentColor ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: color == currentColor
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
