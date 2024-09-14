import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/new_user_info_view.dart';
import 'package:achiva/views/profile_picture_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'models/models.dart';

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
