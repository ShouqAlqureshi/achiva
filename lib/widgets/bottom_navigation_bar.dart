import 'package:achiva/utilities/colors.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/profile/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../views/addition_views/add_goal_page.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  State<BottomNavigationBarWidget> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 10), // Ensure spacing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home Icon
          const SizedBox(
            width: 50,
            height: 50,
            child: Icon(
              CupertinoIcons.home,
              color: CoursesColors.darkGreen,
            ),
          ),

          // Circular Add Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddGoalPage(),
                ),
              );
            },
            child: SizedBox(
              width: 60, // Adjusted width for even spacing
              height: 60,
              child: CircleAvatar(
                backgroundColor: WellBeingColors.darkMaroon,
                child: const Icon(
                  CupertinoIcons.add,
                  color: Color.fromARGB(255, 252, 255, 252),
                ),
              ),
            ),
          ),

          // Person Icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                CupertinoIcons.person,
                color: CoursesColors.darkGreen.withOpacity(.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
