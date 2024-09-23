
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/Constants/constants.dart';
import '../../../core/constants/strings.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/layout_controller/layout_cubit.dart';
import '../profile/layout_controller/layout_states.dart';
import '../profile/widgets/profile_widgets/listTileWidget.dart';
import 'check_otp_of_current_phone_screen.dart';

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
      appBar: AppBar(
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
            ),
            ListTileWidget(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                              layoutCubit: widget.layoutCubit)));
                },
                title: "Edit Profile",
                leadingIconData: Icons.account_circle),
            ListTileWidget(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CheckOtpOfCurrentPhoneScreen(
                              layoutCubit: widget.layoutCubit,
                              phoneNumber:
                                  widget.layoutCubit.user!.phoneNumber)));
                },
                title: "Change Phone",
                leadingIconData: Icons.phone),
            ListTileWidget(
              onTap: () {
                Navigator.pushNamed(
                    context, AppStrings.kDeleteAccountScreenName);
              },
              title: "Delete Account",
              leadingIconData: Icons.delete,
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
                onTap: () {
                  widget.layoutCubit.signOut(notToEmitToState: false);
                },
                title: "Sign Out",
                leadingIconData: Icons.login_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
