import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;

class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

  Stream<List<Map<String, dynamic>>> _fetchTaskPosts() async* {
    try {
      if (kDebugMode) {
        print('Starting _fetchTaskPosts function');
      }

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          print('No user is logged in.');
        }
        yield [];
        return;
      }

      if (kDebugMode) {
        print('Current user ID: ${currentUser.uid}');
      }

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();

      if (!userSnapshot.exists) {
        if (kDebugMode) {
          print('User data not found for ID: ${currentUser.uid}');
        }
        yield [];
        return;
      }

      List<dynamic> friendsList = (userSnapshot.data() as Map<String, dynamic>)['friends'] ?? [];
      friendsList.add(currentUser.uid);

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
            QuerySnapshot postsSnapshot = await taskDoc.reference
                .collection('posts')
                .get();

            for (var postDoc in postsSnapshot.docs) {
              final postData = postDoc.data() as Map<String, dynamic>;
              if (kDebugMode) {
                print('Raw post data: $postData');
              }

              if (postData.containsKey('content') && postData.containsKey('postDate')) {
                String formattedDate = 'Unknown Date';
                try {
                  if (postData['postDate'] is Timestamp) {
                    DateTime dateTime = (postData['postDate'] as Timestamp).toDate();
                    formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
                  } else if (postData['postDate'] is String) {
                    formattedDate = postData['postDate'];
                  } else {
                    if (kDebugMode) {
                      print('Unexpected postDate type: ${postData['postDate'].runtimeType}');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error formatting date: $e');
                    print('postDate value: ${postData['postDate']}');
                  }
                }

                allPosts.add({
                  'userId': friendId,
                  'content': postData['content'].toString(),
                  'photo': postData['photo']?.toString(),
                  'timestamp': formattedDate,
                });
              } else {
                if (kDebugMode) {
                  print('Skipping post due to missing required fields: $postData');
                }
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('Total posts fetched: ${allPosts.length}');
        print('All posts: $allPosts');
      }
      yield allPosts;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _fetchTaskPosts: $e');
        print('Stack trace: $stackTrace');
      }
      yield [];
    }
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
        if (kDebugMode) {
          print('StreamBuilder state: ${snapshot.connectionState}');
          print('StreamBuilder data: ${snapshot.data}');
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
          }
        }

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
              user: post['userId'].toString(),
              content: post['content'].toString(),
              photoUrl: post['photo']?.toString(),
              timestamp: post['timestamp'].toString(),
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
    this.photoUrl,
    required this.timestamp,
  });


   Future<bool> _checkImageAvailability(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking image availability: $e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 5.0),
            Text(content, style: const TextStyle(fontSize: 14.0)),
            if (photoUrl != null && photoUrl!.isNotEmpty)
              FutureBuilder<bool>(
                future: _checkImageAvailability(photoUrl!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == true) {
                    return _buildImageWidget();
                  } else {
                    return _buildErrorWidget();
                  }
                },
              ),
            const SizedBox(height: 10.0),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    return Image.network(
      photoUrl!,
      height: 200.0,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('Error loading image: $error');
          print('Image URL: $photoUrl');
        }
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200.0,
          width: double.infinity,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200.0,
      width: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text('Failed to load image', style: TextStyle(color: Colors.red[700])),
          const SizedBox(height: 5),
          if (kDebugMode)
            Text(
              'URL: $photoUrl',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}