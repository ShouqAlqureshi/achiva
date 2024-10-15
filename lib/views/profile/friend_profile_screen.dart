import 'package:achiva/core/constants/constants.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:achiva/models/goal_model.dart';
import 'package:achiva/models/user_model.dart';
import 'package:achiva/views/profile/layout_controller/layout_cubit.dart';
import 'package:achiva/views/profile/widgets/profile_widgets/textBehindIconWidget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FriendProfileScreen extends StatelessWidget {
  final UserModel userModel;
  const FriendProfileScreen({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(
                userModel.photo ?? "",
              ),
              onBackgroundImageError: (exception, stackTrace) =>
                  const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            16.vrSpace,
            Text(
              "${userModel.fname} ${userModel.lname}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  color: AppColors.kBlack,
                  fontWeight: FontWeight.bold),
            ),
            4.vrSpace,
            Text(
              userModel.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.kDarkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: AppConstants.kContainerPadding,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.deepPurple,
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
            FutureBuilder<List<GoalModel>>(
              future: LayoutCubit().getGoalsByUserId(userId: userModel.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError ||
                    snapshot.data == null ||
                    !snapshot.hasData) {
                  return Center(
                    child: Text("no Goals Fond"),
                  );
                }
                List<GoalModel> goals = snapshot.data!;
                return ListView.separated(
                  itemCount: goals.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  separatorBuilder: AppConstants.kSeparatorBuilder(),
                  itemBuilder: (context, index) => Container(
                    padding: AppConstants.kContainerPadding,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 240, 240, 240),
                      borderRadius: AppConstants.kMainRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goals[index].name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlack,
                          ),
                        ),
                        8.vrSpace,
                        Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(goals[index].date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kLightGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
