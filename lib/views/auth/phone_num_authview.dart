import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/views/auth/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as devtool show log;
import '../../utilities/show_error_dialog.dart';

class PhoneNumAuthView extends StatefulWidget {
  const PhoneNumAuthView({super.key});

  @override
  State<PhoneNumAuthView> createState() => _PhoneNumAuthViewState();
}

class _PhoneNumAuthViewState extends State<PhoneNumAuthView> {
  late final TextEditingController _phonenumber;
  String _verificationId = '';
  Validators validation = Validators();
  bool isFormSubmitted = false;
  bool isPhonenumTouched = false;
  bool isloading = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Image.asset(
            'lib/images/logo-with-name.png',
            fit: BoxFit.contain,
            height: 250,
          ),
          toolbarHeight: 150,
          centerTitle: true,
          backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(30), // More rounded edges
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 5), // Shadow position
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                width: 450,
                height: 450,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Welcome to ",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 240, 238, 249),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const Text(
                      "Achiva,",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 240, 238, 249),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 30),
                    Text("follow this format:+966[number]",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: const Color.fromARGB(255, 54, 53, 53),
                            fontSize: 14)),
                    const SizedBox(height: 15),
                    TextField(
                      maxLength: 30, // Set the maximum number of characters
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                            50), // Enforce the limit
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
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
                        counterText: '',
                        hintText: "Enter your phone number",
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded input
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
                        ? const Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                                backgroundColor: Colors.black,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red)),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isloading = true;
                                isFormSubmitted = true;
                              });
                              if (validation
                                      .validatePhoneNum(_phonenumber.text)
                                      ?.isEmpty ??
                                  true) {
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
                                        'Check your phone number format:\n ${error.message}',
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
                                      devtool.log("auto retrieval timeout");
                                      setState(() {
                                        _verificationId = verificationId;
                                      });
                                    },
                                  );
                                  setState(() {
                                    isloading = false;
                                  });
                                } catch (e) {
                                  await showErrorDialog(context,
                                      'An unexpected error occurred: $e');
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
                            }, // on pressed
                            child: const Text("Continue"),
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
