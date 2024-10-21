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

          // Count completed tasks within last 30 days
          int completedTasksForGoal = tasksSnapshot.docs
              .where((task) {
                final taskData = task.data() as Map<String, dynamic>;
                if (!taskData['completed']) return false;
                
                final completedDate = (taskData['completedDate'] as Timestamp?)?.toDate();
                if (completedDate == null) return false;
                
                return completedDate.isAfter(thirtyDaysAgo);
              })
              .length;

          totalCompletedTasks += completedTasksForGoal;
          totalTasks += tasksSnapshot.docs.length;
        }

        // Fetch user details
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Calculate productivity metrics
        double completionRate = totalTasks > 0 ? totalCompletedTasks / totalTasks : 0;
        int productivityScore =
            (totalCompletedTasks * 10 + completionRate * 100).round();

        userProductivity.add({
          'userId': userId,
          'fullName': '${userData['fname']} ${userData['lname']}',
          'profilePic': userData['photo'] ?? '',
          'completedTasks': totalCompletedTasks,
          'totalGoals': goalsSnapshot.docs.length,
          'totalTasks': totalTasks,
          'productivityScore': productivityScore,
        });
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

  String _getEmoji(int index) {
    switch (index) {
      case 0:
        return '🏆';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}';
    }
  }

  
     @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  children: [
                    Text(
                      "Productivity Rankings",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Last 30 Days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rankings List
                SizedBox(
                  height: 144, // Reduced height
                  child: rankings.isEmpty
                      ? const Center(
                          child: Text(
                            'No ranking data available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: rankings.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) => ProductivityCard(
                            user: rankings[index]['fullName'],
                            score: rankings[index]['productivityScore'].toString(),
                            position: _getEmoji(index),
                            profilePic: rankings[index]['profilePic'],
                            completedTasks: rankings[index]['completedTasks'],
                            totalGoals: rankings[index]['totalGoals'],
                            isFirst: index == 0,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductivityCard extends StatelessWidget {
  final String user;
  final String score;
  final String position;
  final String? profilePic;
  final int completedTasks;
  final int totalGoals;
  final bool isFirst;

  const ProductivityCard({
    super.key,
    required this.user,
    required this.score,
    required this.position,
    this.profilePic,
    required this.completedTasks,
    required this.totalGoals,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isFirst
            ? Colors.purple.withOpacity(0.3)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? Colors.purple.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFirst
                        ? Colors.purple.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      profilePic != null ? NetworkImage(profilePic!) : null,
                  child: profilePic == null
                      ? Text(
                          user.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                top: -9, // Moved higher up
                right: -6, // Moved further right
                child: Container(
                  width: 32, // Increased size
                  height: 32, // Increased size
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Made background transparent
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst ? Colors.amber : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      position,
                      style: TextStyle(
                        fontSize: 16, // Increased font size
                        color: isFirst ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Score: $score',
            style: TextStyle(
              color: isFirst ? Colors.amber : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat('$completedTasks Tasks'),
              _buildDot(),
              _buildStat('$totalGoals Goals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 10,
      ),
    );
  }

  Widget _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '•',
        style: TextStyle(
          color: Colors.white60,
          fontSize: 10,
        ),
      ),
    );
  }
}