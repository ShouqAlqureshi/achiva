import 'dart:async';
import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/models/goal.dart';
import 'package:achiva/utilities/colors.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:achiva/views/SearchFriendsScreen.dart';
import 'package:achiva/views/activity/activity.dart';
import 'package:achiva/views/activity/incoming_request_view.dart';
import 'package:achiva/views/edit_goal_page.dart';
import 'package:achiva/views/FriendsFeed/friends_feed_page.dart';
import 'package:achiva/views/home_view.dart';
import 'package:achiva/views/profile/profile_screen.dart';
import 'package:achiva/widgets/bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../utilities/filestore_services.dart';
import '../utilities/show_log_out_dialog.dart';
import 'GoalTasks.dart';
import 'dart:async';
import 'ChatPage.dart';
import 'package:rxdart/rxdart.dart';

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
    Gemini.init(apiKey: 'AIzaSyBqMMBMeDZaq-ju7BKiPRcFOpzvIBrMEJs');
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatPage(),
      ),
    );
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

  Stream<Map<String, dynamic>> getGoalWithProgress(
    DocumentSnapshot goalDocument) {
  final goalData = goalDocument.data() as Map<String, dynamic>;
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final bool isSharedGoal = 
      goalData.containsKey('isShared') && goalData['isShared'] == true;

  // Stream for tasks depends on whether it's a shared or personal goal
  Stream<QuerySnapshot> tasksStream;

  if (isSharedGoal) {
    final sharedId = goalData['sharedID'] as String?;
    if (sharedId == null) {
      return Stream.value({
        'progress': 0.0,
        'goalDocument': goalDocument,
      });
    }

    // For shared goals, get tasks from sharedGoal collection
    tasksStream = FirebaseFirestore.instance
        .collection('sharedGoal')
        .doc(sharedId)
        .collection('tasks')
        .snapshots();
  } else {
    // For personal goals, get tasks from user's goals collection
    tasksStream = FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection('goals')
        .doc(goalDocument.id)
        .collection('tasks')
        .snapshots();
  }

  // Transform the stream to include progress calculation
  return tasksStream.map((tasksSnapshot) {
    if (tasksSnapshot.docs.isEmpty) {
      return {
        'progress': 0.0,
        'goalDocument': goalDocument,
      };
    }

    int completedTasks = tasksSnapshot.docs
        .where((task) =>
            (task.data() as Map<String, dynamic>)['completed'] == true)
        .length;

    double progress = (completedTasks / tasksSnapshot.docs.length) * 100;

    return {
      'progress': progress.roundToDouble(),
      'goalDocument': goalDocument,
    };
  });
}

  Stream<int> getCompletedTodayTasksCount() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Listen to all goals
    return FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection('goals')
        .snapshots()
        .switchMap((goalSnapshots) {
      // Create a stream for each goal's tasks
      final taskStreams = goalSnapshots.docs.map((goalDoc) {
        final goalData = goalDoc.data();
        final sharedId = goalData['sharedID'] as String?;

        // Streams for both personal and shared tasks
        final List<Stream<int>> combinedTaskStreams = [
          // Personal tasks stream
          goalDoc.reference
              .collection('tasks')
              .where('completed', isEqualTo: true)
              .snapshots()
              .map((taskSnapshot) {
            return taskSnapshot.docs.where((task) {
              final completedDate =
                  (task.data()['completedDate'] as Timestamp?)?.toDate();
              if (completedDate == null) return false;

              return completedDate.isAfter(today) &&
                  completedDate.isBefore(tomorrow);
            }).length;
          }),
        ];

        // Add shared tasks stream if sharedId exists
        if (sharedId != null && sharedId.isNotEmpty) {
          final sharedTaskStream = FirebaseFirestore.instance
              .collection('sharedGoal')
              .doc(sharedId)
              .collection('tasks')
              .where('completed', isEqualTo: true)
              .snapshots()
              .map((taskSnapshot) {
            return taskSnapshot.docs.where((task) {
              final completedDate =
                  (task.data()['completedDate'] as Timestamp?)?.toDate();
              if (completedDate == null) return false;

              return completedDate.isAfter(today) &&
                  completedDate.isBefore(tomorrow);
            }).length;
          });

          combinedTaskStreams.add(sharedTaskStream);
        }

        // Combine personal and shared task streams
        return Rx.combineLatest(combinedTaskStreams, (List<int> counts) {
          return counts.reduce((sum, count) => sum + count);
        });
      });

      // If there are no goals, return a stream of 0
      if (taskStreams.isEmpty) {
        return Stream.value(0);
      }

      // Combine all goal task streams
      return Rx.combineLatest(taskStreams, (List<int> counts) {
        return counts.reduce((sum, count) => sum + count);
      });
    });
  }

  Stream<int> getCompletedWeekTasksCount() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));

    // Listen to all goals
    return FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection('goals')
        .snapshots()
        .switchMap((goalSnapshots) {
      // Create a stream for each goal's tasks
      final taskStreams = goalSnapshots.docs.map((goalDoc) {
        final goalData = goalDoc.data();
        final sharedId = goalData['sharedID'] as String?;

        // Streams for both personal and shared tasks
        final List<Stream<int>> combinedTaskStreams = [
          // Personal tasks stream
          goalDoc.reference
              .collection('tasks')
              .where('completed', isEqualTo: true)
              .snapshots()
              .map((taskSnapshot) {
            return taskSnapshot.docs.where((task) {
              final completedDate =
                  (task.data()['completedDate'] as Timestamp?)?.toDate();
              if (completedDate == null) return false;

              return completedDate.isAfter(startDate) &&
                  completedDate.isBefore(endDate);
            }).length;
          }),
        ];

        // Add shared tasks stream if sharedId exists
        if (sharedId != null && sharedId.isNotEmpty) {
          final sharedTaskStream = FirebaseFirestore.instance
              .collection('sharedGoal')
              .doc(sharedId)
              .collection('tasks')
              .where('completed', isEqualTo: true)
              .snapshots()
              .map((taskSnapshot) {
            return taskSnapshot.docs.where((task) {
              final completedDate =
                  (task.data()['completedDate'] as Timestamp?)?.toDate();
              if (completedDate == null) return false;

              return completedDate.isAfter(startDate) &&
                  completedDate.isBefore(endDate);
            }).length;
          });

          combinedTaskStreams.add(sharedTaskStream);
        }

        // Combine personal and shared task streams
        return Rx.combineLatest(combinedTaskStreams, (List<int> counts) {
          return counts.reduce((sum, count) => sum + count);
        });
      });

      // If there are no goals, return a stream of 0
      if (taskStreams.isEmpty) {
        return Stream.value(0);
      }

      // Combine all goal task streams
      return Rx.combineLatest(taskStreams, (List<int> counts) {
        return counts.reduce((sum, count) => sum + count);
      });
    });
  }
   void _onGoalEdited() {
    // Force refresh of countdown timers
    setState(() {
      // Clear existing countdown timers
      CountdownManager().clearAll();
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
              leadingWidth: 120, // Make space for wider button
              leading: Container(
                margin:
                    const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 30, 12, 48),
                      Color.fromARGB(255, 77, 64, 98),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatPage(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
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
                                            StreamBuilder<int>(
                                              stream:
                                                  getCompletedTodayTasksCount(),
                                              builder: (context, snapshot) {
                                                final count =
                                                    snapshot.data ?? 0;
                                                return reportStats(
                                                    '$count Tasks', 'Today');
                                              },
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: WellBeingColors
                                                    .mediumGrey
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              height: 40,
                                              width: 1.2,
                                            ),
                                            StreamBuilder<int>(
                                              stream:
                                                  getCompletedWeekTasksCount(),
                                              builder: (context, snapshot) {
                                                final count =
                                                    snapshot.data ?? 0;
                                                return reportStats(
                                                    '$count Tasks',
                                                    'This Week');
                                              },
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: WellBeingColors
                                                    .mediumGrey
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              height: 40,
                                              width: 1.2,
                                            ),
                                            reportStats(
                                                "${userData["streak"]}" +
                                                    (userData["streak"] != 0
                                                        ? ' 🔥'
                                                        : ''),
                                                'Streak')
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
                            return FutureBuilder<DocumentSnapshot>(
                              future: getGoalDocument(snapshot.data!.docs[
                                  index]), //filters which type of goal it is (shared or regular)
                              builder: (context,
                                  AsyncSnapshot<DocumentSnapshot>
                                      goalSnapshot) {
                                if (goalSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (goalSnapshot.hasError) {
                                  return const Text(
                                      "Error fetching goal details");
                                }

                                if (!goalSnapshot.hasData) {
                                  return const Text("No goal data available");
                                }

                                // Assign the final document based on the function result
                                final goalDocument = goalSnapshot.data!;
                                final goalData =
                                    goalDocument.data() as Map<String, dynamic>;
                                return FutureBuilder<String>(
                                  future: _getGoalName(goalData),
                                  builder: (context, nameSnapshot) {
                                    if (nameSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (nameSnapshot.hasError) {
                                      return const Text(
                                          "Error fetching goal name");
                                    }

                                    final goalName =
                                        nameSnapshot.data ?? "Unnamed Goal";
                                    final visible = goalData['visibility'];
                                    DateTime date =
                                        DateTime.parse(goalData['date']);

                                    return StreamBuilder<Map<String, dynamic>>(
                                      stream: getGoalWithProgress(goalDocument),
                                      builder: (context, progressSnapshot) {
                                        if (progressSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                        if (!progressSnapshot.hasData) {
                                          return const Center(
                                              child: Text(
                                                  'Error loading progress'));
                                        }

                                        double progress =
                                            progressSnapshot.data!['progress'];
                                        final isDone = progress >= 100;

                                        return _buildGoalCard(
                                            goalName,
                                            progress,
                                            isDone,
                                            goalDocument,
                                            date,
                                            visible);
                                      },
                                    );
                                  },
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

  Future<QueryDocumentSnapshot<Object?>> getGoalDocument(
      QueryDocumentSnapshot originalDocument) async {
    // // If the goal has a sharedId, fetch from sharedGoal collection
    // if (goalData.containsKey('sharedId') && goalData['sharedId'] != null) {
    //   final sharedDocSnapshot = await FirebaseFirestore.instance
    //       .collection('sharedGoal')
    //       .where(FieldPath.documentId, isEqualTo: goalData['sharedId'])
    //       .limit(1)
    //       .get();

    //   if (sharedDocSnapshot.docs.isNotEmpty) {
    //     return sharedDocSnapshot.docs.first;
    //   }
    // }

    // Otherwise return the original document
    return originalDocument;
  }

  Widget _buildGoalCard(
    String goalName,
    double progress,
    bool isDone,
    DocumentSnapshot goalDocument,
    DateTime goalDate,
    bool visibl,
  ) {
    final goalData = goalDocument.data() as Map<String, dynamic>;
    final bool isSharedGoal =
        goalData.containsKey('isShared') && goalData['isShared'] == true;

    return GestureDetector(
      onTap: () async {
        // Handle navigation for both shared and regular goals
        if (isSharedGoal) {
          String? sharedID = goalData['sharedID'] as String?;
          if (sharedID != null) {
            DocumentSnapshot sharedGoalDoc = await FirebaseFirestore.instance
                .collection('sharedGoal')
                .doc(sharedID)
                .get();

            if (sharedGoalDoc.exists) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalTasks(goalDocument: sharedGoalDoc),
                ),
              );
            } else {
              // Navigate to the original goal if shared goal is not found
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalTasks(goalDocument: goalDocument),
                ),
              );
            }
          }
        } else {
          // Handle regular (non-shared) goals
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalTasks(goalDocument: goalDocument),
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(
                left: 15, right: 15, top: 30, bottom: 150),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 30, 12, 48),
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
                if (isSharedGoal) ...[
                  FutureBuilder<DocumentSnapshot>(
                    future: _getSharedGoalDocument(goalDocument),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('Shared goal not found');
                      }

                      return _buildEditDeleteButtons(
                        snapshot.data!.reference,
                        goalDate,
                        goalName,
                        visibl,
                        onEdit: _onGoalEdited, // Add onEdit callback
                      );
                    },
                  ),
                ] else ...[
                  _buildEditDeleteButtons(
                    goalDocument.reference,
                    goalDate,
                    goalName,
                    visibl,
                    onEdit: _onGoalEdited, // Add onEdit callback
                  ),
                ],
                if (isDone) ...[
                  _buildCompletedGoalContent(goalName),
                ] else ...[
                  _buildInProgressGoalContent(goalName, progress, goalDocument),
                ],
              ],
            ),
          ),
          if (isSharedGoal)
            Positioned(
              top: 220,
              right: 40,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 18, 89, 147).withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<DocumentSnapshot> _getSharedGoalDocument(
      DocumentSnapshot goalDoc) async {
    final goalData = goalDoc.data() as Map<String, dynamic>;
    final sharedID = goalData['sharedID'] as String?;
    if (sharedID != null) {
      return await FirebaseFirestore.instance
          .collection('sharedGoal')
          .doc(sharedID)
          .get();
    }
    throw Exception('Shared ID is missing.');
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Method return widget for edit and delete goal
 Widget _buildEditDeleteButtons(
    DocumentReference goalRef,
    DateTime goalDate,
    String goalName,
    bool visible, {
    required VoidCallback onEdit,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.transparent,
            elevation: 0,
          ),
        ),
        child: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          position: PopupMenuPosition.under,
          offset: const Offset(10, 10),
          itemBuilder: (context) => [
            PopupMenuItem(
              padding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 105, 105, 105),
                      Color.fromARGB(255, 72, 72, 72),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text(
                    'Edit Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Future.delayed(
                  const Duration(seconds: 0),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGoalPage(
                        goalRef: goalRef,
                        goalDate: goalDate,
                        goalName: goalName,
                        visibility: visible,
                      ),
                    ),
                  ).then((_) => onEdit()), // Call onEdit callback after navigation
                );
              },
            ),
            PopupMenuItem(
              padding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 198, 137, 137),
                      Color.fromARGB(255, 219, 110, 115),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.white),
                  title: const Text(
                    'Delete Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Future.delayed(
                  const Duration(seconds: 0),
                  () => _deleteGoal(context, goalRef),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(
      BuildContext context, DocumentReference goalRef) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Delete Goal',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this goal? This action cannot be undone.',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  // Get the goal document data
                  final goalDoc = await goalRef.get();
                  final goalData = goalDoc.data() as Map<String, dynamic>?;

                  if (goalData == null) {
                    throw 'Goal data not found';
                  }

                  // Check if sharedID exists
                  final String? sharedID = goalData['sharedID'];
                  if (sharedID == null) {
                    // If no sharedID, delete the goal and its subcollection tasks
                    await _firestore
                        .runTransaction((Transaction myTransaction) async {
                      // Delete the main goal
                      myTransaction.delete(goalRef);

                      // Reference to the tasks subcollection
                      final tasksRef = goalRef.collection('tasks');

                      // Get all tasks in the subcollection
                      final tasksSnapshot = await tasksRef.get();

                      // Delete each task document
                      for (var taskDoc in tasksSnapshot.docs) {
                        myTransaction.delete(taskDoc.reference);
                      }
                    });
                  } else {
                    // Get participants map
                    final Map<String, dynamic>? participants =
                        goalData['participants'] as Map<String, dynamic>?;

                    if (participants == null) {
                      throw 'Participants data not found';
                    }

                    // Start a transaction for atomic operations
                    await _firestore
                        .runTransaction((Transaction myTransaction) async {
                      // Delete the main goal first
                      myTransaction.delete(goalRef);

                      // Reference to the tasks subcollection
                      final tasksRef = goalRef.collection('tasks');

                      // Get all tasks in the subcollection
                      final tasksSnapshot = await tasksRef.get();

                      // Delete each task document
                      for (var taskDoc in tasksSnapshot.docs) {
                        myTransaction.delete(taskDoc.reference);
                      }
                      // Reference to the invite subcollection
                      final invitesRef = goalRef.collection('goalInvitations');

                      // Get all invite in the subcollection
                      final invitesSnapshot = await invitesRef.get();

                      // Delete each invite document
                      for (var inviteDoc in invitesSnapshot.docs) {
                        myTransaction.delete(inviteDoc.reference);
                      }
                      // Process each participant
                      for (String userId in participants.keys) {
                        // Reference to the user's goals subcollection
                        final userGoalsRef = _firestore
                            .collection('Users')
                            .doc(userId)
                            .collection('goals');

                        // Query for goals with matching sharedID
                        final querySnapshot = await userGoalsRef
                            .where('sharedID', isEqualTo: sharedID)
                            .get();

                        // Delete each matching goal document
                        for (var doc in querySnapshot.docs) {
                          myTransaction.delete(doc.reference);
                        }
                      }
                    });
                  }

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal deleted successfully')),
                  );

                  // Close the dialog
                  Navigator.of(context).pop();
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting goal: $e')),
                  );
                  // Close the dialog even if there's an error
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

  Widget _buildInProgressGoalContent(
      String goalName, double progress, DocumentSnapshot goalDocument) {
    return Stack(
      children: [
        // Main content of the card
        Row(
          children: [
            _buildProgressCircle(
                progress / 100, WellBeingColors.lightMaroon, null, progress),
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
          ],
        ),
        // Countdown at the bottom right
        Positioned(
          right: 8.0,
          bottom: 8.0,
          child: StreamBuilder<String>(
            stream: CountdownManager().getCountdownStream(goalDocument),
            initialData: '',
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const SizedBox.shrink();
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

  Widget _buildProgressCircle(double progress, Color color, IconData? icon,
      [double? percentage]) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        icon != null
            ? Icon(
                icon,
                color: Colors.white,
                size: 22,
              )
            : Text(
                '${percentage?.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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

  Future<DocumentSnapshot> _getGoalDocument(
      QueryDocumentSnapshot originalDocument) async {
    try {
      final goalData = originalDocument.data() as Map<String, dynamic>;

      // If the goal has a sharedID, fetch from sharedGoal collection
      if (goalData.containsKey('sharedID') && goalData['sharedID'] != null) {
        final sharedDoc = await FirebaseFirestore.instance
            .collection('sharedGoal')
            .doc(goalData['sharedID'])
            .get();

        if (sharedDoc.exists) {
          return sharedDoc;
        }
      }
      // Return the original document if not shared or shared document not found
      return originalDocument;
    } catch (e) {
      print('Error in getGoalDocument: $e');
      return originalDocument;
    }
  }
}

Future<String> _getGoalName(Map<String, dynamic> goalData) async {
  try {
    if (goalData.containsKey('sharedID') && goalData['sharedID'] != null) {
      // Fetch shared goal document
      final sharedDoc = await FirebaseFirestore.instance
          .collection('sharedGoal')
          .doc(goalData['sharedID'])
          .get();

      if (sharedDoc.exists) {
        final sharedData = sharedDoc.data();
        return sharedData?['name'] ?? 'Unnamed Shared Goal';
      }
      return 'Shared Goal Not Found';
    }
    // Return regular goal name
    return goalData['name'] ?? 'Unnamed Goal';
  } catch (e) {
    print('Error fetching goal name: $e');
    return 'Error Loading Goal Name';
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
    } else if (difference.inDays == 1) {
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
   void clearAll() {
    // Cancel and clear all existing timers and controllers
    _controllers.forEach((_, controller) => controller.close());
    _timers.forEach((_, timer) => timer.cancel());
    _controllers.clear();
    _timers.clear();
  }
}
