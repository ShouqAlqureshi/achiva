import 'package:achiva/views/auth/gender_selection_view.dart';
import 'package:achiva/views/auth/new_user_info_view.dart';
import 'package:achiva/views/auth/phone_num_authview.dart';
import 'package:achiva/views/auth/profile_picture_picker.dart';
import 'package:achiva/views/auth/sms_verification_authview.dart';
import 'package:achiva/views/friends_feed_page.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/profile/profile_screen.dart';
import 'package:achiva/views/profile/layout_controller/layout_cubit.dart';
import 'package:achiva/widgets/bottom_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
      home: const MainApp(),
      routes: {
        '/otp': (context) => const VerfyCodeView(),
        '/phoneauth': (context) => const PhoneNumAuthView(),
        '/newuser': (context) => const NewUserInfoView(),
        '/profilepicturepicker': (context) => const ProfilePicturePicker(),
        '/gender_selection': (context) => const GenderSelectionView(),
      },
    ),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FriendsFeedScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}