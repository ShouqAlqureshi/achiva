import 'package:achiva/utilities/colors.dart';
import 'package:achiva/views/addition_views/add_goal_page.dart';
import 'package:flutter/material.dart';

class FloatingBottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingBottomNavigationBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                _buildNavItem(Icons.home, 'Home', 0),
                const SizedBox(width: 30),
                _buildNavItem(Icons.people, 'Friends', 1),
                const SizedBox(width: 80), // Space for FAB
                _buildNavItem(Icons.notifications, 'Activity', 2),
                const SizedBox(width: 30),
                _buildNavItem(Icons.person, 'Profile', 3),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
        Positioned(
          top: -25,
          child: _buildAddButton(context),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? CoursesColors.darkGreen : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? CoursesColors.darkGreen : Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddGoalPage()),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}