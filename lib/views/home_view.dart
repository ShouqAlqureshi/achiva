import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/models.dart' as app_models;
import 'package:achiva/views/addition_views/add_goal_page.dart';
import '../utilities/show_log_out_dialog.dart';
import 'package:achiva/widgets/bottom_navigation_bar.dart';
import 'package:achiva/utilities/colors.dart';
import '../utilities/filestore_services.dart';
import 'package:achiva/models/goal.dart';
import 'package:achiva/views/SearchFriendsScreen.dart'; // Adjust the path as necessary


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageViewController;
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  String? userId;
  String firstName = '';

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user ID
    if (userId != null) {
      _loadUserProfile(userId!);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      app_models.User? userProfile =
          await _firestoreService.getUserProfile(userId);
      if (userProfile != null) {
        setState(() {
          firstName = userProfile.fname; // Set first name
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
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
    PopupMenuButton<MenuAction>(
      onSelected: (value) async {
        if (value == MenuAction.logout) {
          try {
            final shouldLogout = await showLogOutDialog(context);
            if (shouldLogout) {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/phoneauth', (_) => false);
            }
          } on UserNotLoggedInAuthException catch (_) {
            showErrorDialog(context, "User is not logged in");
          }
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Text("Log out"),
          ),
        ];
      },
    ),
  ],
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
                      Text(
                        'Welcome back to Achiva ${firstName}!',
                        style: const TextStyle(
                          color: WellBeingColors.darkBlueGrey,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
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
                    child: StreamBuilder<List<Goal>>(
                      stream: userId != null
                          ? _firestoreService.getUserGoals(userId!)
                          : Stream.value([]),
                      builder: (context, snapshot) {
                        print('User ID: $userId'); // Log the user ID
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          print('Waiting for data...');
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          print('No goals found.');
                          return const Center(child: Text('No Goals Found'));
                        }

                        final goals = snapshot.data!;
                        print('Goals received: ${goals.length}');
                        return PageView.builder(
                          controller: PageController(
                              initialPage: 0, viewportFraction: .85),
                          onPageChanged: _handlePageViewChanged,
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            double progress =
                                20; // Assuming Goal has a progress field
                            final isDone = progress >= 100;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              height: MediaQuery.of(context).size.width / 2,
                              width: ((MediaQuery.of(context).size.width - 40) /
                                      2) -
                                  9,
                              decoration: BoxDecoration(
                                color: progress < 100
                                    ? WellBeingColors.veryDarkMaroon
                                    : Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
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
                                        decoration: const BoxDecoration(
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
                                                child:
                                                    CircularProgressIndicator(
                                                  value: progress / 100,
                                                  strokeWidth: 8,
                                                  backgroundColor: Colors.white,
                                                  strokeCap: StrokeCap.round,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
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
                                                    color: Colors.white
                                                        .withOpacity(0.7),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.name, // Display goal title
                                              style: TextStyle(
                                                color: isDone
                                                    ? Colors.black
                                                    : Colors.white,
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
                                                color: isDone
                                                    ? Colors.grey[800]!
                                                    : Colors.white,
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
                        );
                      },
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
