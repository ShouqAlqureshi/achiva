import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RankingsService {
  Stream<List<Map<String, dynamic>>> fetchProductivityRankings() async* {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      List<String> userIds =
          friendsSnapshot.docs.map((doc) => doc['userId'] as String).toList();
      userIds.add(currentUser.uid);

      List<Map<String, dynamic>> userProductivity = [];

      for (String userId in userIds) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

        QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('tasks')
            .where('completed', isEqualTo: true)
            .where('completedDate', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .get();

        QuerySnapshot goalsSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('goals')
            .get();

        int completedTasks = tasksSnapshot.docs.length;
        int totalGoals = goalsSnapshot.docs.length;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        double completionRate =
            totalGoals > 0 ? completedTasks / totalGoals : 0;
        int productivityScore =
            (completedTasks * 10 + completionRate * 100).round();

        userProductivity.add({
          'userId': userId,
          'fullName': '${userData['fname']} ${userData['lname']}',
          'profilePic': userData['photo'] ?? '',
          'completedTasks': completedTasks,
          'totalGoals': totalGoals,
          'productivityScore': productivityScore,
        });
      }

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
    Key? key,
    required this.rankings,
  }) : super(key: key);

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
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Productivity Rankings",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                rankings.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ProductivityCard(
                    user: rankings[index]['fullName'],
                    score: rankings[index]['productivityScore'].toString(),
                    position: _getEmoji(index),
                    profilePic: rankings[index]['profilePic'],
                    completedTasks: rankings[index]['completedTasks'],
                    totalGoals: rankings[index]['totalGoals'],
                  ),
                ),
              ),
            ),
          ),
        ],
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

  const ProductivityCard({
    Key? key,
    required this.user,
    required this.score,
    required this.position,
    this.profilePic,
    required this.completedTasks,
    required this.totalGoals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              profilePic != null && profilePic!.isNotEmpty
                  ? CircleAvatar(
                      radius: 25.0,
                      backgroundImage: NetworkImage(profilePic!),
                    )
                  : CircleAvatar(
                      radius: 25.0,
                      child: Text(user.substring(0, 1)),
                    ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(position, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            user,
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4.0),
          Text(
            'Score: $score',
            style: const TextStyle(color: Colors.white, fontSize: 12.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            '$completedTasks Tasks',
            style: const TextStyle(color: Colors.white70, fontSize: 10.0),
          ),
          Text(
            '$totalGoals Goals',
            style: const TextStyle(color: Colors.white70, fontSize: 10.0),
          ),
        ],
      ),
    );
  }
}
