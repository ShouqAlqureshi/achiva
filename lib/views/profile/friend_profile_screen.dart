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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 66, 32, 101),
                    Color.fromARGB(255, 77, 64, 98),
                  ],
                ),
                borderRadius: AppConstants.kMainRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  TextBehindIconWidget(
                    title: "Productivity",
                    iconData: Icons.message,
                    numValue: "0",
                  ),
                  TextBehindIconWidget(
                    iconData: Icons.task_alt,
                    title: "Goals done",
                    numValue: "0",
                  ),
                ],
              ),
            ),
            // Add a heading for the goals section
            Text(
              "Goals",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.kBlack,
              ),
            ),
            8.vrSpace, // Space before the goals list
            FutureBuilder<List<GoalModel>>(
              future: LayoutCubit().getGoalsByUserId(userId: userModel.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  );
                }
                if (snapshot.hasError ||
                    snapshot.data == null ||
                    !snapshot.hasData) {
 
                  return const Center(
                    child: Text(
                      "No Goals Found",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  );
                }
                List<GoalModel> goals = snapshot.data!;
                return ListView.separated(
                  itemCount: goals.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  separatorBuilder: AppConstants.kSeparatorBuilder(),
                  itemBuilder: (context, index) => Container(
                    padding: AppConstants.kContainerPadding,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: AppConstants.kMainRadius,
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
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