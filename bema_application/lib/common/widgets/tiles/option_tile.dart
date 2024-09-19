import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String gender;
  final String? selectedGender;
  final double emojiSize;
  final VoidCallback onSelect; // Callback function for selecting a gender

  const OptionTile({
    Key? key,
    required this.emoji,
    required this.label,
    required this.gender,
    required this.selectedGender,
    required this.emojiSize,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: onSelect, // Calls the function to update the selected gender
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black, // Black border color
                width: isSelected ? 4 : 2, // Thicker border if selected
              ),
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            child: Opacity(
              opacity: isSelected || selectedGender == null ? 1.0 : 0.3, // Blur unselected
              child: Text(
                emoji,
                style: TextStyle(fontSize: emojiSize), // Responsive emoji size
              ),
            ),
          ),
          const SizedBox(height: 10), // Fixed spacing between emoji and label
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
