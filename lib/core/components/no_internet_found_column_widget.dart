import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class InternetLostColumnWidget extends StatelessWidget {
  final void Function() retryFunction;
  final String? message;
  const InternetLostColumnWidget({super.key, required this.retryFunction, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
        [
          InkWell(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Icon(Icons.refresh,color: AppColors.kBlack.withOpacity(0.8),size: 26),
            onTap: (){
              retryFunction();
            },
          ),
          16.vrSpace,
          Center(child: Text(message ?? "لا يوجد إتصال بالإنترنت",style: TextStyle(color: AppColors.kBlack.withOpacity(0.8),fontSize: 16,fontWeight: FontWeight.w500),textAlign: TextAlign.center,)),
        ],
      ),
    );
  }
}
