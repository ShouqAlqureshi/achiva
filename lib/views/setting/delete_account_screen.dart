import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:achiva/core/Constants/constants.dart';
// import 'package:achiva/core/constants/extensions.dart';
// import 'package:achiva/core/constants/strings.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import '../../../core/components/btn_widgets.dart';
// import '../../../core/components/showSnackBar.dart';
// import '../../../core/theme/app_colors.dart';
// import '../profile/layout_controller/layout_cubit.dart';
// import '../profile/layout_controller/layout_states.dart';

// class DeleteAccountScreen extends StatefulWidget {
//   const DeleteAccountScreen({super.key});

//   @override
//   State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
// }

// class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
//   final TextEditingController _pinCodeController = TextEditingController();

//   @override
//   void dispose() {
//     _pinCodeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final LayoutCubit layoutCubit = LayoutCubit.getInstance(context)
//       ..sendOtpForPhoneForDeletingAccount();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Delete User account"),
//       ),
//       body: ListView(
//         padding: AppConstants.kScaffoldPadding.copyWith(bottom: 24),
//         children: [
//           Text("Verification Code",
//               style: TextStyle(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.kBlack)),
//           Text(
//             "Please type the verification code sent to ${layoutCubit.user!.phoneNumber}",
//             style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w600,
//                 height: 1.6,
//                 color: AppColors.kLightGrey),
//           ),
//           24.vrSpace,
//           PinCodeTextField(
//             length: 6,
//             obscureText: false,
//             animationType: AnimationType.fade,
//             pinTheme: PinTheme(
//               shape: PinCodeFieldShape.box,
//               inactiveFillColor: const Color(0xffF3F8FF),
//               borderRadius: BorderRadius.circular(4),
//               fieldHeight: 50,
//               fieldWidth: 40,
//               activeColor: AppColors.kMain,
//               inactiveColor: Colors.grey.withOpacity(0.1),
//               activeFillColor: Colors.transparent,
//             ),
//             animationDuration: const Duration(milliseconds: 300),
//             backgroundColor: Colors.transparent,
//             enableActiveFill: true,
//             controller: _pinCodeController,
//             onCompleted: (v) {
//               layoutCubit.deleteAccount(
//                   pinCode: _pinCodeController.text.trim());
//             },
//             appContext: context,
//           ),
//           12.vrSpace,
//           BlocConsumer<LayoutCubit, LayoutStates>(
//             listenWhen: (past, current) =>
//                 current is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState ||
//                 current
//                     is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState ||
//                 current is DeleteAccountWithFailureState ||
//                 current is DeleteAccountSuccessfullyState ||
//                 current is DeleteAccountLoadingState,
//             listener: (context, state) {
//               if (state
//                   is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState) {
//                 showSnackBarWidget(
//                     message: "Otp code sent to your Phone successfully !",
//                     successOrNot: true,
//                     context: context);
//               }
//               if (state
//                   is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState) {
//                 showSnackBarWidget(
//                     message: state.message,
//                     successOrNot: false,
//                     context: context);
//               }
//               if (state is DeleteAccountWithFailureState) {
//                 showSnackBarWidget(
//                     message: state.message,
//                     successOrNot: false,
//                     context: context);
//               }
//               if (state is DeleteAccountSuccessfullyState) {
//                 showSnackBarWidget(
//                     message: "Your account was deleted successfully",
//                     successOrNot: true,
//                     context: context);
//                 Navigator.pushNamedAndRemoveUntil(
//                     context, AppStrings.kLoginScreenName, (_) => true);
//               }
//             },
//             builder: (context, state) => BtnWidget(
//               minWidth: double.infinity,
//               onTap: () {
//                 if (_pinCodeController.text.isNotEmpty) {
//                   layoutCubit.deleteAccount(
//                       pinCode: _pinCodeController.text.trim());
//                 } else {
//                   showSnackBarWidget(
//                       message:
//                           "Firstly, type your password to be able to delete account!",
//                       successOrNot: false,
//                       context: context);
//                 }
//               },
//               title: state is DeleteAccountLoadingState
//                   ? "Delete user account loading"
//                   : "Delete account",
//             ),
//           ),
//           16.vrSpace,
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Didn't receive Otp code ?",
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.kDarkGrey),
//               ),
//               6.hrSpace,
//               InkWell(
//                 onTap: () {
//                   layoutCubit.sendOtpForPhoneForDeletingAccount();
//                 },
//                 child: Text(
//                   "Resent it",
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.kMain),
//                 ),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;
  Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData =
          FirebaseAuth.instance.currentUser?.providerData.first;

      if (AppleAuthProvider().providerId == providerData!.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(AppleAuthProvider());
      } else if (GoogleAuthProvider().providerId == providerData.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(GoogleAuthProvider());
      }

      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      log("$e");
    }
  }

  // Method to delete user from Firestore and FirebaseAuth
  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current logged-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // Get user's phone number (or use user.uid if using UIDs as document IDs)
      String? userUid = user.uid;

      //delete subcollection goals and goals[tasks]
      Future<QuerySnapshot> goals = FirebaseFirestore.instance
          .collection('Users')
          .doc(userUid)
          .collection("goals")
          .get();
      goals.then((value) async {
        for (var goalsDoc in value.docs) {
          DocumentReference goalsDocRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userUid)
              .collection("goals")
              .doc(goalsDoc.id);
          Future<QuerySnapshot> tasks = FirebaseFirestore.instance
              .collection('Users')
              .doc(userUid)
              .collection("goals")
              .doc(goalsDoc.id)
              .collection("tasks")
              .get();
          tasks.then(
            (value) async {
              for (var tasksDoc in value.docs) {
                DocumentReference tasksDocRef = FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userUid)
                    .collection("goals")
                    .doc(goalsDoc.id)
                    .collection("tasks")
                    .doc(tasksDoc.id);
                await tasksDocRef.delete();
              }
            },
          );
          await goalsDocRef.delete();
        }
      });
      // Delete the user document from Firestore
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userUid); // Use user.uid if using UIDs

      await userDocRef.delete();

      // Delete the user from FirebaseAuth
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        log("$e");

        if (e.code == "requires-recent-login") {
          await _reauthenticateAndDelete();
        }
      }

      // Show success message and navigate to the login screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully.')),
        );
      }

      // Navigate to the login screen (or any other screen you prefer)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/phoneauth');
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Account"),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator while deleting account
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Are you sure you want to delete your account?",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red, // Set button color to red for warning
                    ),
                    onPressed: _deleteAccount,
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
// import 'package:achiva/core/Constants/constants.dart';
// import 'package:achiva/core/constants/extensions.dart';
// import 'package:achiva/core/constants/strings.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import '../../../core/components/btn_widgets.dart';
// import '../../../core/components/showSnackBar.dart';
// import '../../../core/theme/app_colors.dart';
// import '../profile/layout_controller/layout_cubit.dart';
// import '../profile/layout_controller/layout_states.dart';

// class DeleteAccountScreen extends StatefulWidget {
//   const DeleteAccountScreen({super.key});

//   @override
//   State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
// }

// class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
//   final TextEditingController _pinCodeController = TextEditingController();

//   @override
//   void dispose() {
//     _pinCodeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final LayoutCubit layoutCubit = LayoutCubit.getInstance(context)
//       ..sendOtpForPhoneForDeletingAccount();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Delete User account"),
//       ),
//       body: ListView(
//         padding: AppConstants.kScaffoldPadding.copyWith(bottom: 24),
//         children: [
//           Text("Verification Code",
//               style: TextStyle(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.kBlack)),
//           Text(
//             "Please type the verification code sent to ${layoutCubit.user!.phoneNumber}",
//             style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w600,
//                 height: 1.6,
//                 color: AppColors.kLightGrey),
//           ),
//           24.vrSpace,
//           PinCodeTextField(
//             length: 6,
//             obscureText: false,
//             animationType: AnimationType.fade,
//             pinTheme: PinTheme(
//               shape: PinCodeFieldShape.box,
//               inactiveFillColor: const Color(0xffF3F8FF),
//               borderRadius: BorderRadius.circular(4),
//               fieldHeight: 50,
//               fieldWidth: 40,
//               activeColor: AppColors.kMain,
//               inactiveColor: Colors.grey.withOpacity(0.1),
//               activeFillColor: Colors.transparent,
//             ),
//             animationDuration: const Duration(milliseconds: 300),
//             backgroundColor: Colors.transparent,
//             enableActiveFill: true,
//             controller: _pinCodeController,
//             onCompleted: (v) {
//               layoutCubit.deleteAccount(
//                   pinCode: _pinCodeController.text.trim());
//             },
//             appContext: context,
//           ),
//           12.vrSpace,
//           BlocConsumer<LayoutCubit, LayoutStates>(
//             listenWhen: (past, current) =>
//                 current is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState ||
//                 current
//                     is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState ||
//                 current is DeleteAccountWithFailureState ||
//                 current is DeleteAccountSuccessfullyState ||
//                 current is DeleteAccountLoadingState,
//             listener: (context, state) {
//               if (state
//                   is OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState) {
//                 showSnackBarWidget(
//                     message: "Otp code sent to your Phone successfully !",
//                     successOrNot: true,
//                     context: context);
//               }
//               if (state
//                   is OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState) {
//                 showSnackBarWidget(
//                     message: state.message,
//                     successOrNot: false,
//                     context: context);
//               }
//               if (state is DeleteAccountWithFailureState) {
//                 showSnackBarWidget(
//                     message: state.message,
//                     successOrNot: false,
//                     context: context);
//               }
//               if (state is DeleteAccountSuccessfullyState) {
//                 showSnackBarWidget(
//                     message: "Your account was deleted successfully",
//                     successOrNot: true,
//                     context: context);
//                 Navigator.pushNamedAndRemoveUntil(
//                     context, AppStrings.kLoginScreenName, (_) => true);
//               }
//             },
//             builder: (context, state) => BtnWidget(
//               minWidth: double.infinity,
//               onTap: () {
//                 if (_pinCodeController.text.isNotEmpty) {
//                   layoutCubit.deleteAccount(
//                       pinCode: _pinCodeController.text.trim());
//                 } else {
//                   showSnackBarWidget(
//                       message:
//                           "Firstly, type your password to be able to delete account!",
//                       successOrNot: false,
//                       context: context);
//                 }
//               },
//               title: state is DeleteAccountLoadingState
//                   ? "Delete user account loading"
//                   : "Delete account",
//             ),
//           ),
//           16.vrSpace,
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Didn't receive Otp code ?",
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.kDarkGrey),
//               ),
//               6.hrSpace,
//               InkWell(
//                 onTap: () {
//                   layoutCubit.sendOtpForPhoneForDeletingAccount();
//                 },
//                 child: Text(
//                   "Resent it",
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.kMain),
//                 ),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }