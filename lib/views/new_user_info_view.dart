import 'package:flutter/material.dart';

class NewUserInfoView extends StatefulWidget {
  const NewUserInfoView({super.key});

  @override
  State<NewUserInfoView> createState() => _NewUserInfoViewState();
}

class _NewUserInfoViewState extends State<NewUserInfoView> {
  String fn = "";
  String ln = "";
  String gender = "";
  String photo = "";
  late final TextEditingController email;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "enter your first name",
              style: TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: TextField(
                decoration: InputDecoration(
                  fillColor: Colors.grey.withOpacity(0.25),
                  filled: true,
                  hintText: "First Name ",
                  prefixIcon: const Icon(Icons.abc),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const Text(
              "enter your last name",
              style: TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: TextField(
                decoration: InputDecoration(
                  fillColor: Colors.grey.withOpacity(0.25),
                  filled: true,
                  hintText: "Last Name",
                  prefixIcon: const Icon(Icons.abc),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const Text(
              "enter your Gender",
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
                          gender = "female";
                        },
                        child: const Text("Female")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: () {
                          gender = "male";
                        },
                        child: const Text("Male")),
                  ),
                ],
              ),
            ),
            const Text(
              "enter your Email",
              style: TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: TextField(
                controller: email,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  fillColor: Colors.grey.withOpacity(0.25),
                  filled: true,
                  hintText: "Email ex: xxx@gmail.com",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
            
                  Navigator.of(context).pushNamed('/profilepicturepicker');
            
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
