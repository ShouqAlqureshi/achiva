import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';  // For ImageFilter

class RankingsService {
  Stream<List<Map<String, dynamic>>> fetchProductivityRankings() async* {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      // Fetch friends list
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      List<String> userIds =
          friendsSnapshot.docs.map((doc) => doc['userId'] as String).toList();
      userIds.add(currentUser.uid);

      List<Map<String, dynamic>> userProductivity = [];
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (String userId in userIds) {
        try {
          // First get all goals
          QuerySnapshot goalsSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('goals')
              .get();

          int totalCompletedTasks = 0;
          int totalTasks = 0;

          // For each goal, get its tasks
          for (var goalDoc in goalsSnapshot.docs) {
            QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection('goals')
                .doc(goalDoc.id)
                .collection('tasks')
                .get();

            // Count completed tasks within last 30 days with null-safe checks
            int completedTasksForGoal = tasksSnapshot.docs
                .where((task) {
                  final taskData = task.data() as Map<String, dynamic>;
                  
                  // Safely check completion status
                  bool isCompleted = taskData['completed'] == true;
                  if (!isCompleted) return false;
                  
                  // Safely handle completion date
                  final completedDate = (taskData['completedDate'] as Timestamp?)?.toDate();
                  if (completedDate == null) return false;
                  
                  return completedDate.isAfter(thirtyDaysAgo);
                })
                .length;

            totalCompletedTasks += completedTasksForGoal;
            totalTasks += tasksSnapshot.docs.length;
          }

          // Fetch user details with null safety
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

          if (!userDoc.exists) continue;

          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData == null) continue;

          // Safely access user data with null checks and defaults
          final firstName = userData['fname'] as String? ?? 'Unknown';
          final lastName = userData['lname'] as String? ?? 'User';
          final photoUrl = userData['photo'] as String? ?? '';

          // Calculate productivity metrics
          double completionRate = totalTasks > 0 ? totalCompletedTasks / totalTasks : 0;
          int productivityScore =
              (totalCompletedTasks * 10 + completionRate * 100).round();

          userProductivity.add({
            'userId': userId,
            'fullName': '$firstName $lastName',
            'profilePic': photoUrl,
            'completedTasks': totalCompletedTasks,
            'totalGoals': goalsSnapshot.docs.length,
            'totalTasks': totalTasks,
            'productivityScore': productivityScore,
          });
        } catch (e) {
          print('Error processing user $userId: $e');
          continue; // Skip this user and continue with others
        }
      }

      // Sort by productivity score
      userProductivity.sort(
          (a, b) => b['productivityScore'].compareTo(a['productivityScore']));

      yield userProductivity;
    } catch (e) {
      print('Error fetching productivity rankings: $e');
      yield [];
    }
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
      children: [
        _PeriodTab(label: 'Last 30 days', isActive: true),
        const SizedBox(width: 8),
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
    required this.topUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (topUsers.length > 1)
          Expanded(
            child: PodiumCard(
              user: topUsers[1],
              position: 2,
              scale: 0.9,
            ),
          ),
        Expanded(
          child: PodiumCard(
            user: topUsers[0],
            position: 1,
            isWinner: true,
            scale: 1.1,
          ),
        ),
        if (topUsers.length > 2)
          Expanded(
            child: PodiumCard(
              user: topUsers[2],
              position: 3,
              scale: 0.9,
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

  String _getPositionEmoji() {
    switch (position) {
      case 1:
        return '👑';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _getPositionColor() {
    switch (position) {
      case 1:
        return Colors.amber.withOpacity(0.2);
      case 2:
        return Colors.grey[300]!.withOpacity(0.2);
      case 3:
        return Colors.orange[800]!.withOpacity(0.2);
      default:
        return Colors.white.withOpacity(0.1);
    }
  }

  String _getFirstName() {
    final fullName = user['fullName'] as String;
    return fullName.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_getPositionEmoji(), style: const TextStyle(fontSize: 24)),
            ),
          // Profile Picture
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isWinner ? Colors.amber : Colors.white.withOpacity(0.2),
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
          // Glassy Card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getPositionColor(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFirstName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${user['productivityScore']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
              // Position
              SizedBox(
                width: 32,
                child: Text(
                  position.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              
              // Profile picture
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
              
              // Name and Score in Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user['fullName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${user['productivityScore']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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