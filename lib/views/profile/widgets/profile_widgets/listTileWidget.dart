import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:flutter/material.dart';

class ListTileWidget extends StatelessWidget {
  final String title;
  final Function() onTap;
  final IconData leadingIconData;
  final Color backgroundColor; // Added background color parameter
  final Color iconColor; // Added icon color parameter
  final Color textColor; // Added text color parameter

  const ListTileWidget({
    super.key,
    required this.title,
    required this.onTap,
    required this.leadingIconData,
    required this.backgroundColor, // Constructor parameter
    required this.iconColor, // Constructor parameter
    required this.textColor, // Constructor parameter
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: AppConstants.kContainerPadding,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor, // Use the passed background color
          borderRadius: AppConstants.kMainRadius,
        ),
        child: Row(
          children: [
            Icon(
              leadingIconData,
              color: iconColor, // Use the passed icon color
            ),
            12.hrSpace,
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor, // Use the passed text color
              ),
            ),
            const Spacer(),
            const Icon(Icons.navigate_next)
          ],
        ),
      ),
    );
  }
}
