import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../theme/app_colors.dart';

void showAwesomeDialogWidget({String? okBtnText,String? cancelBtnText,String? title,required String desc,required BuildContext context,required DialogType type,bool? showOnlyOkBtn,Function()? okBtnMethod}){
  AwesomeDialog(
    context: context,
    dialogType: type,
    animType: AnimType.bottomSlide,
    title: title,
    desc: desc,
    dialogBackgroundColor: AppColors.kLightPrimary,
    buttonsBorderRadius: BorderRadius.circular(6),
    dialogBorderRadius: BorderRadius.circular(6),
    transitionAnimationDuration: const Duration(milliseconds: 400),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    btnOkText: okBtnText ?? "Continue",
    btnOkColor: AppColors.kGreenColor,
    reverseBtnOrder: true,
    titleTextStyle: TextStyle(fontSize: 16,fontWeight: FontWeight.w700,color: AppColors.kDarkPrimary),
    descTextStyle: TextStyle(fontSize: title != null ? 14 : 16,height: 1.6,fontWeight: title != null ? FontWeight.w500 : FontWeight.w600,color: title != null ? AppColors.kBlack.withOpacity(0.8) : AppColors.kDarkPrimary),
    btnCancelText: showOnlyOkBtn == null ? cancelBtnText ?? "Cancel" : null,
    btnCancelOnPress: showOnlyOkBtn == null ? () => Navigator.canPop(context) : null,
    btnOkOnPress: ()
    {
      okBtnMethod != null ? okBtnMethod() : Navigator.canPop(context);
    },
  ).show();
}


void showImageSourceDialog({required BuildContext context,required Function() pickCameraImage,required Function() pickGalleryImage}) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Image source '),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            pickCameraImage();
          },
          child: const Text('Camera',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            pickGalleryImage();
          },
          child: const Text('Gallery',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
        ),
      ],
    ),
  );
}


// TODO: Need to hanlde login screen