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
late StreamController<List<Map<String, dynamic>>> _postsStreamController;
  Stream<List<Map<String, dynamic>>>? _postsStream;
  Stream<List<Map<String, dynamic>>>? _rankingsStream;
  bool _showPosts = true;
  final PageController _pageController = PageController();
  
  final Map<String, Map<String, String>> _userCache = {};
  List<Map<String, dynamic>>? _cachedPosts;
  List<Map<String, dynamic>>? _cachedRankings;
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _postsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
    _postsStream = _postsStreamController.stream;
    _initializeStreams();
  }

  @override
  void dispose() {
    _postsStreamController.close();
    _pageController.dispose();
    super.dispose();
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
 Future<void> _refreshPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final freshPosts = await _createPostsStream();
      if (!_postsStreamController.isClosed) {
        _postsStreamController.add(freshPosts);
        _cachedPosts = freshPosts;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing posts: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _initializeStreams() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      // Initialize posts
      final posts = await _createPostsStream();
      if (!_postsStreamController.isClosed) {
        _postsStreamController.add(posts);
        _cachedPosts = posts;
      }

      // Initialize rankings stream
      _rankingsStream = RankingsService().fetchProductivityRankings().asBroadcastStream();
      _rankingsStream?.listen((data) {
        _cachedRankings = data;
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error initializing streams: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  void _onPageChanged(int page) {
    if (_showPosts != (page == 0)) {
      setState(() {
        _showPosts = page == 0;
      });
    }
  }

 Future<void> handlePostDeletion(String postId, String userId) async {
    try {
      // Update the local state immediately
      final currentPosts = _cachedPosts ?? [];
      final updatedPosts = currentPosts.where((post) => post['id'] != postId).toList();
      
      if (!_postsStreamController.isClosed) {
        _postsStreamController.add(updatedPosts);
      }
      
      // Update cache
      _cachedPosts = updatedPosts;
      
      // Verify the deletion in Firestore
      final postDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('allPosts')
          .doc(postId)
          .get();
      
      if (!postDoc.exists) {
        // Post was successfully deleted, we've already updated the UI
        return;
      } else {
        // If the post still exists, refresh the entire feed
        final freshPosts = await _createPostsStream();
        if (!_postsStreamController.isClosed) {
          _postsStreamController.add(freshPosts);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling post deletion: $e');
      }
      // Refresh the feed to ensure consistency
      final freshPosts = await _createPostsStream();
      if (!_postsStreamController.isClosed) {
        _postsStreamController.add(freshPosts);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _createPostsStream() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
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

      return allPosts.take(20).toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _createPostsStream: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
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
          'userId': userId, 
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
      onRefresh: _refreshPosts,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postsStream,
        initialData: _cachedPosts,
        builder: (context, snapshot) {
          // Show loading indicator only on initial load (no cached data)
          if (_isLoadingPosts && _cachedPosts == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final posts = snapshot.data ?? _cachedPosts ?? [];

          if (posts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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

          return Stack(
            children: [
              ListView.separated(
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
                    userId: post['userId'],
                    onPostDeleted: () => handlePostDeletion(post['id'], post['userId']),
                  );
                },
              ),
              // Show a subtle loading indicator at the top when refreshing
              // if (_isLoadingPosts)
              //   const Positioned(
              //     top: 0,
              //     left: 0,
              //     right: 0,
              //     child: LinearProgressIndicator(
              //       backgroundColor: Colors.transparent,
              //       valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
              //     ),
              //   ),
            ],
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
        initialData: _cachedRankings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _cachedRankings == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading rankings: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
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
