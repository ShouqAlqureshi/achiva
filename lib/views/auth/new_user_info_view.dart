// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:achiva/views/auth/validators.dart';

class NewUserInfoView extends StatefulWidget {
  const NewUserInfoView({super.key});

  @override
  State<NewUserInfoView> createState() => _NewUserInfoViewState();
}

class _NewUserInfoViewState extends State<NewUserInfoView> {
  // String gender = "";
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
      backgroundColor: Colors.grey.shade900,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 150),
              const Text(
                "Enter your first name",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: fn,
                  onChanged: (value) {
                    setState(() {
                      isFirstNameTouched = true;
                    });
                  },
                  decoration: InputDecoration(
                    fillColor: Colors.white.withOpacity(0.25),
                    filled: true,
                    hintText: "First Name ",
                    prefixIcon: const Icon(Icons.abc),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: (isFirstNameTouched || isFormSubmitted) &&
                                fn.text.isEmpty
                            ? const BorderSide(
                                color: Color.fromARGB(255, 195, 24, 12))
                            : BorderSide.none),
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
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: ln,
                  onChanged: (value) {
                    setState(() {
                      isLastNameTouched = true;
                    });
                  },
                  decoration: InputDecoration(
                    fillColor: Colors.white.withOpacity(0.25),
                    filled: true,
                    hintText: "Last Name",
                    prefixIcon: const Icon(Icons.abc),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: (isLastNameTouched || isFormSubmitted) &&
                                ln.text.isEmpty
                            ? const BorderSide(
                                color: Color.fromARGB(255, 195, 24, 12))
                            : BorderSide.none),
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
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: email,
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
                    hintText: "Email ex: xxx@gmail.com",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: (isEmailTouched || isFormSubmitted) &&
                              (validation.validateEmail(email.text)?.isEmpty ??
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  setState(() {
                    isFormSubmitted = true;
                  });
                  final contextBeforeAsync = context;
                  bool isvalidFields = await _validateForm() as bool;
                  if (isvalidFields) {
                    final datatosave = ModalRoute.of(context)!
                        .settings
                        .arguments as Map<String, dynamic>;
                    datatosave.addAll({
                      "fname": fn.text,
                      "lname": ln.text,
                      "email": email.text,
                      // "gender": gender,
                    });
                    Navigator.of(contextBeforeAsync)
                        .pushNamed('/gender_selection', arguments: datatosave);
                  } else {
                    // Show an error message or handle invalid form
                    ScaffoldMessenger.of(contextBeforeAsync).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields correctly'),
                      ),
                    );
                  }
                },
                child: const Text("Continue"),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _validateForm() async {
    bool isUnique = await validation.isEmailUnique(email.text);
    return fn.text.isNotEmpty &&
        ln.text.isNotEmpty &&
        // gender.isNotEmpty &&
        isUnique &&
        (validation.validateEmail(email.text)?.isEmpty ?? true);
  }
}
