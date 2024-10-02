import 'package:achiva/views/auth/gender_selection_view.dart';
import 'package:achiva/views/auth/new_user_info_view.dart';
import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/profile_picture_picker.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/profile/layout_controller/layout_cubit.dart';
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
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const PhoneNumAuthView();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'lib/images/logo-with-name.png',
          width: 200, 
          height: 200, 
        ),
      ),
    );
  }
}

