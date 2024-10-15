import 'dart:io';
import 'package:achiva/core/constants/extensions.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class AppConstants{
  static String? kUserID;
  static Map<String, Widget Function(BuildContext)> kRoutes = {

  };

  static void kShowImageSourceDialog({required BuildContext context,required Function() pickCameraImage,required Function() pickGalleryImage}) async {

  }

  static Future<File?> kPickedImage({required ImageSource imageSource}) async {
    final XFile? pickedImage = await ImagePicker().pickImage(source: imageSource);
    return pickedImage != null ? File(pickedImage.path) : null;
  }

  static Widget Function(BuildContext, int) kSeparatorBuilder() => (context,index) => 12.vrSpace;
  static BorderRadius kMainRadius = BorderRadius.circular(12);
  static BorderRadius kMaxRadius = BorderRadius.circular(24);
  static EdgeInsets kContainerPadding = const EdgeInsets.all(16);
  static EdgeInsets kScaffoldPadding = const EdgeInsets.symmetric(horizontal: 16);
  static EdgeInsets kListViewPadding = const EdgeInsets.only(bottom: 24);
  static BoxBorder kMainBorder = Border.all(color: const Color(0xffF1F5F7));
}