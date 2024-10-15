import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
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
    _pageController.jumpToPage(index); // Update the PageView when a tab is selected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.search,
              size: 32,
              color: CoursesColors.darkGreen,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchFriendsScreen()),
              );
            },
          ),
        
        ],
      ),
//       appBar: AppBar(
//   automaticallyImplyLeading: false,
//   backgroundColor: Colors.white,
//   title: Row(
//     mainAxisAlignment: MainAxisAlignment.end,
//     children: [
//       const SizedBox(
//         height: 50,
//         width: 50,
//         child: Icon(
//           CupertinoIcons.search,
//           size: 32,
//           color: CoursesColors.darkGreen,
//         ),
//       ),
//     ],
//   ),
// ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to switch pages
        children: [
          _buildHomePage(context),
          const FriendsFeedScreen(), // Your Friends Feed Page
          const ProfileScreen(), // Your Profile Page
        ],
      ),

      bottomNavigationBar: FloatingBottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
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
                          .where("id", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return const Text("Error fetching goals");
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          final goalDocuments = snapshot.data!.docs;
                          if (goalDocuments.isEmpty) {
                            return const Text("No goals available");
                          }


                          final userData = snapshot.data!.docs.first;
                          final String fname = userData['fname'];

                          return Text(
                            'Welcome back to Achiva, $fname!',
                            style: const TextStyle(
                              color: WellBeingColors.darkBlueGrey,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return const Text("No user data available");
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 105,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: .4,
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
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                reportStats('2 Tasks', 'Today'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: WellBeingColors.mediumGrey
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  height: 40,
                                  width: 1.2,
                                ),
                                reportStats('13 Tasks', 'This Week'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: WellBeingColors.mediumGrey
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
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
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("Users")
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('goals')
                            .snapshots(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return const Text("Error fetching goals");
                          }

                          if (snapshot.hasData && snapshot.data != null) {
                            final goalDocuments = snapshot.data!.docs;
                            if (goalDocuments.isEmpty) {
                              return const Text("No goals available");
                            }

                            return SizedBox(
            height: 300,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: goalDocuments.length,
              itemBuilder: (context, index) {
                final goalDocument = goalDocuments[index];
                final goalData = goalDocument.data() as Map<String, dynamic>;
                final String goalName = goalData['name'];
                double progress = (index + 1) * 10.0;
                final isDone = progress >= 100;

                return _buildGoalCard(goalName, progress, isDone, goalDocument);
              },
            ),
          );
        } else {
          return const Text("No goals available");
        }
      },
    ),
                    ],
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
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: progress < 100 ? Colors.deepPurple : Colors.white,
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
            const SizedBox(height: 23),
            if (isDone)
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: WellBeingColors.yellowColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: WellBeingColors.yellowColor,
                    size: 25,
                  ),
                ),
              ),
            if (!isDone)
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SizedBox(
                          height: 50,
                          width: 50,
                          child: CircularProgressIndicator(
                            value: progress / 100,
                            strokeWidth: 8,
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
                          height: 50,
                          width: 50,
                          alignment: Alignment.center,
                          child: Text(
                            '${progress.round()}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
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
                      const SizedBox(height: 6),
                      const Text(
                        'In progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
