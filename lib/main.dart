import 'package:achiva/views/auth/gender_selection_view.dart';
import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/auth/new_user_info_view.dart';
import 'package:achiva/views/profile/layout_controller/layout_cubit.dart';
import 'package:achiva/views/auth/profile_picture_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );
   await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  runApp(BlocProvider(
    create: (context) => LayoutCubit(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Achiva',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/otp': (context) => const VerfyCodeView(),
        '/home': (context) => const HomeScreen(),
        '/phoneauth': (context) => const PhoneNumAuthView(),
        '/newuser': (context) => const NewUserInfoView(),
        '/profilepicturepicker': (context) => const ProfilePicturePicker(),
        '/gender_selection': (context) => const GenderSelectionView(),
      },
    ),
  ));
}
