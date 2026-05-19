import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood.dart';

class MoodSelectorGrid extends StatelessWidget {
  const MoodSelectorGrid({
    required this.selected,
    required this.onSelect,
  });

  final MoodType selected;
  final ValueChanged<MoodType> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: Mood.all.map((mood) {
        final isSelected = selected == mood.type;
        return GestureDetector(
          onTap: () => onSelect(mood.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: mood.colors)
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
                Text(mood.emoji, style: const TextStyle(fontSize: 32))
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 6),
                Text(
                  mood.label,
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
