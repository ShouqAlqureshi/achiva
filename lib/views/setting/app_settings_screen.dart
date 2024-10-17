import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/Constants/constants.dart';
import '../../../core/constants/strings.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';
import '../profile/widgets/profile_widgets/listTileWidget.dart';
import 'check_otp_of_current_phone_screen.dart';
import 'delete_account_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  final LayoutCubit layoutCubit;

  const AppSettingsScreen({super.key, required this.layoutCubit});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  @override
  void initState() {
    if (!widget.layoutCubit.showFriendNotGoalsOnProfile) {
      widget.layoutCubit
          .toggleBetweenFriendsAndGoalsBar(viewFriendsNotGoals: true);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: AppConstants.kScaffoldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTileWidget(
              onTap: () {
                Navigator.pushNamed(
                    context, AppStrings.kNotificationsScreenName);
              },
              title: "Notifications",
              leadingIconData: Icons.notification_important,
              backgroundColor: Colors.deepPurple,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            ListTileWidget(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditProfileScreen(layoutCubit: widget.layoutCubit)));
              },
              title: "Edit Profile",
              leadingIconData: Icons.account_circle,
              backgroundColor: Colors.deepPurple,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            ListTileWidget(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CheckOtpOfCurrentPhoneScreen(
                              layoutCubit: widget.layoutCubit,
                              phoneNumber:
                                  widget.layoutCubit.user!.phoneNumber,
                            )));
              },
              title: "Change Phone",
              leadingIconData: Icons.phone,
              backgroundColor: Colors.deepPurple,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            ListTileWidget(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DeleteAccountScreen()));
              },
              title: "Delete Account",
              leadingIconData: Icons.delete,
              backgroundColor: Colors.deepPurple,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            BlocListener<LayoutCubit, LayoutStates>(
              listenWhen: (past, currentState) =>
                  currentState is SignOutSuccessfullyState,
              listener: (context, state) {
                if (state is SignOutSuccessfullyState) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppStrings.kLoginScreenName, (_) => true);
                }
              },
              child: ListTileWidget(
                onTap: () async {

                 try {
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/phoneauth', (_) => false);
                  }
                } on UserNotLoggedInAuthException catch (_) {
                  showErrorDialog(context, "User is not logged in");
                }

                },

                title: "Log Out",
                leadingIconData: Icons.login_outlined,
                backgroundColor: const Color.fromARGB(255, 213, 80, 71), // Red background for Log Out
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showLogOutDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white, // Set dialog background to white
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.black), // Set title text color
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.black), // Set content text color
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black), // Customize button color if desired
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red), // Set log out button text color
            ),
          ),
        ],
      );
    },
  ).then((value) => value ?? false); // Ensure it returns false if dismissed
}

