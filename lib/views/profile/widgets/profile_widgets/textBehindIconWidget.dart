import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TextBehindIconWidget extends StatelessWidget {
  final String title;
  final IconData iconData;
  final String numValue;
  const TextBehindIconWidget({super.key, required this.title, required this.iconData, required this.numValue});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData,color: AppColors.kWhite,),
          12.hrSpace,
          Column(
            children: [
              Text(title,style: TextStyle(fontSize: 14,color: AppColors.kWhite,fontWeight: FontWeight.bold),),
              Text(numValue,style: TextStyle(fontSize: 16,color: AppColors.kWhite,fontWeight: FontWeight.bold),),
            ],
          )
        ],
      ),
    );
  }
}
