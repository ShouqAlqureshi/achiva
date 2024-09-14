import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtool show log;
import '../../utilities/show_error_dialog.dart';

class PhoneNumAuthView extends StatefulWidget {
  const PhoneNumAuthView({super.key});

  @override
  State<PhoneNumAuthView> createState() => _PhoneNumAuthViewState();
}

class _PhoneNumAuthViewState extends State<PhoneNumAuthView> {
  late final TextEditingController _phonenumber;
  // ignore: unused_field
  String _verificationId = '';
  @override
  void initState() {
    super.initState();
    _phonenumber = TextEditingController();
  }

  @override
  void dispose() {
    _phonenumber.dispose();
    super.dispose();
  }

  bool isloading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to achiva ",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _phonenumber,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                fillColor: Colors.grey.withOpacity(0.25),
                filled: true,
                hintText: "enter your Phone number here",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            isloading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isloading = true;
                      });
                      FirebaseAuth.instance.verifyPhoneNumber(
                        phoneNumber: _phonenumber.text,
                        verificationCompleted: (phoneAuthCredential) async {
                          await FirebaseAuth.instance
                              .signInWithCredential(phoneAuthCredential);
                        },
                        verificationFailed: (FirebaseAuthException error) {
                          devtool.log(error.toString());
                          if (error.code == 'invalid-phone-number') {
                            showErrorDialog(context,
                                'The provided phone number is not valid.');
                          }
                        },
                        codeSent: (verificationId, forceResendingToken) async {
                          setState(() {
                            isloading = false;
                          });
                          setState(() {
                            _verificationId = verificationId;
                          });
                          Navigator.pushNamed(
                            context,
                            '/otp',
                            arguments: verificationId,
                          );
                          setState(() {
                            _verificationId = verificationId;
                          });
                        },
                        timeout: const Duration(seconds: 60),
                        codeAutoRetrievalTimeout: (verificationId) {
                          devtool.log("auto retrireval timeout");
                          setState(() {
                            _verificationId = verificationId;
                          });
                        },
                      );
                    },
                    child: const Text("Continue"),
                  )
          ],
        ),
      ),
    );
  }
}
