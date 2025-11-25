import 'package:flutter/material.dart';
import 'main.dart';
import 'package:bmi_app/RepeatContainerCode.dart';
import 'constantfile.dart';


// Icon Card Widget Class
class IconCard extends StatelessWidget {
  const IconCard({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: kIconSize,
          color: Colors.white,
        ),
        SizedBox(height: kSpaceBetweenIconAndLabel),
        Text(
          label,
          style: kLabelTextStyle,
        ),
      ],
    );
  }
}