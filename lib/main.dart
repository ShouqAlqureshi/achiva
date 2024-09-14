// import 'dart:developer' as devtool show log;
import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/new_user_info_view.dart';
import 'package:achiva/views/profile_picture_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/models.dart';
void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter is initialized before Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    title: 'Achiva',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const PhoneNumAuthView(),
    routes: {
      '/otp': (context) => const VerfyCodeView(),
      '/home': (context) => const HomeScreen(),
      '/phoneauth': (context) => const PhoneNumAuthView(),
      '/newuser': (context) => const NewUserInfoView(),
      '/profilepicturepicker': (context) => const ProfilePicturePicker(),
    },
  ));
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   late final TextEditingController _phonenumber;
//   String _verificationId = '';
//   @override
//   void initState() {
//     super.initState();
//     _phonenumber = TextEditingController();
//   }

//   @override
//   void dispose() {
//     _phonenumber.dispose();
//     super.dispose();
//   }

//   bool isloading = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Welcome to achiva ",
//               style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             TextField(
//               controller: _phonenumber,
//               enableSuggestions: false,
//               autocorrect: false,
//               keyboardType: TextInputType.phone,
//               decoration: InputDecoration(
//                 fillColor: Colors.grey.withOpacity(0.25),
//                 filled: true,
//                 hintText: "enter your Phone number here",
//                 prefixIcon: const Icon(Icons.phone),
//                 border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none),
//               ),
//             ),
//             isloading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: () async {
//                       setState(() {
//                         isloading = true;
//                       });
//                       FirebaseAuth.instance.verifyPhoneNumber(
//                         phoneNumber: _phonenumber.text,
//                         verificationCompleted: (phoneAuthCredential) async {
//                           await FirebaseAuth.instance
//                               .signInWithCredential(phoneAuthCredential);
//                         },
//                         verificationFailed: (FirebaseAuthException error) {
//                           devtool.log(error.toString());
//                           if (error.code == 'invalid-phone-number') {
//                             showErrorDialog(context,
//                                 'The provided phone number is not valid.');
//                           }
//                         },
//                         codeSent: (verificationId, forceResendingToken) async {
//                           setState(() {
//                             isloading = false;
//                           });
//                           setState(() {
//                             _verificationId = verificationId;
//                           });
//                           Navigator.pushNamed(
//                             context,
//                             '/otp',
//                             arguments: verificationId,
//                           );
//                           setState(() {
//                             _verificationId = verificationId;
//                           });
//                         },
//                         timeout: const Duration(seconds: 60),
//                         codeAutoRetrievalTimeout: (verificationId) {
//                           devtool.log("auto retrireval timeout");
//                           setState(() {
//                             _verificationId = verificationId;
//                           });
//                         },
//                       );
//                     },
//                     child: const Text("Continue"),
//                   )
//           ],
//         ),
//       ),
//     );
//   }
// }
