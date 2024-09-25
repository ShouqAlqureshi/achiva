
import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/components/textField_widget.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/btn_widgets.dart';
import '../../../core/components/showSnackBar.dart';
import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';
import 'check_otp_of_phoneUpdated_screen.dart';

class ChangeUserPhoneScreen extends StatefulWidget {
  const ChangeUserPhoneScreen({super.key});

  @override
  State<ChangeUserPhoneScreen> createState() => _ChangeUserPhoneScreenState();
}

class _ChangeUserPhoneScreenState extends State<ChangeUserPhoneScreen> {
  final TextEditingController _phoneNumController = TextEditingController();

  @override
  void dispose() {
    _phoneNumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LayoutCubit layoutCubit = LayoutCubit.getInstance(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change User Phone"),
      ),
      body: ListView(
        padding: AppConstants.kScaffoldPadding.copyWith(bottom: 24),
        children: [
          TextFieldWidget(controller: _phoneNumController, hint: "Type your new Phone Number", prefixIconData: Icons.phone,textInputType: TextInputType.number),
          12.vrSpace,
          BlocConsumer<LayoutCubit,LayoutStates>(
            listenWhen: (past,current) => (current is PhoneNumVerifiedWithFailureState && current.usedWithCurrentPhoneOrNewOne == false) || (current is PhoneNumVerifiedSuccessfullyState && current.usedWithCurrentPhoneOrNewOne == false) || (current is PhoneNumVerifiedLoadingState && current.usedWithCurrentPhoneOrNewOne == false),
            listener: (context,state)
            {
              if( state is PhoneNumVerifiedWithFailureState && state.usedWithCurrentPhoneOrNewOne == false )
              {
                showSnackBarWidget(message: state.message, successOrNot: false, context: context);
              }
              if( state is PhoneNumVerifiedSuccessfullyState && state.usedWithCurrentPhoneOrNewOne == false )
              {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> CheckOtpOfPhoneUpdatedScreen(layoutCubit: layoutCubit, phoneNumber: _phoneNumController.text.trim())));
              }
            },
            builder: (context,state) => BtnWidget(
              minWidth: double.infinity,
              onTap: ()
              {
                if( _phoneNumController.text.isNotEmpty )
                {
                  layoutCubit.verifyPhoneNum(phoneNumber: _phoneNumController.text.trim(),usedWithCurrentPhoneOrNewOne: false);
                }
                else
                {
                  showSnackBarWidget(message: "Please, Enter Phone Number and try again !", successOrNot: false, context: context);
                }
              },
              title: state is PhoneNumVerifiedLoadingState ? "Change Phone Number loading" : "Change",
            ),
          ),
        ],
      ),
    );
  }
}
