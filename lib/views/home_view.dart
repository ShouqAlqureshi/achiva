import 'package:achiva/views/friends_feed_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:achiva/widgets/bottom_navigation_bar.dart';
import 'package:achiva/utilities/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0; // Add this line to manage the current index

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

  // Add this method to handle tab selection
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
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
      ),
      body: Stack(
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
                            return const CircularProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return const Text("Error fetching user data");
                          }

                          if (snapshot.hasData && snapshot.data != null) {
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
                                      color: WellBeingColors.mediumGrey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    height: 40,
                                    width: 1.2,
                                  ),
                                  reportStats('13 Tasks', 'This Week'),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: WellBeingColors.mediumGrey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    height: 40,
                                    width: 1.2,
                                  ),
                                  reportStats('56 🚀', 'Streak'),
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
                          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
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
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {});
                                  },
                                  itemCount: goalDocuments.length,
                                  itemBuilder: (context, index) {
                                    final goalData = goalDocuments[index].data() as Map<String, dynamic>;
                                    final String goalName = goalData['name'];
                                    double progress = (index + 1) * 10.0;
                                    final isDone = progress >= 100;

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 15),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      height: MediaQuery.of(context).size.width / 2,
                                      width: ((MediaQuery.of(context).size.width - 40) / 2) - 9,
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
                                                            fontSize: 12,
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
                                                        color: isDone ? Colors.black : Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      isDone
                                                          ? 'Completed 100%'
                                                          : '${(100 - progress).round()}% remaining',
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
                                          const SizedBox(height: 34),
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
          // Positioned(
          //   bottom: 5,
          //   height: 100,
          //   left: 25,
          //   right: 25,
          //   child: BottomNavigationBarWidget(
          //     currentIndex: _currentIndex,
          //     onTabSelected: _onTabSelected,
          //   ),
          // ),
        ],
      ),
    );
  }
}

Widget reportStats(String title, String value) {
  return Column(
    children: [
      Text(
        title,
        style: const TextStyle(
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