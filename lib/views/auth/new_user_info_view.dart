import 'dart:developer';

import 'package:achiva/views/auth/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewUserInfoView extends StatefulWidget {
  const NewUserInfoView({super.key});

  @override
  State<NewUserInfoView> createState() => _NewUserInfoViewState();
}

class _NewUserInfoViewState extends State<NewUserInfoView> {
  late final TextEditingController email;
  late final TextEditingController fn;
  late final TextEditingController ln;
  bool isFirstNameTouched = false;
  bool isLastNameTouched = false;
  bool isEmailTouched = false;
  bool isFormSubmitted = false;
  Validators validation = Validators();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isloading = false;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
    fn = TextEditingController();
    ln = TextEditingController();
  }

  @override
  void dispose() {
    email.dispose();
    fn.dispose();
    ln.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile information",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          textAlign: TextAlign.start,
        ),
        toolbarHeight: 100,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 30, 12, 48),
                Color.fromARGB(255, 77, 64, 98),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Enter your first name",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 30, 12, 48),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: fn,
                              maxLength: 50,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  isFirstNameTouched = true;
                                });
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.grey[100],
                                filled: true,
                                counterText: '',
                                hintText: "First Name",
                                prefixIcon: const Icon(Icons.abc, color: Color.fromARGB(255, 30, 12, 48)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: (isFirstNameTouched || isFormSubmitted) && fn.text.isEmpty
                                      ? const BorderSide(color: Color.fromARGB(255, 195, 24, 12))
                                      : BorderSide.none,
                                ),
                                errorText: (isFirstNameTouched || isFormSubmitted) && fn.text.isEmpty
                                    ? "First name is required"
                                    : null,
                              ),
                            ),
                          ),
                          const Text(
                            "Enter your last name",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 30, 12, 48),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: ln,
                              maxLength: 50,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  isLastNameTouched = true;
                                });
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.grey[100],
                                filled: true,
                                counterText: '',
                                hintText: "Last Name",
                                prefixIcon: const Icon(Icons.abc, color: Color.fromARGB(255, 30, 12, 48)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: (isLastNameTouched || isFormSubmitted) && ln.text.isEmpty
                                      ? const BorderSide(color: Color.fromARGB(255, 195, 24, 12))
                                      : BorderSide.none,
                                ),
                                errorText: (isLastNameTouched || isFormSubmitted) && ln.text.isEmpty
                                    ? "Last name is required"
                                    : null,
                              ),
                            ),
                          ),
                          const Text(
                            "Enter your Email",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 30, 12, 48),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: email,
                              maxLength: 150,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              enableSuggestions: false,
                              autocorrect: false,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                setState(() {
                                  isEmailTouched = true;
                                });
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.grey[100],
                                filled: true,
                                counterText: '',
                                hintText: "Email ex: xxx@gmail.com",
                                prefixIcon: const Icon(Icons.email, color: Color.fromARGB(255, 30, 12, 48)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: (isEmailTouched || isFormSubmitted) &&
                                          (validation.validateEmail(email.text)?.isEmpty ?? true)
                                      ? BorderSide.none
                                      : const BorderSide(color: Color.fromARGB(255, 195, 24, 12)),
                                ),
                                errorText: (isEmailTouched || isFormSubmitted)
                                    ? validation.validateEmail(email.text)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 30, 12, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      setState(() {
                        isFormSubmitted = true;
                      });
                      final contextBeforeAsync = context;
                      bool isValidFields = await _validateForm();
                      if (isValidFields) {
                        final dataToSave =
                            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                        dataToSave.addAll({
                          "fname": fn.text,
                          "lname": ln.text,
                          "email": email.text,
                          "streak":0,
                        });
                        Navigator.of(context).pop();
                        Navigator.of(contextBeforeAsync).pushNamed(
                          '/gender_selection',
                          arguments: dataToSave,
                        );
                      } else {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(contextBeforeAsync).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields correctly'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isloading)
                    const Align(
                      alignment: Alignment.center,
                      child: Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 195, 24, 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final iscanceld = await showCancelDialog(context);
                      if (iscanceld) {
                        setState(() {
                          isloading = true;
                        });
                        await deleteUserAccount();
                        setState(() {
                          isloading = false;
                        });
                      }
                    },
                    child: const Text(
                      "Cancel Registration",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

Future<bool> _validateForm() async {
  bool isUnique = await validation.isEmailUnique(email.text);
  if (!isUnique) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email already exists'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  return fn.text.isNotEmpty &&
         ln.text.isNotEmpty &&
         (validation.validateEmail(email.text)?.isEmpty ?? true);
}

  Future<bool> showCancelDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 54, 52, 58),
          title: const Icon(
            Icons.warning_amber_outlined,
            size: 60,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "Are you sure you want to cancel registration?",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "By canceling, you will go back to the sign-up page to redo the process.",
                style: TextStyle(color: Color.fromARGB(255, 201, 199, 199), fontSize: 12),
              )
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    "Proceed",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    "cancel Registration",
                    style: TextStyle(
                      color: Color.fromARGB(255, 183, 43, 43),
                      fontSize: 13,
                    ),
                  ),

                ),
              ],
            ),

          ],
        );
      },
    ).then((value) => value ?? false);

  }

  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration process is canceled successfully.'),
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil('/phoneauth', (route) => false);
      } else {
        log('No user is currently signed in.');
      }
    } catch (e) {
      log('Error deleting user account: $e');
    }
  }
}