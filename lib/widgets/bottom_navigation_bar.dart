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
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 60,
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.people, 'Friends', 1),
                    const SizedBox(width: 60), // Space for FAB
                    _buildNavItem(Icons.notifications, 'Activity', 2),
                    _buildNavItem(Icons.person, 'Profile', 3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: _buildAddButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
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
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 66, 32, 101),
            Color.fromARGB(255, 77, 64, 98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 45, 43, 47).withOpacity(0.3),
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