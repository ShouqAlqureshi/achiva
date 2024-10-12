import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

Stream<List<Map<String, dynamic>>> _fetchTaskPosts() async* {
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    if (kDebugMode) {
      print('No user is logged in.');
    }
    return;
  }

  // Get the current user's document from the 'users' collection
  DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser.uid)
      .get();

  if (!userSnapshot.exists) {
    if (kDebugMode) {
      print('User data not found.');
    }
    return;
  }

  // Get the user's friends list
  List<dynamic> friendsList = userSnapshot['friends'] ?? [];
  friendsList.add(currentUser.uid);  // Include the current user's UID
if (kDebugMode) {
  print('Friends List: $friendsList');
}

  List<Map<String, dynamic>> allPosts = [];

for (String friendId in friendsList) {
  if (kDebugMode) {
    print('Fetching posts for user: $friendId');
  }
  
  QuerySnapshot goalsSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(friendId)
      .collection('goals')
      .get();

  for (var goalDoc in goalsSnapshot.docs) {
    QuerySnapshot tasksSnapshot = await goalDoc.reference
        .collection('tasks')
        .get();

    for (var taskDoc in tasksSnapshot.docs) {
      // Fetch the posts subcollection inside each task
      QuerySnapshot postsSnapshot = await taskDoc.reference
          .collection('posts') // Adjusted to query 'posts' subcollection
          .get();

      for (var postDoc in postsSnapshot.docs) {
        final post = postDoc.data() as Map<String, dynamic>;
        print('Post found: ${post['content']}');
        allPosts.add({
          'userId': friendId,
          'content': post['content'],
          'photo': post['photo'],
          'timestamp': post['postDate'],
        });
      }
    }
  }
}


  if (kDebugMode) {
    print('Total posts fetched: ${allPosts.length}');
  }
  yield allPosts;
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _buildRankingDashboard(),
            Expanded(
              child: _buildPostsFeed(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the ranking dashboard 
  Widget _buildRankingDashboard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.deepPurpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Ranked Users",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _RankingCard(user: 'Alice', score: '🏅 1500'),
              _RankingCard(user: 'Bob', score: '🥈 1200'),
              _RankingCard(user: 'Charlie', score: '🥉 1100'),
            ],
          ),
        ],
      ),
    );
  }

  // Widget for the feed of posts (fetch posts from tasks)
  Widget _buildPostsFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchTaskPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        final posts = snapshot.data!;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostCard(
              user: post['userId'],
              content: post['content'],
              photoUrl: post['photo'],
              timestamp: post['timestamp'],
            );
          },
        );
      },
    );
  }
}

// Widget for each ranking card 
class _RankingCard extends StatelessWidget {
  final String user;
  final String score;

  const _RankingCard({required this.user, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(user[0], style: const TextStyle(fontSize: 20.0)),
        ),
        const SizedBox(height: 5.0),
        Text(
          user,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          score,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

// Widget for each post card (display post content)
class _PostCard extends StatelessWidget {
  final String user;
  final String content;
  final String? photoUrl;
  final String timestamp;

  const _PostCard({
    required this.user,
    required this.content,
    required this.photoUrl,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User name
            Text(
              user,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 5.0),
            // Post content
            Text(
              content,
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 5.0),
            // Post image (if available)
            photoUrl != null
                ? Image.network(photoUrl!, height: 200.0, fit: BoxFit.cover)
                : const SizedBox.shrink(),
            const SizedBox(height: 10.0),
            // Post reactions and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              
                // Post date
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
