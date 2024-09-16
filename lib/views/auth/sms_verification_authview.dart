// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:achiva/exceptions/auth_exceptions.dart';
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

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "We have sent an OTP to your phone. Plz verify",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  fillColor: Colors.grey.withOpacity(0.25),
                  filled: true,
                  hintText: "Enter OTP",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      try {
                        try {
                          final verificationId = ModalRoute.of(context)!
                              .settings
                              .arguments as String;
                          final cred = PhoneAuthProvider.credential(
                              verificationId: verificationId,
                              smsCode: otpController.text);
                          final usercred = await FirebaseAuth.instance
                              .signInWithCredential(cred);
                          bool isNewUser_ =
                              usercred.additionalUserInfo!.isNewUser;

                          if (isNewUser_) {
                            Navigator.pushNamed(context, "/newuser");
                          } else {
                            Navigator.pushNamed(context, "/home");
                          }
                        } on FirebaseAuthException catch (e) {
                          log(e.toString());
                          if (e.code == "invalid-verification-code") {
                            throw InvalidVerificationCodeException(
                                "\nPlease check and enter the correct verification code again.");
                          } else {
                            throw GenricException();
                          }
                        }
                      } on InvalidVerificationCodeException catch (e) {
                        showErrorDialog(context, e.toString());
                      } on GenricException catch (e) {
                        showErrorDialog(context, e.toString());
                      }
                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: const Text(
                      "Verify",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ))
          ],
        ),
      ),
    );
  }
}
