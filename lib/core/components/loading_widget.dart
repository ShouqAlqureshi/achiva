import 'package:achiva/core/constants/extensions.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
        [
          Center(
            child: SizedBox(height:22,width:22,child: CircularProgressIndicator(strokeWidth: 2.4,color: AppColors.kDarkGrey,)),
          ),
          14.vrSpace,
          Text(message ?? "Loading content",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color:AppColors.kDarkPrimary),)
        ],
      ),
    );
  }
}
