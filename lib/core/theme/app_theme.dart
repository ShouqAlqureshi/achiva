import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: AppColors.kScaffoldLightBackground,
    appBarTheme: AppBarTheme(
        backgroundColor: AppColors.kScaffoldLightBackground,
        foregroundColor: AppColors.kDarkPrimary,
        titleTextStyle: TextStyle(fontSize: 18,fontWeight: FontWeight.w700,color: AppColors.kDarkPrimary,fontFamily: "ElMessiri"),
        centerTitle: true,
        scrolledUnderElevation: 0
    ),
    buttonTheme: ButtonThemeData(
        buttonColor: AppColors.kMain
    ),
    fontFamily: "ElMessiri",
  );
}