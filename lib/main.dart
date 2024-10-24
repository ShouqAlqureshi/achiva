import 'package:achiva/views/activity/activity.dart';
import 'package:achiva/views/auth/gender_selection_view.dart';
import 'package:achiva/views/auth/new_user_info_view.dart';
import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/profile_picture_picker.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/profile/layout_controller/layout_cubit.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider
        .playIntegrity, // [DO NOT DO THIS] change for debug for emulators and add debug token in terminal and playIntegrity for android device
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LayoutCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Achiva',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
           scaffoldBackgroundColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        home: const AuthWrapper(),
        routes: {
          '/otp': (context) => const VerfyCodeView(),
          '/home': (context) => const HomeScreen(),
          '/phoneauth': (context) => const PhoneNumAuthView(),
          '/newuser': (context) => const NewUserInfoView(),
          '/profilepicturepicker': (context) => const ProfilePicturePicker(),
          '/gender_selection': (context) => const GenderSelectionView(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return FutureBuilder(
          future: Future.delayed(const Duration(seconds: 2)), // Minimum splash duration
          builder: (context, _) {
            if (snapshot.connectionState == ConnectionState.waiting || _.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            } else if (snapshot.hasData) {
              return const HomeScreen();
            } else {
              return const PhoneNumAuthView();
            }
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/images/logo-with-name.png',
                width: 400,
                height: 400,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error'); // Add this for debugging
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Image loading error',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),),),
    );
  }
}
