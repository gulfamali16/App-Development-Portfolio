import 'package:flutter/material.dart';


class RepeatContainerCode extends StatelessWidget {
  const RepeatContainerCode({
    super.key,
    required this.colors,
    required this.cardWidget,
  });

  final Color colors;
  final Widget cardWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: colors,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: cardWidget,
    );
  }
}