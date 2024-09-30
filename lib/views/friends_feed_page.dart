import 'package:flutter/material.dart';

class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

  // Sample data for posts
  final List<Map<String, String>> posts = const [
    {
      "user": "Alice",
      "content": "Just finished a 10k run! Feeling awesome! 🏃‍♀️💪",
    },
    {
      "user": "Bob",
      "content": "Can't wait for the weekend! Time to relax. 🌴",
    },
    {
      "user": "Charlie",
      "content": "Loving this new coffee shop in town ☕. #BestCoffee",
    },
    {
      "user": "Diana",
      "content": "Working on my new project, so excited to share soon! 💻🚀",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends Feed"),
      ),
      body: Column(
        children: [
          // Ranking dashboard at the top
          _buildRankingDashboard(),

          // Expanded widget to allow the feed to take up the remaining space
          Expanded(
            child: _buildPostsFeed(),
          ),
        ],
      ),
    );
  }

  // Widget for the ranking dashboard
  Widget _buildRankingDashboard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.deepPurpleAccent, // Background color
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

  // Widget for the feed of posts
  Widget _buildPostsFeed() {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostCard(user: post['user']!, content: post['content']!);
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

// Widget for each post card
class _PostCard extends StatelessWidget {
  final String user;
  final String content;

  const _PostCard({required this.user, required this.content});

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
          ],
        ),
      ),
    );
  }
}
