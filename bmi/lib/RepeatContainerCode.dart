import 'package:flutter/material.dart';


// Reusable Container Widget Class with GestureDetector
class RepeatContainerCode extends StatelessWidget {
  const RepeatContainerCode({
    super.key,
    required this.colors,
    required this.cardWidget,
    this.onPress, // Function object for gesture detector
  });

  final Color colors;
  final Widget cardWidget;
  final Function()? onPress; // Function object (nullable)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress, // Use function object here
      child: Container(
        margin: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: colors,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: cardWidget,
      ),
    );
  }
}