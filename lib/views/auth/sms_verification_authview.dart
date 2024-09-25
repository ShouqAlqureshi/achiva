// ignore_for_file: use_build_context_synchronously

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
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Image.asset(
          'lib/images/logo-with-name.png',
          fit: BoxFit.contain,
          height: 250,
        ),
        toolbarHeight: 150,
        backgroundColor: Colors.grey.shade900,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 53, 29, 94),
                    borderRadius: BorderRadius.circular(10)),
                width: 500,
                height: 500,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "We have sent an OTP to your phone.\nPlease check your SMS massages",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
                        fillColor: Colors.white.withOpacity(0.25),
                        filled: true,
                        hintText: "Enter OTP",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: (isCodeTouched || isFormSubmitted) &&
                                  (validation
                                          .validateCode(otpController.text)
                                          ?.isNotEmpty ??
                                      false)
                              ? const BorderSide(
                                  color: Color.fromARGB(255, 195, 24, 12))
                              : BorderSide.none,
                        ),
                        errorText: (isCodeTouched || isFormSubmitted)
                            ? validation.validateCode(otpController.text)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const Align(
                            alignment: Alignment
                                .center,
                            child: CircularProgressIndicator(),
                          )
                        : ElevatedButton(
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
                                      Navigator.pushNamed(context, "/newuser",
                                          arguments: datatosave);
                                    } else {
                                      Navigator.pushNamed(context, "/home");
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
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ))
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
