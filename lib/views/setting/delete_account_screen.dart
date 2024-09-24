
import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/components/btn_widgets.dart';
import '../../../core/components/showSnackBar.dart';
import '../../../core/theme/app_colors.dart';
import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _pinCodeController = TextEditingController();

  @override
  void dispose() {
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LayoutCubit layoutCubit = LayoutCubit.getInstance(context)..sendOtpForPhoneForDeletingAccount();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete User account"),
      ),
      body: ListView(
        padding: AppConstants.kScaffoldPadding.copyWith(bottom: 24),
        children: [
          Text("Verification Code",style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold,color: AppColors.kBlack)),
          Text("Please type the verification code sent to ${layoutCubit.user!.phoneNumber}",style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600,height: 1.6,color: AppColors.kLightGrey),),
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
              layoutCubit.deleteAccount(pinCode: _pinCodeController.text.trim());
            },
            appContext: context,
          ),
          12.vrSpace,
          BlocConsumer<LayoutCubit,LayoutStates>(
            listenWhen: (past,current) => current is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState || current is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState || current is DeleteAccountWithFailureState || current is DeleteAccountSuccessfullyState || current is DeleteAccountLoadingState,
            listener: (context,state)
            {
              if( state is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState )
              {
                showSnackBarWidget(message: "Otp code sent to your Phone successfully !", successOrNot: true, context: context);
              }
              if( state is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState )
              {
                showSnackBarWidget(message: state.message, successOrNot: false, context: context);
              }
              if( state is DeleteAccountWithFailureState )
              {
                showSnackBarWidget(message: state.message, successOrNot: false, context: context);
              }
              if( state is DeleteAccountSuccessfullyState )
              {
                showSnackBarWidget(message: "Account Deleted Successfully", successOrNot: true, context: context);
                Navigator.pushNamedAndRemoveUntil(context, AppStrings.kLoginScreenName, (_)=> true);
              }
            },
            builder: (context,state) => BtnWidget(
              minWidth: double.infinity,
              onTap: ()
              {
                if( _pinCodeController.text.isNotEmpty )
                {
                  layoutCubit.deleteAccount(pinCode: _pinCodeController.text.trim());
                }
                else
                {
                  showSnackBarWidget(message: "Firstly, type your password to be able to delete account!", successOrNot: false, context: context);
                }
              },
              title: state is DeleteAccountLoadingState ? "Delete user account loading" : "Delete account",
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
                  layoutCubit.sendOtpForPhoneForDeletingAccount();
                },
                child: Text("Resent it",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: AppColors.kMain),),
              )
            ],
          )
        ],
      ),
    );
  }
}
