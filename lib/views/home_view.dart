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
import 'dart:async';


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
  CountdownManager().dispose();
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
   Stream<Map<String, dynamic>> getGoalWithProgress(DocumentSnapshot goalDocument) {
    final goalId = goalDocument.id;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Stream of tasks for the goal
    final tasksStream = FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .collection('tasks')
        .snapshots();

    // Transform the stream to include progress calculation
    return tasksStream.map((tasksSnapshot) {
      if (tasksSnapshot.docs.isEmpty) {
        return {
          'progress': 0.0,
          'goalDocument': goalDocument,
        };
      }

      int completedTasks = tasksSnapshot.docs
          .where((task) => (task.data() as Map<String, dynamic>)['completed'] == true)
          .length;

      double progress = (completedTasks / tasksSnapshot.docs.length) * 100;

      return {
        'progress': progress.roundToDouble(),
        'goalDocument': goalDocument,
      };
    });
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
                                    const SizedBox(height: 5),
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
                          final goalData = goalDocument.data() as Map<String, dynamic>;
                          final String goalName = goalData['name'];

                          return StreamBuilder<Map<String, dynamic>>(
          stream: getGoalWithProgress(goalDocument),
                            builder: (context, progressSnapshot) {
                              if (progressSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
if (!progressSnapshot.hasData) {
              return const Center(child: Text('Error loading progress'));
            }

            double progress = progressSnapshot.data!['progress'];
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

Widget _buildGoalCard(String goalName, double progress, bool isDone, DocumentSnapshot goalDocument) {
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
      margin: const EdgeInsets.only(left: 15, right: 15, top: 30, bottom: 150),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 66, 32, 101),
            Color.fromARGB(255, 77, 64, 98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDone) ...[
            _buildCompletedGoalContent(goalName)
          ] else ...[
            _buildInProgressGoalContent(goalName, progress, goalDocument)
          ],
        ],
      ),
    ),
  );
}

Widget _buildCompletedGoalContent(String goalName) {
  return Row(
    children: [
      _buildProgressCircle(1.0, Colors.green, Icons.check),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goalName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Done!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildInProgressGoalContent(String goalName, double progress, DocumentSnapshot goalDocument) {
  return Row(
    children: [
      _buildProgressCircle(progress / 100, WellBeingColors.lightMaroon, null, progress),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goalName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              progress == 0 ? 'Not started yet' : 'In progress',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: StreamBuilder<String>(
          stream: CountdownManager().getCountdownStream(goalDocument),
          initialData: '',
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                snapshot.data!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildProgressCircle(double progress, Color color, IconData? icon, [double? percentage]) {
  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        height: 45,
        width: 45,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 5,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      icon != null
          ? Icon(
              icon,
              color: Colors.white,
              size: 20,
            )
          : Text(
              '${percentage?.round()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    ],
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
class CountdownManager {
  static final CountdownManager _instance = CountdownManager._internal();
  factory CountdownManager() => _instance;
  CountdownManager._internal();

  final Map<String, StreamController<String>> _controllers = {};
  final Map<String, Timer> _timers = {};

  void dispose() {
    _controllers.forEach((_, controller) => controller.close());
    _timers.forEach((_, timer) => timer.cancel());
    _controllers.clear();
    _timers.clear();
  }

  Stream<String> getCountdownStream(DocumentSnapshot goalDocument) {
    final String goalId = goalDocument.id;
    
    if (!_controllers.containsKey(goalId)) {
      _controllers[goalId] = StreamController<String>.broadcast();
      _startCountdown(goalDocument);
    }
    
    return _controllers[goalId]!.stream;
  }

  void _startCountdown(DocumentSnapshot goalDocument) {
    final String goalId = goalDocument.id;
    final goalData = goalDocument.data() as Map<String, dynamic>;
    
    if (!goalData.containsKey('date')) {
      _controllers[goalId]?.add('');
      return;
    }

    DateTime? dueDate = _parseDate(goalData['date']);
    if (dueDate == null) {
      _controllers[goalId]?.add('');
      return;
    }

    // Initial update
    _updateCountdown(goalId, dueDate);

    // Set up periodic updates
    _timers[goalId] = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(goalId, dueDate!);
    });
  }

  DateTime? _parseDate(dynamic dateField) {
    try {
      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is String) {
        return DateTime.parse(dateField);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  void _updateCountdown(String goalId, DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    String countdownText;
    if (difference.isNegative) {
      countdownText = 'Overdue';
    } else if (difference.inDays ==1) {
      countdownText = '${difference.inDays} day left';
    } else if (difference.inDays > 0) {
      countdownText = '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      countdownText = '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      countdownText = '${difference.inMinutes} minutes left';
    } else if (difference.inSeconds > 0) {
      countdownText = '${difference.inSeconds} seconds left';
    } else {
      countdownText = 'Due now';
    }

    _controllers[goalId]?.add(countdownText);
  }

  void cancelCountdown(String goalId) {
    _timers[goalId]?.cancel();
    _timers.remove(goalId);
    _controllers[goalId]?.close();
    _controllers.remove(goalId);
  }
}