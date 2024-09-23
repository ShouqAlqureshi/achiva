import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? textInputType;
  final TextInputAction? textInputAction;
  final IconData prefixIconData;
  final bool? secureTxt;
  const TextFieldWidget({super.key, required this.controller, required this.hint, this.textInputType, required this.prefixIconData, this.secureTxt, this.textInputAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enableSuggestions: false,
        autocorrect: false,
        obscureText: secureTxt ?? false,
        keyboardType: textInputType ?? TextInputType.text,
        textInputAction: textInputAction ?? TextInputAction.done,
        decoration: InputDecoration(
          fillColor: AppColors.kTextFieldBackground,
          filled: true,
          hintText: hint,
          prefixIcon: Icon(prefixIconData),
          border: OutlineInputBorder(
              borderRadius: AppConstants.kMainRadius,
              borderSide: BorderSide.none
          ),
        ),
      ),
    );
  }
}
