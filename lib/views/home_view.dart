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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class GoalsPage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final CollectionReference goalCollection =
      FirebaseFirestore.instance.collection('goals');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late PageController _pageController;
  final currentUser = FirebaseAuth.instance;

  int farmsLength = 8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void getuser() async {
    await for (var snapshot in _firestore.collection('Users').snapshots()) {
      for (var user in snapshot.docs) {
        print(user.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(
              height: 50,
              width: 50,
              child: Icon(
                CupertinoIcons.search,
                size: 32,
                color: CoursesColors.darkGreen,
              ),
            ),
          ],
        ),
      ),body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                // Welcome message and report container
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
  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator(); // Show a loading spinner while data is being fetched
    }

    if (snapshot.hasError) {
      return const Text("Error fetching user data");
    }

    if (snapshot.hasData && snapshot.data != null) {
      final userData = snapshot.data!.docs.first; // Get the first matching document
      final String fname = userData['fname']; // Assuming 'fname' is the field storing the first name

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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                // Cards container
                // Cards container

              Expanded(
      child: Container(
        color: Colors.white, // Background color for the PageView
        child: Column(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('goals')
                  .snapshots(), // Stream from the 'goals' subcollection
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Loading indicator
                }

                if (snapshot.hasError) {
                  return const Text("Error fetching goals");
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final goalDocuments = snapshot.data!.docs; // Retrieve all goal documents
                  if (goalDocuments.isEmpty) {
                    return const Text("No goals available");
                  }

                  // Use PageView.builder to display goals in cards
                  return SizedBox(
                    height: 300, // Maintain the height for the cards
                    child: PageView.builder(
                      controller: _pageController, // Use the persistent PageController
                      onPageChanged: _handlePageViewChanged,
                      itemCount: goalDocuments.length, // Number of goals
                      itemBuilder: (context, index) {
                        final goalData = goalDocuments[index].data() as Map<String, dynamic>;
                        final String goalName = goalData['name']; // Assuming 'name' field in goal doc
                        double progress = (index + 1) * 10.0; // Sample progress calculation
                        final isDone = progress >= 100; // Check if the progress is complete

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 15), // Spacing between cards
                          padding: const EdgeInsets.symmetric(horizontal: 16), // Internal padding
                          height: MediaQuery.of(context).size.width / 2, // Card height
                          width: ((MediaQuery.of(context).size.width - 40) / 2) - 9, // Card width
                          decoration: BoxDecoration(
                            color: progress < 100
                                ? WellBeingColors.veryDarkMaroon
                                : Colors.white, // Background color based on progress
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 15,
                                offset: const Offset(0, 3), // Shadow effect
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20), // Rounded corners
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 23), // Spacing from top of the card
                              if (isDone)
                                // Checkmark when task is done
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
                                  // Row to align the progress indicator and the text next to it
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
                                              value: progress / 100, // Progress value
                                              strokeWidth: 8,
                                              backgroundColor: Colors.white,
                                              strokeCap: StrokeCap.round,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                WellBeingColors.lightMaroon, // Progress color
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
                                              '${progress.round()}%', // Display progress as percentage
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
                                    const SizedBox(width: 10), // Space between progress indicator and text
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                                      children: [
                                        Text(
                                          goalName, // Use goal name from Firestore data
                                          style: TextStyle(
                                            color: isDone ? Colors.black : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isDone
                                              ? 'Completed 100%'
                                              : '${(100 - progress).round()}% remaining', // Show remaining progress
                                          style: TextStyle(
                                            color: isDone ? Colors.grey[800]! : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 34), // Adjusted bottom spacing
                            ],
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return const Text("No goals available");
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
            ),
            ],
            ),
          ),
          const Positioned(
            bottom: 5,
            height: 100,
            left: 25,
            right: 25,
            child: BottomNavigationBarWidget(),
          ),
        ],
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {});
  }
}

Widget reportStats(String title, String value) {
  return Column(
    children: [
      Text(
        title,
        style: TextStyle(
          color: WellBeingColors.darkBlueGrey,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: WellBeingColors.mediumGrey,
          fontSize: 13,
        ),
      ),
    ],
  );
}
