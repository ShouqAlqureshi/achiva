// ignore_for_file: use_build_context_synchronously

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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Card(
              color: Colors.deepPurple, // Set card color to deep purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Colors.grey.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        maxLength: 50, // Set the maximum number of characters
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                              50), // Enforce the limit
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
                            borderSide:
                                (isFirstNameTouched || isFormSubmitted) &&
                                        fn.text.isEmpty
                                    ? const BorderSide(
                                        color: Color.fromARGB(255, 195, 24, 12))
                                    : BorderSide.none,
                          ),
                          errorText: (isFirstNameTouched || isFormSubmitted) &&
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
                        maxLength: 50, // Set the maximum number of characters
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(50),
                          FilteringTextInputFormatter.deny(
                              RegExp(r'\s')), // Enforce the limit
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
                            borderSide:
                                (isLastNameTouched || isFormSubmitted) &&
                                        ln.text.isEmpty
                                    ? const BorderSide(
                                        color: Color.fromARGB(255, 195, 24, 12))
                                    : BorderSide.none,
                          ),
                          errorText: (isLastNameTouched || isFormSubmitted) &&
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
                        maxLength: 150, // Set the maximum number of characters
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                              50), // Enforce the limit
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
                            borderSide: (isEmailTouched || isFormSubmitted) &&
                                    (validation
                                            .validateEmail(email.text)
                                            ?.isEmpty ??
                                        true)
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color.fromARGB(255, 195, 24, 12)),
                          ),
                          errorText: (isEmailTouched || isFormSubmitted)
                              ? validation.validateEmail(email.text)
                              : null,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
                            // "gender": gender,
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
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
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
}
