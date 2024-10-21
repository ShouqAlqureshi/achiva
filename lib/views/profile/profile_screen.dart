import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/components/loading_widget.dart';
import 'package:achiva/core/components/no_internet_found_column_widget.dart';
import 'package:achiva/core/components/server_failure_column_widget.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/errors/app_failures.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:achiva/views/profile/widgets/profile_widgets/textBehindIconWidget.dart';
import 'package:achiva/views/profile/widgets/profile_widgets/user_friends_listview_widget.dart';
import 'package:achiva/views/profile/widgets/profile_widgets/user_goals_listview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting/app_settings_screen.dart';
import 'layout_controller/layout_cubit.dart';
import 'layout_controller/layout_states.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    LayoutCubit.getInstance(context).getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final LayoutCubit layoutCubit = LayoutCubit.getInstance(context)
      ..showFriendNotGoalsOnProfile = true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Profile"),
       automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<LayoutCubit, LayoutStates>(builder: (context, state) {
            if (layoutCubit.user != null) {
              return Padding(
                padding:
                    AppConstants.kContainerPadding.copyWith(top: 0, bottom: 0),
                child: InkWell(
                    child: const Icon(Icons.settings),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AppSettingsScreen(layoutCubit: layoutCubit)))),
              );
            } else {
              return const SizedBox();
            }
          })
        ],
      ),
      body: BlocBuilder<LayoutCubit, LayoutStates>(builder: (context, state) {
        if (layoutCubit.user != null) {
          return ListView(
            padding: AppConstants.kScaffoldPadding,
            children: [
              Builder(
                builder: (context) {
                  if (layoutCubit.user!.photo == null) {
                    return CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person,
                          size: 60, color: Colors.grey),
                    );
                  } else {
                    return CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image.network(
                          layoutCubit.user!.photo!,
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                        ),
                      ),
                    );
                  }
                },
              ),
              16.vrSpace,
              Text(
                "${layoutCubit.user!.fname} ${layoutCubit.user!.lname}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    color: AppColors.kBlack,
                    fontWeight: FontWeight.bold),
              ),
              4.vrSpace,
              Text(layoutCubit.user!.phoneNumber,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.kDarkGrey,
                      fontWeight: FontWeight.w500)),
              Container(
                padding: AppConstants.kContainerPadding,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(255, 66, 32, 101),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
                    borderRadius: AppConstants.kMainRadius),
                child: const Row(
                  children: [
                    TextBehindIconWidget(
                        title: "Productivity",
                        iconData: Icons.message,
                        numValue: "0"),
                    TextBehindIconWidget(
                        iconData: Icons.task_alt,
                        title: "Goals done",
                        numValue: "0"),
                  ],
                ),
              ),
              Container(
                padding: AppConstants.kContainerPadding,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.kWhite,
                    borderRadius: AppConstants.kMainRadius),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            layoutCubit.toggleBetweenFriendsAndGoalsBar(
                                viewFriendsNotGoals: true),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: layoutCubit.showFriendNotGoalsOnProfile
                                  ? const Color.fromARGB(255, 53, 29, 94)
                                      .withOpacity(0.15)
                                  : AppColors.kLightGrey.withOpacity(0.1),
                              borderRadius: AppConstants.kMainRadius),
                          child: const Text(
                            "Friends",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    12.hrSpace,
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            layoutCubit.toggleBetweenFriendsAndGoalsBar(
                                viewFriendsNotGoals: false),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: layoutCubit.showFriendNotGoalsOnProfile ==
                                      false
                                  ? const Color.fromARGB(255, 53, 29, 94)
                                      .withOpacity(0.15)
                                  : AppColors.kLightGrey.withOpacity(0.1),
                              borderRadius: AppConstants.kMainRadius),
                          child: const Text(
                            "Goals",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  if (layoutCubit.showFriendNotGoalsOnProfile) {

                     return UserFriendsListviewWidget(layoutCubit: layoutCubit);
                    
                  } else {
                    return UserGoalsListviewWidget(layoutCubit: layoutCubit);
                  }
                },
              )
            ],
          );
        } else if (state is GetUserDataWithFailureState) {
          if (state.failure.runtimeType == InternetNotFoundFailure) {
            return InternetLostColumnWidget(
                retryFunction: () => layoutCubit.getUserData());
          } else {
            return const ServerFailureColumnWidget();
          }
        } else {
          return const LoadingWidget(
            message: "Loading User Data",
          );
        }
      }),
    );
  }
}
