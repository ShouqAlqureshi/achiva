import 'dart:async';
import 'package:achiva/views/FriendsFeed/PostCard.dart';
import 'package:achiva/views/FriendsFeed/productivity_ranking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FriendsFeedScreen extends StatefulWidget {
  const FriendsFeedScreen({super.key});

  @override
  _FriendsFeedScreenState createState() => _FriendsFeedScreenState();
}

class _FriendsFeedScreenState extends State<FriendsFeedScreen> {
  late Stream<List<Map<String, dynamic>>> _postsStream;
  late Stream<List<Map<String, dynamic>>> _rankingsStream;
  bool _showPosts = true;
  final PageController _pageController = PageController();
  
  // Cache for user information
  final Map<String, Map<String, String>> _userCache = {};
  
  // Cache for posts
  List<Map<String, dynamic>>? _cachedPosts;
  List<Map<String, dynamic>>? _cachedRankings;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _postsStream = _createPostsStream().asBroadcastStream();
    _rankingsStream = RankingsService().fetchProductivityRankings().asBroadcastStream();

    // Listen to streams and cache data
    _postsStream.listen((data) {
      _cachedPosts = data;
    });
    _rankingsStream.listen((data) {
      _cachedRankings = data;
    });
  }

  void _toggleView(bool showPosts) {
    if (_showPosts != showPosts) {
      setState(() {
        _showPosts = showPosts;
        _pageController.animateToPage(
          showPosts ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _onPageChanged(int page) {
    if (_showPosts != (page == 0)) {
      setState(() {
        _showPosts = page == 0;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _createPostsStream() async* {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      // Get friends list
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      final friendIds = friendsSnapshot.docs
          .map((doc) => doc['userId'] as String)
          .toList()
        ..add(currentUser.uid); // Include current user

      // Fetch posts for all users in parallel
      final futures = friendIds.map((userId) => _fetchUserPosts(userId));
      final postsLists = await Future.wait(futures);

      // Combine and sort all posts
      final allPosts = postsLists.expand((posts) => posts).toList()
        ..sort((a, b) => (b['dateTime'] as DateTime)
            .compareTo(a['dateTime'] as DateTime));

      yield allPosts.take(20).toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _createPostsStream: $e');
        print('Stack trace: $stackTrace');
      }
      yield [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserPosts(String userId) async {
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('allPosts')
          .orderBy('postDate', descending: true)
          .limit(20)
          .get();

      final userInfo = await _getCachedUserInfo(userId);
      
      return Future.wait(postsSnapshot.docs.map((doc) async {
        final postData = doc.data();
        final postId = doc.id;

        if (!postData.containsKey('content') || !postData.containsKey('postDate')) {
          return null;
        }

        final timestamp = postData['postDate'] as Timestamp;
        final dateTime = timestamp.toDate();
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

        return {
          'id': postId,
          'userName': userInfo['fullName'],
          'profilePic': userInfo['profilePic'],
          'content': postData['content']?.toString() ?? 'No content',
          'photo': postData['photo']?.toString() ?? '',
          'timestamp': formattedDate,
          'dateTime': dateTime,
        };
      }))
      .then((posts) => posts.whereType<Map<String, dynamic>>().toList());
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching posts for user $userId: $e');
      }
      return [];
    }
  }

  Future<Map<String, String>> _getCachedUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final userInfo = {
          'fullName': '${userData['fname'] ?? 'Unknown'} ${userData['lname'] ?? 'User'}',
          'profilePic': userData['photo']?.toString() ?? '',
        };
        _userCache[userId] = userInfo;
        return userInfo;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user info: $e');
      }
    }

    return {
      'fullName': 'Unknown User',
      'profilePic': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            _buildToggleSwitch(),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPostsView(),
                  _buildRankingsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildPostsView() {
  return RefreshIndicator(
    onRefresh: () async => _initializeStreams(),
    child: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while waiting for data
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final posts = snapshot.data ?? _cachedPosts ?? [];

        if (posts.isEmpty) {
          return ListView(
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No posts available.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 16.0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return const SizedBox(height: kBottomNavigationBarHeight);
            }

            final post = posts[index];
            return PostCard(
              userName: post['userName'],
              content: post['content'],
              photoUrl: post['photo'],
              timestamp: post['timestamp'],
              profilePicUrl: post['profilePic'],
              postId: post['id'],
            );
          },
        );
      },
    ),
  );
}

Widget _buildRankingsView() {
  return RefreshIndicator(
    onRefresh: () async => _initializeStreams(),
    child: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _rankingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while waiting for data
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final rankings = snapshot.data ?? _cachedRankings ?? [];

        if (rankings.isEmpty) {
          return ListView(
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No ranking data available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProductivityRankingDashboard(rankings: rankings),
              const SizedBox(height: kBottomNavigationBarHeight),
            ],
          ),
        );
      },
    ),
  );
}


  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _showPosts ? "Recent Posts" : "Productivity Leaderboard",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

 
  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25), // Increased border radius
        ),
        padding: const EdgeInsets.all(4), // Added padding inside container
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                text: "Posts",
                isSelected: _showPosts,
                onTap: () => _toggleView(true),
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                text: "Leaderboard",
                isSelected: !_showPosts,
                onTap: () => _toggleView(false),
              ),
            ),
          ],
        ),
      ),
    );
  }


  
}
 Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
