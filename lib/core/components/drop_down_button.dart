import 'package:flutter/material.dart';
import '../Constants/constants.dart';
import '../theme/app_colors.dart';

// ignore: must_be_immutable
class DropDownBtnWidget extends StatelessWidget {
  final String hint;
  late String? value;
  final Function(String val) onChanged;
  final List<String> items;
  DropDownBtnWidget({super.key, required this.hint,this.value, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColors.kTextFieldBackground,
          borderRadius: AppConstants.kMainRadius,
      ),
      child: DropdownButtonHideUnderline(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: DropdownButton(
              alignment: Alignment.centerLeft,
              hint: Text(hint,style: TextStyle(fontSize: 16,color: AppColors.kDarkGrey,fontWeight: FontWeight.w400),),
              style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,color: AppColors.kBlack.withOpacity(0.8)),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Align(alignment:AlignmentDirectional.centerStart,child: Text(item,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,color: AppColors.kBlack.withOpacity(0.8)),)),
              )
              ).toList(),
              onChanged: (value)
              {
                onChanged(value!);
              },
              value: value,
            ),
          )
      ),
    );
  }
}
