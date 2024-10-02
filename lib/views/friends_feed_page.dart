import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

  // Function to fetch posts from the user's tasks and their friends' tasks
  Stream<List<Map<String, dynamic>>> _fetchTaskPosts() async* {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No user is logged in.');
    }

    // Get the current user's document from the 'users' collection
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userSnapshot.exists) {
      throw Exception('User data not found.');
    }

    // Get the user's friends list (assuming it's an array of UIDs)
    List<dynamic> friendsList = userSnapshot['friends'] ?? [];
    
    // Include the current user's UID to fetch their posts as well
    friendsList.add(currentUser.uid);

    // Fetch tasks with posts from both the user and their friends
    List<Map<String, dynamic>> allPosts = [];

    // For each friend (including the user), fetch tasks that have posts
    for (String friendId in friendsList) {
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('tasks')
          .where('post', isNotEqualTo: null)  // Only fetch tasks with posts
          .get();

      for (var doc in tasksSnapshot.docs) {
        final task = doc.data() as Map<String, dynamic>;
        final post = task['post'];
        if (post != null) {
          allPosts.add({
            'userId': friendId,
            'content': post['content'],
            'photo': post['photo'],
            'timestamp': post['timestamp'],
            'noReaction': post['noReaction'],
            'reactions': post['reactions'],
          });
        }
      }
    }

    // Emit the posts
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
              noReaction: post['noReaction'],
              reactions: post['reactions'],
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
  final String photoUrl;
  final String timestamp;
  final int noReaction;
  final List reactions;

  const _PostCard({
    required this.user,
    required this.content,
    required this.photoUrl,
    required this.timestamp,
    required this.noReaction,
    required this.reactions,
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
            Text(
              user,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              content,
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 5.0),
            photoUrl != null
                ? Image.network(photoUrl, height: 200.0, fit: BoxFit.cover)
                : const SizedBox.shrink(),
            const SizedBox(height: 5.0),
            Text(
              '$noReaction Reactions',
              style: const TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
