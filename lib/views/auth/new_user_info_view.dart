import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:achiva/views/auth/validators.dart';
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
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 71, 71, 71),
            ),
            textAlign: TextAlign.start,
          ),
          toolbarHeight: 100,
          centerTitle: true,
          backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.deepPurple, // Set card color to deep purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: Colors.grey.withOpacity(0.5),
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
                              color: Colors.white), // Set text color to white
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: fn,
                            maxLength:
                                50, // Set the maximum number of characters
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
                              fillColor: Colors.white.withOpacity(0.25),
                              filled: true,
                              counterText: '',
                              hintText: "First Name",
                              prefixIcon:
                                  const Icon(Icons.abc, color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: (isFirstNameTouched ||
                                            isFormSubmitted) &&
                                        fn.text.isEmpty
                                    ? const BorderSide(
                                        color: Color.fromARGB(255, 195, 24, 12))
                                    : BorderSide.none,
                              ),
                              errorText:
                                  (isFirstNameTouched || isFormSubmitted) &&
                                          fn.text.isEmpty
                                      ? "First name is required"
                                      : null,
                            ),
                          ),
                        ),
                        const Text(
                          "Enter your last name",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: ln,
                            maxLength:
                                50, // Set the maximum number of characters
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
                              fillColor: Colors.white.withOpacity(0.25),
                              filled: true,
                              counterText: '',
                              hintText: "Last Name",
                              prefixIcon:
                                  const Icon(Icons.abc, color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: (isLastNameTouched ||
                                            isFormSubmitted) &&
                                        ln.text.isEmpty
                                    ? const BorderSide(
                                        color: Color.fromARGB(255, 195, 24, 12))
                                    : BorderSide.none,
                              ),
                              errorText:
                                  (isLastNameTouched || isFormSubmitted) &&
                                          ln.text.isEmpty
                                      ? "Last name is required"
                                      : null,
                            ),
                          ),
                        ),
                        const Text(
                          "Enter your Email",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: email,
                            maxLength:
                                150, // Set the maximum number of characters
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
                              fillColor: Colors.white.withOpacity(0.25),
                              filled: true,
                              counterText: '',
                              hintText: "Email ex: xxx@gmail.com",
                              prefixIcon:
                                  const Icon(Icons.email, color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: (isEmailTouched ||
                                            isFormSubmitted) &&
                                        (validation
                                                .validateEmail(email.text)
                                                ?.isEmpty ??
                                            true)
                                    ? BorderSide.none
                                    : const BorderSide(
                                        color:
                                            Color.fromARGB(255, 195, 24, 12)),
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
                    backgroundColor:
                        Colors.deepPurple, // Deep purple background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // Prevent dismissal by tapping outside
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
                      final dataToSave = ModalRoute.of(context)!
                          .settings
                          .arguments as Map<String, dynamic>;
                      dataToSave.addAll({
                        "fname": fn.text,
                        "lname": ln.text,
                        "email": email.text,
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 149, 45, 40), // Deep purple background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    final iscanceld = await showCancelDialog(context);
                    if (iscanceld) {
                      await deleteUserAccount();
                    }
                  },
                  child: const Text(
                    "Cancel Registration",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _validateForm() async {
    bool isUnique = await validation.isEmailUnique(email.text);
    return fn.text.isNotEmpty &&
        ln.text.isNotEmpty &&
        isUnique &&
        (validation.validateEmail(email.text)?.isEmpty ?? true);
  }

  Future<bool> showCancelDialog(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 54, 52, 58),
            title: const Icon(Icons.exit_to_app),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Are you sure you want to cancel registration?",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "By canceling, you will go back to the sign-up page to redo the process.",
                  style: TextStyle(
                      color: Color.fromARGB(255, 201, 199, 199), fontSize: 12),
                )
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Align buttons with space between
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text(
                        "No, Proceed",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Add space between buttons
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black26,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text(
                      "Yes, cancel Registration",
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
        }).then((value) => value ?? false);
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
        Navigator.of(context).pushNamed(
          '/phoneauth',
        );
      } else { 
        log('No user is currently signed in.');
      }
    } catch (e) {
      log('Error deleting user account: $e');
    }
  }
}
