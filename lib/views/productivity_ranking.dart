import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:math' as math;

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

      // Batch queries for better performance
      final userDoc = _firestore.collection('Users').doc(currentUser.uid);
      final friendsQuery = userDoc.collection('friends').get();
      
      final friendsSnapshot = await friendsQuery;
      final List<String> userIds = [
        currentUser.uid,
        ...friendsSnapshot.docs.map((doc) => doc['userId'] as String)
      ];

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      List<Map<String, dynamic>> userProductivity = [];

      // Parallel processing for user data
      final futures = userIds.map((userId) => _processUserData(userId, sevenDaysAgo));
      final results = await Future.wait(futures);
      
      userProductivity = results.where((data) => data != null).cast<Map<String, dynamic>>().toList();
      userProductivity.sort((a, b) => b['productivityScore'].compareTo(a['productivityScore']));

      yield userProductivity;
    } catch (e) {
      print('Error fetching productivity rankings: $e');
      yield [];
    }
  }

  Future<Map<String, dynamic>?> _processUserData(String userId, DateTime sevenDaysAgo) async {
    try {
      // Check cache first
      final cachedData = UserDataCache.getCachedUser(userId);
      if (cachedData != null) {
        return cachedData;
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

      // Process all tasks in parallel
      final taskFutures = goalsSnapshot.docs.map((goalDoc) =>
          _processGoalTasks(userId, goalDoc.id, sevenDaysAgo));
      final taskResults = await Future.wait(taskFutures);

      for (final result in taskResults) {
        totalCompletedTasks += result['completed'] as int;
        totalTasks += result['total'] as int;
      }

      final productivityData = {
        'userId': userId,
        'fullName': '${userData['fname'] ?? 'Unknown'} ${userData['lname'] ?? 'User'}',
        'profilePic': userData['photo'] ?? '',
        'completedTasks': totalCompletedTasks,
        'totalGoals': goalsSnapshot.docs.length,
        'totalTasks': totalTasks,
        'productivityScore': _calculateProductivityScore(totalCompletedTasks, totalTasks),
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
    final tasksSnapshot = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .collection('tasks')
        .get();

    final completedTasks = tasksSnapshot.docs.where((task) {
      final taskData = task.data();
      final isCompleted = taskData['completed'] == true;
      if (!isCompleted) return false;

      final completedDate = (taskData['completedDate'] as Timestamp?)?.toDate();
      if (completedDate == null) return false;

      return completedDate.isAfter(sevenDaysAgo);
    }).length;

    final totalTasks = tasksSnapshot.docs.where((task) {
      final taskData = task.data();
      final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
      if (dueDate == null) return false;
      return dueDate.isAfter(sevenDaysAgo);
    }).length;

    return {'completed': completedTasks, 'total': totalTasks};
  }

  int _calculateProductivityScore(int completedTasks, int totalTasks) {
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0;
    return (completedTasks * 20 + completionRate * 100).round();
  }
}

class ProductivityRankingDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> rankings;

  const ProductivityRankingDashboard({
    super.key,
    required this.rankings,
  });

  @override
  Widget build(BuildContext context) {
    final topThree = rankings.take(3).toList();
    final remainingRankings = rankings.skip(3).toList();
// In the ProductivityRankingDashboard widget

    return Container(
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
          // Period selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: PeriodSelector(),
          ),

          // Top 3 podium
          if (topThree.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
    );
  }
}

class PeriodSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _PeriodTab(label: 'Last 7 days', isActive: true), // Updated text
            const SizedBox(width: 8),
          ],
        ),
        IconButton(
          onPressed: () {
            print("Share button pressed");
          },
          icon: Icon(
            Icons.share,
            color: Colors.purple.withOpacity(0.70),
          ),
        ),
      ],
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
      final horizontalSpacing = math.min(8.0, (availableWidth - podiumWidth * 3 - 32) / 2);
      final leftPadding = 16.0;
      
      // Calculate center points for each podium
      final firstPlaceCenter = (availableWidth - 32) / 2;
      final secondPlaceCenter = firstPlaceCenter - podiumWidth - horizontalSpacing;
      final thirdPlaceCenter = firstPlaceCenter + podiumWidth + horizontalSpacing;

      final firstPlaceName = _formatName(topUsers[0]['fullName'] ?? '');
      final firstPlaceFontSize = _calculateFontSize(firstPlaceName, podiumWidth);

      return Container(
        height: 260,
        width: availableWidth,
        child: Stack(
          fit: StackFit.loose,
          clipBehavior: Clip.none,
          children: [
            // Background podium shapes (unchanged)
            Positioned(
              left: leftPadding,
              right: leftPadding,
              bottom: 0,
              child: SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (topUsers.length > 1) ...[
                      Container(
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
                      SizedBox(width: horizontalSpacing),
                    ],

                    Container(
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
                              padding: const EdgeInsets.symmetric(horizontal: 4),
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

                    if (topUsers.length > 2) ...[
                      SizedBox(width: horizontalSpacing),
                      Container(
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
                    ],
                  ],
                ),
              ),
            ),

            // Player photos layer - Updated positioning
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
                        // Updated second place positioning to use secondPlaceCenter
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
                        // Updated third place positioning to use thirdPlaceCenter
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