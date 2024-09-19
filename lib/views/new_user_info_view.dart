import 'package:flutter/material.dart';

class NewUserInfoView extends StatefulWidget {
  const NewUserInfoView({super.key});

  @override
  State<NewUserInfoView> createState() => _NewUserInfoViewState();
}

class _NewUserInfoViewState extends State<NewUserInfoView> {
  String gender = "";
  late final TextEditingController email;
  late final TextEditingController fn;
  late final TextEditingController ln;
  bool isFirstNameTouched = false;
  bool isLastNameTouched = false;
  bool isEmailTouched = false;
  bool isFormSubmitted = false;

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

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    if (!isValidEmail(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 150),
              const Text(
                "Enter your first name",
                style: TextStyle(fontSize: 20),
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
                    fillColor: Colors.grey.withOpacity(0.25),
                    filled: true,
                    hintText: "First Name ",
                    prefixIcon: const Icon(Icons.abc),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    errorText: (isFirstNameTouched || isFormSubmitted) &&
                            fn.text.isEmpty
                        ? "First name is required"
                        : null,
                  ),
                ),
              ),
              const Text(
                "Enter your last name",
                style: TextStyle(fontSize: 20),
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
                    fillColor: Colors.grey.withOpacity(0.25),
                    filled: true,
                    hintText: "Last Name",
                    prefixIcon: const Icon(Icons.abc),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    errorText: (isLastNameTouched || isFormSubmitted) &&
                            ln.text.isEmpty
                        ? "Last name is required"
                        : null,
                  ),
                ),
              ),
              const Text(
                "Enter your Gender",
                style: TextStyle(fontSize: 20),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            gender = "female";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gender == "female"
                              ? Colors.grey
                              : const Color.fromARGB(255, 255, 204, 241),
                        ),
                        child: const Text("Female"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            gender = "male";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gender == "male"
                              ? Colors.grey
                              : const Color.fromARGB(255, 201, 228, 251),
                        ),
                        child: const Text("Male"),
                      ),
                    ),
                  ],
                ),
              ),
              if (isFormSubmitted && gender.isEmpty)
                const Text(
                  "Gender is required",
                  style: TextStyle(
                      color: Color.fromARGB(255, 195, 24, 12), fontSize: 11),
                ),
              const Text(
                "Enter your Email",
                style: TextStyle(fontSize: 20),
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
                    fillColor: Colors.grey.withOpacity(0.25),
                    filled: true,
                    hintText: "Email ex: xxx@gmail.com",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    errorText: (isEmailTouched || isFormSubmitted)
                        ? validateEmail(email.text)
                        : null,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isFormSubmitted = true;
                  });
                  if (fn.text.isNotEmpty &&
                      ln.text.isNotEmpty &&
                      gender.isNotEmpty &&
                      validateEmail(email.text) == null) {
                    final datatosave = ModalRoute.of(context)!
                        .settings
                        .arguments as Map<String, dynamic>;
                    datatosave.addAll({
                      "fname": fn.text,
                      "lname": ln.text,
                      "email": email.text,
                      "gender": gender,
                    });
                    Navigator.of(context).pushNamed('/profilepicturepicker',
                        arguments: datatosave);
                  } else {
                    // Show an error message or handle invalid form
                    ScaffoldMessenger.of(context).showSnackBar(
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
}
