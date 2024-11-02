import 'dart:developer';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/views/auth/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utilities/show_error_dialog.dart';

class VerfyCodeView extends StatefulWidget {
  const VerfyCodeView({super.key});

  @override
  State<VerfyCodeView> createState() => _VerfyCodeViewState();
}

class _VerfyCodeViewState extends State<VerfyCodeView> {
  final otpController = TextEditingController();
  Validators validation = Validators();
  bool isLoading = false;
  bool isFormSubmitted = false;
  bool isCodeTouched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Image.asset(
                      'lib/images/logo-with-name.png',
                      fit: BoxFit.contain,
                      height: 250, // Increased logo size
                    ),
                    const SizedBox(height: 60), // Increased space between logo and card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      width: 500,
                      padding: const EdgeInsets.all(30), // Increased padding to make card taller
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "We have sent an OTP to your phone.\nPlease check your SMS messages",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          const SizedBox(height: 40),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                isCodeTouched = true;
                              });
                            },
                            controller: otpController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              fillColor: Colors.black.withOpacity(0.1),
                              filled: true,
                              hintText: "Enter OTP",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: (isCodeTouched || isFormSubmitted) &&
                                        (validation
                                                .validateCode(otpController.text)
                                                ?.isNotEmpty ??
                                            false)
                                    ? const BorderSide(color: Colors.red)
                                    : BorderSide.none,
                              ),
                              errorText: (isCodeTouched || isFormSubmitted)
                                  ? validation.validateCode(otpController.text)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 30), // Increased space before button
                          isLoading
                              ? const Align(
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                      Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    onPressed: () async {
                              setState(() {
                                isLoading = true;
                                isFormSubmitted = true;
                              });
                              if (validation
                                      .validateCode(otpController.text)
                                      ?.isEmpty ??
                                  true) {
                                try {
                                  try {
                                    final verificationId =
                                        ModalRoute.of(context)!
                                            .settings
                                            .arguments as String;
                                    final cred = PhoneAuthProvider.credential(
                                        verificationId: verificationId,
                                        smsCode: otpController.text);
                                    final usercred = await FirebaseAuth.instance
                                        .signInWithCredential(cred);
                                    bool isNewUser_ =
                                        usercred.additionalUserInfo!.isNewUser;
                                    final userphonenumber =
                                        usercred.user?.phoneNumber;
                                    final datatosave = <String, dynamic>{
                                      "phoneNumber": userphonenumber
                                    };
                                    if (isNewUser_) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        "/newuser",
                                        (Route<dynamic> route) =>
                                            false, // This will remove all previous routes
                                        arguments: datatosave,
                                      );
                                    } else {
                                      Navigator.pushNamedAndRemoveUntil(
                                          context, "/home", (route) => false);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    log(e.toString());
                                    if (e.code == "invalid-verification-code") {
                                      throw InvalidVerificationCodeException(
                                          "Please check and enter the correct verification code again.");
                                    } else {
                                      throw GenricException();
                                    }
                                  }
                                } on InvalidVerificationCodeException catch (e) {
                                  showErrorDialog(context, e.message);
                                } on GenricException catch (e) {
                                  showErrorDialog(context, e.toString());
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please fill Code field correctly'),
                                  ),
                                );
                              }

                              setState(() {
                                isLoading = false;
                              });
                            },
                            child: const Text(
                              "Verify",
                              style: TextStyle(color: Colors.white, // Set text color to white
          fontSize: 16,
          fontWeight: FontWeight.bold,),
                            ))
                                  ),
                                
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
