import 'package:achiva/views/PostCard.dart';
import 'package:achiva/views/productivity_ranking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class FriendsFeedScreen extends StatefulWidget {
  const FriendsFeedScreen({super.key});

  @override
  _FriendsFeedScreenState createState() => _FriendsFeedScreenState();
}

class _FriendsFeedScreenState extends State<FriendsFeedScreen> {
  late Stream<List<Map<String, dynamic>>> _postsStream;
  
late Stream<List<Map<String, dynamic>>> _rankingsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _fetchTaskPosts();
    _rankingsStream = RankingsService().fetchProductivityRankings();

  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsStream = _fetchTaskPosts();
    });
  }

Stream<List<Map<String, dynamic>>> _fetchTaskPosts() async* {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print('No user is logged in.');
      }
      yield [];
      return;
    }

    // Fetch friends list
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .collection('friends')
        .get();

    List<String> friendIds = friendsSnapshot.docs
        .map((doc) => doc['userId'] as String)
        .toList();

    // Add current user's ID to the list
    friendIds.add(currentUser.uid);

    List<Map<String, dynamic>> allPosts = [];
    
    // Fetch posts for each user (including current user)
    for (String userId in friendIds) {
      QuerySnapshot userPostsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('allPosts')
          .orderBy('postDate', descending: true)
          .limit(20)
          .get();

      for (var postDoc in userPostsSnapshot.docs) {
        final postData = postDoc.data() as Map<String, dynamic>;
        final postId = postDoc.id;

        if (kDebugMode) {
          print('Raw post data: $postData');
          print('Post ID: $postId');
        }

        if (postData.containsKey('content') &&
            postData.containsKey('postDate')) {
          String formattedDate = 'Unknown Date';
          try {
            if (postData['postDate'] is Timestamp) {
              DateTime dateTime = (postData['postDate'] as Timestamp).toDate();
              formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
            } else if (postData['postDate'] is String) {
              formattedDate = postData['postDate'];
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error formatting date: $e');
            }
          }

          final userInfo = await _fetchUserName(userId);

          allPosts.add({
            'id': postId,
            'userName': userInfo['fullName'],
            'profilePic': userInfo['profilePic'],
            'content': postData['content'].toString(),
            'photo': postData['photo']?.toString(),
            'timestamp': formattedDate,
            'dateTime': (postData['postDate'] as Timestamp).toDate(),
          });
        }
      }
    }

    // Sort all posts by date
    allPosts.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));

    // Limit to the most recent 20 posts
    allPosts = allPosts.take(20).toList();

    if (kDebugMode) {
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

  Future<Map<String, String>> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        String firstName = userData['fname'] ?? 'Unknown';
        String lastName = userData['lname'] ?? 'User';
        String profilePic = userData['photo'] ?? '';

        return {
          'fullName': '$firstName $lastName',
          'profilePic': profilePic,
        };
      } else {
        return {
          'fullName': 'Unknown User',
          'profilePic': '',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user name: $e');
      }
      return {
        'fullName': 'Unknown User',
        'profilePic': '',
      };
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.centerLeft,
                end: Alignment.centerRight,
            colors: [
                  Color.fromARGB(255, 66, 32, 101),
                  Color.fromARGB(255, 77, 64, 98),
                ],              
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                expandedHeight: 160.0,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Center(
                    child: _buildRankingDashboard(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Recent Posts",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildPostsFeed(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the feed of posts (fetch posts from tasks)
 Widget _buildPostsFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

         if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No posts available.', style: TextStyle(color: Colors.white))),
          );
        }

        final posts = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              return  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: PostCard(
                userName: post['userName'] ?? 'Unknown User',
                content: post['content'] ?? 'No content',
                photoUrl: post['photo'],
                timestamp: post['timestamp'] ?? 'Unknown time',
                profilePicUrl: post['profilePic'],
                postId: post['id'] ?? '',),
              );
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }

  // Widget for the ranking dashboard
    Widget _buildRankingDashboard() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream:RankingsService().fetchProductivityRankings(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text('No ranking data available', 
            style: TextStyle(color: Colors.white))
        );
      }
      
      return ProductivityRankingDashboard(rankings: snapshot.data!);
    },
  );
}
}
