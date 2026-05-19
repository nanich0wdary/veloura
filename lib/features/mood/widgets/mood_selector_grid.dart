import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood.dart';

class MoodSelectorGrid extends StatelessWidget {
  const MoodSelectorGrid({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  static const _moods = [
    ('😊', 'Happy', [Color(0xFFFBBF24), Color(0xFFF97316)]),
    ('😔', 'Sad', [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
    ('😴', 'Tired', [Color(0xFFAD7FF2), Color(0xFF7C3AED)]),
    ('😡', 'Angry', [Color(0xFFEF4444), Color(0xFFFCA5A5)]),
    ('😌', 'Calm', [Color(0xFF34D399), Color(0xFF10B981)]),
    ('😍', 'Loved', [Color(0xFFC084FC), Color(0xFFF472B6)]),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: _moods.map((mood) {
        final isSelected = selected == mood.$1;
        return GestureDetector(
          onTap: () => onSelect(mood.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: mood.$3)
                  : null,
              color: isSelected
                  ? null
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.$1, style: const TextStyle(fontSize: 32))
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 6),
                Text(
                  mood.$2,
                  style: GoogleFonts.cinzel(
                    fontSize: 10,
                    color: isSelected ? Colors.white : Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
