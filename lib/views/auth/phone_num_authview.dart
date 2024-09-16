import 'package:achiva/exceptions/auth_exceptions.dart';
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
              autofocus: true,
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
                      try {
                        if (_phonenumber.text.isEmpty) {
                          throw EmptyFieldException();
                        }

                        // Basic format check (you might want to use a more sophisticated regex)
                        if (!_phonenumber.text.startsWith('+') ||
                            _phonenumber.text.length < 8) {
                          throw InvalidPhoneNumberException(
                              'Phone number must start with + and be at least 8 characters long');
                        }
                        FirebaseAuth.instance.verifyPhoneNumber(
                          phoneNumber: _phonenumber.text,
                          verificationCompleted: (phoneAuthCredential) async {
                            await FirebaseAuth.instance
                                .signInWithCredential(phoneAuthCredential);
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              throw UserNotLoggedInAuthException();
                            }
                          },
                          verificationFailed:
                              (FirebaseAuthException error) async {
                            throw InvalidPhoneNumberException(
                                error.message ?? 'Unknown error occurred');
                          },
                          codeSent:
                              (verificationId, forceResendingToken) async {
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
                      } on EmptyFieldException {
                        await showErrorDialog(
                          context,
                          "Your phone number field is empty.\nPlease enter your phone number in the format: [+][country code][user number]",
                        );
                      } on InvalidPhoneNumberException catch (e) {
                        await showErrorDialog(
                          context,
                          'Invalid phone number: ${e.message}\nformat: [+][country code][user number]',
                        );
                      } catch (e) {
                        await showErrorDialog(
                            context, 'An unexpected error occurred: $e');
                      } finally {
                        setState(() {
                          isloading = false;
                        });
                      }
                    }, //on pressed
                    child: const Text("Continue"),
                  )
          ],
        ),
      ),
    );
  }
}
