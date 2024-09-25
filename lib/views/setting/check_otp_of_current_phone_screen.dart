
import 'package:achiva/core/constants/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/Constants/constants.dart';
import '../../../core/components/btn_widgets.dart';
import '../../../core/components/showSnackBar.dart';
import '../../../core/theme/app_colors.dart';
import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';
import 'change_user_phone_number_screen.dart';

class CheckOtpOfCurrentPhoneScreen extends StatefulWidget {
  final LayoutCubit layoutCubit;
  final String phoneNumber;
  const CheckOtpOfCurrentPhoneScreen({super.key, required this.layoutCubit, required this.phoneNumber});

  @override
  State<CheckOtpOfCurrentPhoneScreen> createState() => _CheckOtpOfCurrentPhoneScreenState();
}

class _CheckOtpOfCurrentPhoneScreenState extends State<CheckOtpOfCurrentPhoneScreen> {
  final TextEditingController _pinCodeController = TextEditingController();

  @override
  void initState() {
    widget.layoutCubit.verifyPhoneNum(phoneNumber: widget.phoneNumber,usedWithCurrentPhoneOrNewOne: true);
    super.initState();
  }

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
          children:
          [
            Text("Verification Code",style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold,color: AppColors.kBlack)),
            Text("Please type the verification code sent to ${widget.phoneNumber}",style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600,height: 1.6,color: AppColors.kLightGrey),),
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
              onCompleted: (v)
              {
                widget.layoutCubit.checkOtpOfCurrentPhone(code: _pinCodeController.text.trim());
              },
              appContext: context,
            ),
            12.vrSpace,
            BlocConsumer<LayoutCubit,LayoutStates>(
              listenWhen: (past,currentState) => (currentState is PhoneNumVerifiedWithFailureState && currentState.usedWithCurrentPhoneOrNewOne) || (currentState is PhoneNumVerifiedSuccessfullyState && currentState.usedWithCurrentPhoneOrNewOne) || currentState is CheckOtpOfCurrentPhoneLoadingState || currentState is CheckOtpOfCurrentPhoneSuccessfullyState || currentState is CheckOtpOfCurrentPhoneWithFailureState,
              listener: (context,state)
              {
                if( state is CheckOtpOfCurrentPhoneWithFailureState )
                {
                  showSnackBarWidget(message: state.message, successOrNot: false, context: context);
                }
                if( state is CheckOtpOfCurrentPhoneSuccessfullyState )
                {
                  showSnackBarWidget(message: "Otp code confirmed successfully", successOrNot: true, context: context);
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> const ChangeUserPhoneScreen()));
                }
                if( state is PhoneNumVerifiedWithFailureState )
                {
                  showSnackBarWidget(message: "${state.message}, While sending Otp to your Phone.", successOrNot: false, context: context);
                }
              },
              builder: (context,state) => BtnWidget(
                minWidth: double.infinity,
                onTap: ()
                {
                  if( _pinCodeController.text.isEmpty )
                  {
                    showSnackBarWidget(message: "Please, Enter Otp code, try again !", successOrNot: false, context: context);
                  }
                  else
                  {
                    widget.layoutCubit.checkOtpOfCurrentPhone(code: _pinCodeController.text.trim());
                  }
                },
                title: state is CheckOtpOfCurrentPhoneLoadingState ? "Check Otp code loading" : "Continue",
              ),
            ),
            16.vrSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
              [
                Text("Didn't receive Otp code ?",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: AppColors.kDarkGrey),),
                6.hrSpace,
                InkWell(
                  onTap: ()  
                  {
                    widget.layoutCubit.verifyPhoneNum(phoneNumber: widget.phoneNumber,usedWithCurrentPhoneOrNewOne: true);
                  },
                  child: Text("Resent it",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: AppColors.kMain),),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

}

