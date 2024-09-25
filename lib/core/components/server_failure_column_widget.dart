import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ServerFailureColumnWidget extends StatelessWidget {
  const ServerFailureColumnWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
        [
          Icon(Icons.error,color: AppColors.kBlack.withOpacity(0.8),size: 28),
          16.vrSpace,
          Text("Server failure\ntry agin later",style: TextStyle(color: AppColors.kBlack.withOpacity(0.8),fontSize: 16,fontWeight: FontWeight.w500,height: 1.6),textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}
