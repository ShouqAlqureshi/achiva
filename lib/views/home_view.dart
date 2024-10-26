import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:achiva/views/activity/activity.dart';
import 'package:achiva/views/activity/incoming_request_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utilities/filestore_services.dart';
import '../utilities/show_log_out_dialog.dart';
import 'package:achiva/widgets/bottom_navigation_bar.dart';
import 'package:achiva/utilities/colors.dart';
import 'package:achiva/models/goal.dart';
import 'package:achiva/views/SearchFriendsScreen.dart';
import 'package:achiva/views/friends_feed_page.dart';
import 'package:achiva/views/profile/profile_screen.dart';
import 'package:achiva/views/home_view.dart';
import 'GoalTasks.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late PageController _pageController;
  int _currentIndex = 0; // Track the current index for the bottom navigation

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Method to switch between pages when the navigation item is tapped
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController
        .jumpToPage(index); // Update the PageView when a tab is selected
  }
   Future<double> calculateGoalProgress(DocumentSnapshot goalDocument) async {
    try {
      // Get all tasks for this goal
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('goals')
          .doc(goalDocument.id)
          .collection('tasks')
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        return 0.0; // Return 0% if there are no tasks
      }

      // Count completed tasks
      int completedTasks = tasksSnapshot.docs
          .where((task) => (task.data() as Map<String, dynamic>)['completed'] == true)
          .length;

      // Calculate progress percentage
      double progress = (completedTasks / tasksSnapshot.docs.length) * 100;
      return progress.roundToDouble();
    } catch (e) {
      print('Error calculating progress: $e');
      return 0.0;
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: _currentIndex == 0
        ? AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.person_add,
                  size: 32,
                  color: CoursesColors.darkGreen,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchFriendsScreen()),
                  );
                },
              ),
            ],
          )
        : null,
    body: Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildHomePage(context),
            const FriendsFeedScreen(),
            const Activity(),
            const ProfileScreen(),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingBottomNavigationBarWidget(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
          ),
        ),
      ],
    ),
  );
}

Widget _buildHomePage(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Users")
                        .where("id",
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Text("Error fetching goals");
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        final goalDocuments = snapshot.data!.docs;
                        final userData = snapshot.data!.docs.first;
                        final String fname = userData['fname'];

                        return Column(
                          children: [
                            Text(
                              'Welcome back to Achiva, $fname!',
                              style: const TextStyle(
                                color: WellBeingColors.darkBlueGrey,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (goalDocuments.isEmpty)
                              Text(
                                "You have no goals yet. Start adding some!",
                                style: TextStyle(
                                  color: WellBeingColors.mediumGrey,
                                  fontSize: 16,
                                ),
                              )
                            else
                              Container(
                                height: 105,
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 13),
                                    Row(
                                      children: [
                                        Text(
                                          'Your productivity',
                                          style: TextStyle(
                                            color: WellBeingColors.mediumGrey,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          reportStats('2 Tasks', 'Today'),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: WellBeingColors.mediumGrey
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            height: 40,
                                            width: 1.2,
                                          ),
                                          reportStats('13 Tasks', 'This Week'),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: WellBeingColors.mediumGrey
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            height: 40,
                                            width: 1.2,
                                          ),
                                          reportStats('56 🚀', 'Steark'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      } else {
                        return const Text("No user data available");
                      }
                    },
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('goals')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text("Error fetching goals");
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            "No goals available. Please add some goals!",
                            style: TextStyle(
                              color: WellBeingColors.mediumGrey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.87),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final goalDocument = snapshot.data!.docs[index];
                          final goalData =
                              goalDocument.data() as Map<String, dynamic>;
                          final String goalName = goalData['name'];

                          return FutureBuilder<double>(
                            future: calculateGoalProgress(goalDocument),
                            builder: (context, progressSnapshot) {
                              if (progressSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              double progress = progressSnapshot.data ?? 0.0;
                              final isDone = progress >= 100;

                              return _buildGoalCard(
                                goalName,
                                progress,
                                isDone,
                                goalDocument,
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildGoalCard(String goalName, double progress, bool isDone,
    DocumentSnapshot goalDocument) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalTasks(goalDocument: goalDocument),
        ),
      );
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 35),
      padding: const EdgeInsets.all(20),
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 66, 32, 101),
            Color.fromARGB(255, 77, 64, 98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          if (isDone) ...[
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 6,
                          backgroundColor: Colors.white,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,  // Changed to green for completed state
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        child: Icon(  // Changed to checkmark icon
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Done!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            WellBeingColors.lightMaroon,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '${progress.round()}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        progress == 0 ? 'Not started yet' : 'In progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    ),
  );
}
  Widget reportStats(String stat, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat,
          style: TextStyle(
            color: WellBeingColors.darkBlueGrey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: WellBeingColors.mediumGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
