import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:achiva/utilities/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

class UserDataCache {
  static final Map<String, Map<String, dynamic>> _userCache = {};

  static void cacheUser(String userId, Map<String, dynamic> userData) {
    _userCache[userId] = userData;
  }

  static Map<String, dynamic>? getCachedUser(String userId) {
    return _userCache[userId];
  }

  static void clearCache() {
    _userCache.clear();
  }

  // Add method to remove specific user from cache
  static void invalidateUser(String userId) {
    _userCache.remove(userId);
  }
}

class RankingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> fetchProductivityRankings() async* {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      // Get initial friends list
      final userDoc = _firestore.collection('Users').doc(currentUser.uid);
      final friendsSnapshot = await userDoc.collection('friends').get();
      final List<String> userIds = [
        currentUser.uid,
        ...friendsSnapshot.docs.map((doc) => doc['userId'] as String)
      ];

      // Create a stream that combines updates from all relevant collections
      final Stream<List<Map<String, dynamic>>> rankings = Stream.periodic(
        const Duration(seconds: 1),
        (_) => _fetchLatestRankings(userIds),
      ).asyncMap((future) => future);

      // Listen to task updates for all users
      for (final userId in userIds) {
        _listenToUserTasks(userId);
      }

      await for (final rankingsList in rankings) {
        yield rankingsList;
      }
    } catch (e) {
      print('Error fetching productivity rankings: $e');
      yield [];
    }
  }

  void _listenToUserTasks(String userId) {
    // Set to store shared goal IDs
    final Set<String> sharedGoalIds = {};

    // Listen to all goals collections for the user
    _firestore
        .collection('Users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .listen((goalsSnapshot) {
      // When any goal changes, invalidate the cache for this user
      UserDataCache.invalidateUser(userId);

      // Collect sharedIds from goals
      for (final goalDoc in goalsSnapshot.docs) {
        final sharedId = goalDoc.data()['sharedID'];
        if (sharedId != null && sharedId.isNotEmpty) {
          sharedGoalIds.add(sharedId);
        }
      }

      // Listen to shared goals
      for (final sharedId in sharedGoalIds) {
        _firestore
            .collection('sharedGoal')
            .doc(sharedId)
            .snapshots()
            .listen((sharedGoalDoc) {
          // When shared goal changes, invalidate the cache
          if (sharedGoalDoc.exists) {
            UserDataCache.invalidateUser(userId);

            // Check if tasks collection exists before listening
            _firestore
                .collection('sharedGoal')
                .doc(sharedId)
                .collection('tasks')
                .get()
                .then((tasksCollection) {
              if (tasksCollection.docs.isNotEmpty) {
                // Only set up listener if tasks exist
                _firestore
                    .collection('sharedGoal')
                    .doc(sharedId)
                    .collection('tasks')
                    .snapshots()
                    .listen((sharedTasksSnapshot) {
                  UserDataCache.invalidateUser(userId);
                });
              }
            });
          }
        });
      }
    });

    // Listen to tasks in all goals, checking if tasks collection exists
    _firestore
        .collection('Users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .listen((goalsSnapshot) {
      for (final goalDoc in goalsSnapshot.docs) {
        // Check if tasks collection exists before setting up listener
        _firestore
            .collection('Users')
            .doc(userId)
            .collection('goals')
            .doc(goalDoc.id)
            .collection('tasks')
            .get()
            .then((tasksCollection) {
          if (tasksCollection.docs.isNotEmpty) {
            // Only set up listener if tasks exist
            _firestore
                .collection('Users')
                .doc(userId)
                .collection('goals')
                .doc(goalDoc.id)
                .collection('tasks')
                .snapshots()
                .listen((tasksSnapshot) {
              UserDataCache.invalidateUser(userId);
            });
          }
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchLatestRankings(
      List<String> userIds) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Process all users in parallel
    final futures =
        userIds.map((userId) => _processUserData(userId, sevenDaysAgo));
    final results = await Future.wait(futures);

    final rankings = results
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();

    rankings.sort(
        (a, b) => b['productivityScore'].compareTo(a['productivityScore']));
    return rankings;
  }

  Future<Map<String, dynamic>?> _processUserData(
      String userId, DateTime sevenDaysAgo) async {
    try {
      // Check cache first, but don't return cached data if it's too old
      final cachedData = UserDataCache.getCachedUser(userId);
      if (cachedData != null) {
        final cacheAge = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(
                cachedData['cacheTimestamp'] ?? 0));
        if (cacheAge < const Duration(seconds: 30)) {
          return cachedData;
        }
      }

      final userDoc = await _firestore.collection('Users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      final goalsSnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('goals')
          .get();

      int totalCompletedTasks = 0;
      int totalTasks = 0;

      final taskFutures = goalsSnapshot.docs.map(
          (goalDoc) => _processGoalTasks(userId, goalDoc.id, sevenDaysAgo));
      final taskResults = await Future.wait(taskFutures);

      for (final result in taskResults) {
        totalCompletedTasks += result['completed'] as int;
        totalTasks += result['total'] as int;
      }

      final productivityData = {
        'userId': userId,
        'fullName':
            '${userData['fname'] ?? 'Unknown'} ${userData['lname'] ?? 'User'}',
        'profilePic': userData['photo'] ?? '',
        'completedTasks': totalCompletedTasks,
        'totalGoals': goalsSnapshot.docs.length,
        'totalTasks': totalTasks,
        'productivityScore':
            _calculateProductivityScore(totalCompletedTasks, totalTasks),
        'cacheTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Cache the result
      UserDataCache.cacheUser(userId, productivityData);
      return productivityData;
    } catch (e) {
      print('Error processing user $userId: $e');
      return null;
    }
  }

  Future<Map<String, int>> _processGoalTasks(
      String userId, String goalId, DateTime sevenDaysAgo) async {
    List<QueryDocumentSnapshot> allTasks = [];

    // Fetch the specific goal document
    final goalDoc = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .get();

    // Check if goal exists and get its data
    final Map<String, dynamic>? goalData = goalDoc.data();
    if (goalData == null) {
      return {'completed': 0, 'total': 0};
    }

    // Check for sharedId
    final String? sharedId = goalData['sharedID'] as String?;

    // Fetch personal tasks for the specific goal
    try {
      final tasksSnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .collection('tasks')
          .get();

      if (tasksSnapshot.docs.isNotEmpty) {
        allTasks.addAll(tasksSnapshot.docs);
      }
    } catch (e) {
      print('Error fetching personal tasks for goal: $goalId');
    }

    // If there's a sharedId, fetch shared tasks
    if (sharedId != null && sharedId.isNotEmpty) {
      try {
        final sharedTasksSnapshot = await _firestore
            .collection('sharedGoal')
            .doc(sharedId)
            .collection('tasks')
            .get();

        if (sharedTasksSnapshot.docs.isNotEmpty) {
          allTasks.addAll(sharedTasksSnapshot.docs);
        }
      } catch (e) {
        print('Error fetching shared tasks for sharedId: $sharedId');
      }
    }

    // Process completed tasks
    final completedTasks = allTasks.where((task) {
      final Map<String, dynamic>? taskData =
          task.data() as Map<String, dynamic>?;

      // Safely check completion status
      final bool? isCompleted = taskData?['completed'] as bool?;
      if (isCompleted != true) return false;

      // Safely check completed date
      final Timestamp? completedTimestamp =
          taskData?['completedDate'] as Timestamp?;
      final DateTime? completedDate = completedTimestamp?.toDate();
      if (completedDate == null) return false;

      return completedDate.isAfter(sevenDaysAgo);
    }).length;

    // Process total tasks due within 7 days
    final totalTasks = allTasks.where((task) {
      final Map<String, dynamic>? taskData =
          task.data() as Map<String, dynamic>?;

      // Safely check due date
      final Timestamp? dueTimestamp = taskData?['dueDate'] as Timestamp?;
      final DateTime? dueDate = dueTimestamp?.toDate();
      if (dueDate == null) return false;

      return dueDate.isAfter(sevenDaysAgo);
    }).length;

    return {
      'completed': completedTasks,
      'total': totalTasks,
    };
  }

  int _calculateProductivityScore(int completedTasks, int totalTasks) {
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0;
    return (completedTasks * 20 + completionRate * 100).round();
  }
}

class ProductivityRankingDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> rankings;

  const ProductivityRankingDashboard({
    super.key,
    required this.rankings,
  });

  @override
  State<ProductivityRankingDashboard> createState() =>
      _ProductivityRankingDashboardState();
}

class _ProductivityRankingDashboardState
    extends State<ProductivityRankingDashboard> {
  // Create a GlobalKey for capturing the widget
  final GlobalKey _boundaryKey = GlobalKey();
  bool _shareIsLoading = false;

// Function to capture the widget as an image
  Future<Uint8List?> _captureWidget() async {
    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture the widget as an image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Create a new image with a gradient background
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Define the gradient
      final Rect rect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final Gradient gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color.fromARGB(255, 30, 12, 48),
          Color.fromARGB(255, 59, 38, 91),
        ],
      );

      // Apply the gradient as a shader to the paint
      final Paint paint = Paint()..shader = gradient.createShader(rect);

      // Draw the gradient background
      canvas.drawRect(rect, paint);

      // Draw the captured widget image on top of the gradient background
      canvas.drawImage(image, Offset.zero, Paint());

      // Convert the final image to bytes
      final ui.Image finalImage = await recorder.endRecording().toImage(
            image.width,
            image.height,
          );
      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final Uint8List? pngBytes = byteData?.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      log('Error capturing widget: $e');
      return null;
    }
  }

// Function to handle the screenshot and sharing process
  Future<void> _captureAndShowPreview() async {
    // Wait for the widget to fully render
    await Future.delayed(Duration(milliseconds: 200)); // Adjust as needed
    showLoadingDialog(context);
    try {
      final Uint8List? imageBytes = await _captureWidget();

      if (imageBytes != null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss loading dialog
        // Show preview dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Color(0xFF241c2e),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        child: Image.memory(imageBytes),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              setState(() {
                                _shareIsLoading = true;
                              });
                              try {
                                // Get temporary directory to save the file temporarily
                                final tempDir = await getTemporaryDirectory();
                                final tempPath =
                                    '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

                                // Save the image temporarily
                                final File tempFile = File(tempPath);
                                await tempFile.writeAsBytes(imageBytes);

                                // Share the image
                                await Share.shareXFiles(
                                  [XFile(tempPath)],
                                  text: 'Check out my productivity ranking!',
                                );

                                // Delete the temporary file
                                if (await tempFile.exists()) {
                                  await tempFile.delete();
                                }

                                // Close the dialog after sharing
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                log('Error sharing image: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to share image'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _shareIsLoading = false;
                                });
                              }
                            },
                            child: _shareIsLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : Text('Share Image'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      log('Error capturing screenshot: $e');
      setState(() {
        Navigator.of(context).pop(); // Stop loading
        _shareIsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture screenshot'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topThree = widget.rankings.take(3).toList();
    final remainingRankings = widget.rankings.skip(3).toList();

    return RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Period selector with modified share button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _PeriodTab(label: 'Last 7 days', isActive: true),
                      const SizedBox(width: 8),
                    ],
                  ),
                  IconButton(
                    onPressed: _captureAndShowPreview,
                    icon: Icon(
                      Icons.share,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Rest of the widget remains the same...
            if (topThree.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: TopThreePodium(topUsers: topThree),
              ),

            // Remaining rankings
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  ...remainingRankings.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RankingListItem(
                        user: entry.value,
                        position: entry.key + 4,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PeriodTab({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.purple.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.purple[200] : Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}

class TopThreePodium extends StatelessWidget {
  final List<Map<String, dynamic>> topUsers;

  const TopThreePodium({
    super.key,
    required this.topUsers,
  });

  String _formatName(String fullName) {
    final nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0]} .${nameParts[1][0]}';
    }
    return fullName;
  }

  double _calculateFontSize(String name, double containerWidth) {
    double baseFontSize = 24;
    int baseCharCount = 8;

    if (name.length > baseCharCount) {
      double ratio = baseCharCount / name.length;
      return math.max(16.0, baseFontSize * ratio);
    }

    return baseFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final podiumWidth = math.min(100.0, (availableWidth - 32 - 16) / 3);
      final horizontalSpacing =
          math.min(8.0, (availableWidth - podiumWidth * 3 - 32) / 2);
      final leftPadding = 16.0;

      // Calculate fixed center points regardless of number of podiums
      final firstPlaceCenter = (availableWidth - 32) / 2;
      final secondPlaceCenter =
          firstPlaceCenter - podiumWidth - horizontalSpacing;
      final thirdPlaceCenter =
          firstPlaceCenter + podiumWidth + horizontalSpacing;

      final firstPlaceName = _formatName(topUsers[0]['fullName'] ?? '');
      final firstPlaceFontSize =
          _calculateFontSize(firstPlaceName, podiumWidth);

      return Container(
        height: 260,
        width: availableWidth,
        child: Stack(
          fit: StackFit.loose,
          clipBehavior: Clip.none,
          children: [
            // Background podium shapes
            Positioned(
              left: leftPadding,
              right: leftPadding,
              bottom: 0,
              child: SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Second place podium - Always shown if there's a second place
                    if (topUsers.length > 1)
                      Positioned(
                        left: secondPlaceCenter - podiumWidth / 2,
                        bottom: 0,
                        child: Container(
                          width: podiumWidth,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.15),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: Colors.pink.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatName(topUsers[1]['fullName'] ?? ''),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topUsers[1]['productivityScore']}${topUsers[1]['productivityScore'] == 0 ? '😢' : '🦾'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // First place podium - Always centered
                    Positioned(
                      left: firstPlaceCenter - podiumWidth / 2,
                      bottom: 0,
                      child: Container(
                        width: podiumWidth,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: podiumWidth,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    firstPlaceName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: firstPlaceFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${topUsers[0]['productivityScore']}${topUsers[0]['productivityScore'] == 0 ? '😢' : '🚀'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Third place podium - Only shown if there's a third place
                    if (topUsers.length > 2)
                      Positioned(
                        left: thirdPlaceCenter - podiumWidth / 2,
                        bottom: 0,
                        child: Container(
                          width: podiumWidth,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatName(topUsers[2]['fullName'] ?? ''),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topUsers[2]['productivityScore']}${topUsers[2]['productivityScore'] == 0 ? '😢' : '💨'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Player photos layer
            Positioned(
              left: leftPadding,
              right: leftPadding,
              bottom: 0,
              child: SizedBox(
                height: 260,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (topUsers.length > 1)
                      Positioned(
                        left: secondPlaceCenter - 35,
                        bottom: 140,
                        child: PlayerPhoto(user: topUsers[1], position: 2),
                      ),
                    Positioned(
                      left: firstPlaceCenter - 35,
                      bottom: 180,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: PlayerPhoto(user: topUsers[0], position: 1),
                          ),
                          const Positioned(
                            top: -45,
                            child: Text(
                              '👑',
                              style: TextStyle(
                                fontSize: 50,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (topUsers.length > 2)
                      Positioned(
                        left: thirdPlaceCenter - 35,
                        bottom: 100,
                        child: PlayerPhoto(user: topUsers[2], position: 3),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class PlayerPhoto extends StatelessWidget {
  final Map<String, dynamic> user;
  final int position;

  const PlayerPhoto({
    super.key,
    required this.user,
    required this.position,
  });

  String _getOrdinalNumber(int number) {
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }

  Color _getPositionColor() {
    switch (position) {
      case 1:
        return Colors.purple;
      case 2:
        return Colors.pink;
      case 3:
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionColor = _getPositionColor();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: positionColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: user['profilePic']?.isNotEmpty == true
                ? Image.network(
                    user['profilePic'],
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: positionColor.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        user['fullName'][0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            color: positionColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: positionColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              _getOrdinalNumber(position),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PodiumCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int position;
  final bool isWinner;
  final double scale;

  const PodiumCard({
    super.key,
    required this.user,
    required this.position,
    this.isWinner = false,
    this.scale = 1.0,
  });

  String _getOrdinalNumber(int number) {
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }

  Color _getScoreColor() {
    switch (position) {
      case 1:
        return Colors.purple;
      case 2:
        return Colors.pink;
      case 3:
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  String _getFirstName() {
    final fullName = user['fullName'] as String;
    return fullName.split(' ')[0];
  }

  String _getEmoji() {
    final score = user['productivityScore'] as int;
    if (score == 0) return '😢';

    switch (position) {
      case 1:
        return '🚀';
      case 2:
        return '🦾';
      case 3:
        return '💨';
      default:
        return '⏫';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user['profilePic']?.isNotEmpty == true
                      ? Image.network(
                          user['profilePic'],
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.purple.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              _getFirstName()[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getOrdinalNumber(position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getFirstName(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${user['productivityScore']}${_getEmoji()}',
            style: TextStyle(
              color: _getScoreColor(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RankingListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int position;

  const RankingListItem({
    super.key,
    required this.user,
    required this.position,
  });

  String _getOrdinalNumber(int number) {
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }

  String _getEmoji() {
    final score = user['productivityScore'] as int;
    if (score == 0) return '😢';

    switch (position) {
      case 1:
        return '🚀';
      case 2:
        return '🦾';
      case 3:
        return '💨';
      default:
        return '⏫';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  _getOrdinalNumber(position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: user['profilePic']?.isNotEmpty == true
                      ? Image.network(
                          user['profilePic'],
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            user['fullName'][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              user['fullName'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Text(
                          '${user['productivityScore']}${_getEmoji()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
