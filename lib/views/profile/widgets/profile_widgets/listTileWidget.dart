import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ListTileWidget extends StatelessWidget {
  final String title;
  final Function() onTap;
  final IconData leadingIconData;
  const ListTileWidget({super.key, required this.title, required this.onTap, required this.leadingIconData});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: ()=> onTap(),
      child: Container(
        padding: AppConstants.kContainerPadding,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.kWhite,
            borderRadius: AppConstants.kMainRadius
        ),
        child: Row(
          children: [
            Icon(leadingIconData),
            12.hrSpace,
            Text(title,style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
            const Spacer(),
            const Icon(Icons.navigate_next)
          ],
        ),
      ),
    );
  }
}
