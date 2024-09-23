import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/views/auth/validators.dart';
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

  Validators validation = Validators();
  bool isFormSubmitted = false;
  bool isPhonenumTouched = false;
  bool isloading = false;
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
          // backgroundColor: null,
          centerTitle: true,
          backgroundColor: Colors.grey.shade900),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            decoration: BoxDecoration(
                color: (Colors.deepPurple),
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Welcome to achiva ",
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 240, 238, 249)),
                ),
                const SizedBox(height: 30),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      isPhonenumTouched = true;
                    });
                  },
                  autofocus: true,
                  controller: _phonenumber,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    fillColor: Colors.white.withOpacity(0.25),
                    filled: true,
                    hintText: "enter your Phone number here",
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: (isPhonenumTouched || isFormSubmitted) &&
                              (validation
                                      .validatePhoneNum(_phonenumber.text)
                                      ?.isNotEmpty ??
                                  false)
                          ? const BorderSide(
                              color: Color.fromARGB(255, 195, 24, 12))
                          : BorderSide.none,
                    ),
                    errorText: (isPhonenumTouched || isFormSubmitted)
                        ? validation.validatePhoneNum(_phonenumber.text)
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                isloading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isloading = true;
                            isFormSubmitted = true;
                          });
                          if (validation.validatePhoneNum(_phonenumber.text)?.isEmpty ?? true) {
                            try {
                              FirebaseAuth.instance.verifyPhoneNumber(
                                phoneNumber: _phonenumber.text,
                                verificationCompleted:
                                    (phoneAuthCredential) async {
                                  await FirebaseAuth.instance
                                      .signInWithCredential(
                                          phoneAuthCredential);
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    throw UserNotLoggedInAuthException();
                                  }
                                },
                                verificationFailed:
                                    (FirebaseAuthException error) async {
                                  await showErrorDialog(
                                    context,
                                    'Check your Phone number formate:\n ${error.message}',
                                  );
                                },
                                codeSent: (verificationId,
                                    forceResendingToken) async {
                                  setState(() {
                                    _verificationId = verificationId;
                                  });
                                  Navigator.pushNamed(
                                    context,
                                    '/otp',
                                    arguments: verificationId,
                                  );
                                },
                                timeout: const Duration(seconds: 60),
                                codeAutoRetrievalTimeout: (verificationId) {
                                  devtool.log("auto retrireval timeout");
                                  setState(() {
                                    _verificationId = verificationId;
                                  });
                                },
                              );
                              setState(() {
                                isloading = false;
                              });
                            } catch (e) {
                              await showErrorDialog(
                                  context, 'An unexpected error occurred: $e');
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please fill phone number field correctly'),
                              ),
                            );
                          }

                          setState(() {
                            isloading = false;
                          });
                        }, //on pressed
                        child: const Text("Continue"),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
