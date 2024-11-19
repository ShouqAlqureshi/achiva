import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/components/loading_widget.dart';
import 'package:achiva/core/components/no_internet_found_column_widget.dart';
import 'package:achiva/core/components/server_failure_column_widget.dart';
import 'package:achiva/core/errors/app_failures.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:achiva/models/user_model.dart';
import 'package:achiva/views/profile/friend_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout_controller/layout_cubit.dart';
import '../../layout_controller/layout_states.dart';

class UserFriendsListviewWidget extends StatefulWidget {
  final LayoutCubit layoutCubit;
  const UserFriendsListviewWidget({super.key, required this.layoutCubit});

  @override
  State<UserFriendsListviewWidget> createState() => _UserFriendsListviewWidgetState();
}

class _UserFriendsListviewWidgetState extends State<UserFriendsListviewWidget> {
  @override
  void initState() {
    widget.layoutCubit.getMyFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutCubit, LayoutStates>(
      builder: (context, state) {
        if (widget.layoutCubit.myFriends.isNotEmpty) {
          return Column(
            children: [
              for (int index = 0; index < widget.layoutCubit.myFriends.length; index++) ...[
                if (index > 0) AppConstants.kSeparatorBuilder()(context, index),
                _buildFriendItem(widget.layoutCubit.myFriends[index]),
              ],
            ],
          );
        } else if (state is GetUserFriendsWithFailureState) {
          if (state.failure.runtimeType == InternetNotFoundFailure) {
            return InternetLostColumnWidget(
                retryFunction: () => widget.layoutCubit.getMyFriends());
          } else {
            return const ServerFailureColumnWidget();
          }
        } else {
          if (state is GetUserFriendsSuccessfullyState &&
              widget.layoutCubit.myFriends.isEmpty) {
            return Container(
              alignment: Alignment.center,
              height: 300,
              child: Text(
                "No Friend add until now!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlack,
                ),
              ),
            );
          } else {
            return const SizedBox(
                height: 300,
                child: LoadingWidget(message: "Loading User Friends"));
          }
        }
      },
    );
  }

  Widget _buildFriendItem(UserModel user) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FriendProfileScreen(
                    userModel: user,
                  )),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 240),
          borderRadius: AppConstants.kMainRadius,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.amber,
            backgroundImage: NetworkImage(user.photo ?? ""),
            onBackgroundImageError: (exception, stackTrace) =>
                const SizedBox(),
          ),
          title: Text(
            "${user.fname}  ${user.lname}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlack,
            ),
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Remove Friend"),
                    content: Text("Are you sure you want to remove ${user.fname} ${user.lname} from your friends?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text("Remove"),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await widget.layoutCubit.removeFrieand(userId: user.id);
              }
            },
            child: Text(
              "remove",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}