import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/Constants/constants.dart';
import '../../../core/components/btn_widgets.dart';
import '../../../core/components/showSnackBar.dart';
import '../../../core/theme/app_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';

class CheckOtpOfPhoneUpdatedScreen extends StatefulWidget {
  final LayoutCubit layoutCubit;
  final String phoneNumber;

  const CheckOtpOfPhoneUpdatedScreen(
      {super.key, required this.layoutCubit, required this.phoneNumber});

  @override
  State<CheckOtpOfPhoneUpdatedScreen> createState() =>
      _CheckOtpOfPhoneUpdatedScreenState();
}

class _CheckOtpOfPhoneUpdatedScreenState
    extends State<CheckOtpOfPhoneUpdatedScreen> {
  final TextEditingController _pinCodeController = TextEditingController();

  @override
  void dispose() {
    _pinCodeController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Otp"),
      ),
      body: Padding(
        padding: AppConstants.kScaffoldPadding,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text("Verification Code",
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kBlack)),
            Text(
              "Please type the verification code sent to ${widget.phoneNumber}",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: AppColors.kLightGrey),
            ),
            24.vrSpace,
            PinCodeTextField(
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                inactiveFillColor: const Color(0xffF3F8FF),
                borderRadius: BorderRadius.circular(4),
                fieldHeight: 50,
                fieldWidth: 40,
                activeColor: AppColors.kMain,
                inactiveColor: Colors.grey.withOpacity(0.1),
                activeFillColor: Colors.transparent,
              ),
              animationDuration: const Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              controller: _pinCodeController,
              onCompleted: (v) {
                widget.layoutCubit.changeUserPhoneNumber(
                    phoneNumber: widget.phoneNumber,
                    pinCode: _pinCodeController.text.trim());
              },
              appContext: context,
            ),
            12.vrSpace,
            BlocConsumer<LayoutCubit, LayoutStates>(
              listener: (context, state) {
                if (state is ChangeUserPhoneNumberWithFailureState) {
                  showSnackBarWidget(
                      message: state.message,
                      successOrNot: false,
                      context: context);
                }
                if (state is ChangeUserPhoneNumberSuccessfullyState) {
                  showSnackBarWidget(
                      message:
                          "Your phone number is changed successfully, Sign in with the new one !",
                      successOrNot: true,
                      context: context);
                  widget.layoutCubit
                      .signOut(notToEmitToState: true, context: context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppStrings.kLoginScreenName, (_) => true);
                }
              },
              builder: (context, state) => BtnWidget(
                minWidth: double.infinity,
                onTap: () {
                  if (_pinCodeController.text.isEmpty) {
                    showSnackBarWidget(
                        message: "Please, Enter Otp code, try again !",
                        successOrNot: false,
                        context: context);
                  } else {
                    widget.layoutCubit.changeUserPhoneNumber(
                        phoneNumber: widget.phoneNumber,
                        pinCode: _pinCodeController.text.trim());
                  }
                },
                title: state is ChangeUserPhoneNumberLoadingState
                    ? "Change Phone Number loading"
                    : "Continue",
              ),
            ),
            16.vrSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive Otp code ?",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kDarkGrey),
                ),
                6.hrSpace,
                InkWell(
                  onTap: () {
                    widget.layoutCubit.verifyPhoneNum(
                        phoneNumber: widget.phoneNumber,
                        usedWithCurrentPhoneOrNewOne: false);
                  },
                  child: Text(
                    "Resent it",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kMain),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
