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
  bool _showPosts = true;
  bool _needsPostsRefresh = false;

   @override
  void initState() {
    super.initState();
    _refreshCurrentView();
  }

  // Refresh the current view based on which tab is selected
  void _refreshCurrentView() {
    if (_showPosts) {
      _refreshPosts();
    } else {
      _refreshRankings();
    }
  }

  // Modified toggle view to always refresh data
  void _toggleView(bool showPosts) {
    if (_showPosts != showPosts) {
      setState(() {
        _showPosts = showPosts;
        _refreshCurrentView(); // Refresh data whenever view changes
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsStream = _fetchTaskPosts().asBroadcastStream();
    });
  }

  Future<void> _refreshRankings() async {
    setState(() {
      _rankingsStream = RankingsService().fetchProductivityRankings().asBroadcastStream();
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

      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      List<String> friendIds = friendsSnapshot.docs
          .map((doc) => doc['userId'] as String)
          .toList();

      friendIds.add(currentUser.uid);

      List<Map<String, dynamic>> allPosts = [];
      
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

          if (postData.containsKey('content') &&
              postData.containsKey('postDate')) {
            String formattedDate = 'Unknown Date';
            DateTime? dateTime;
            
            try {
              if (postData['postDate'] is Timestamp) {
                dateTime = (postData['postDate'] as Timestamp).toDate();
                formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
              } else if (postData['postDate'] is String) {
                formattedDate = postData['postDate'];
                dateTime = DateTime.parse(formattedDate);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error formatting date: $e');
              }
              dateTime = DateTime.now();
            }

            final userInfo = await _fetchUserName(userId);

            allPosts.add({
              'id': postId,
              'userName': userInfo['fullName'] ?? 'Unknown User',
              'profilePic': userInfo['profilePic'] ?? '',
              'content': postData['content']?.toString() ?? 'No content',
              'photo': postData['photo']?.toString() ?? '',
              'timestamp': formattedDate,
              'dateTime': (postData['postDate'] as Timestamp).toDate(),
            });
          }
        }
      }

      allPosts.sort((a, b) => (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime));
      allPosts = allPosts.take(20).toList();

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
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        String firstName = userData['fname']?.toString() ?? 'Unknown';
        String lastName = userData['lname']?.toString() ?? 'User';
        String profilePic = userData['photo']?.toString() ?? '';

        return {
          'fullName': '$firstName $lastName',
          'profilePic': profilePic,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user name: $e');
      }
    }
    
    // Return default values if anything fails
    return {
      'fullName': 'Unknown User',
      'profilePic': '',
    };
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildToggleSwitch(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showPosts ? _buildPostsView() : _buildRankingsView(),
          ),
        ),
      ),
    );
  }


  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _showPosts ? "Friends Feed" : "Rankings",
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
          borderRadius: BorderRadius.circular(25),
        ),
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
                text: "Rankings",
                isSelected: !_showPosts,
                onTap: () => _toggleView(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

    Widget _buildPostsView() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

          final posts = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16.0),
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                userName: post['userName'] ?? 'Unknown User',
                content: post['content'] ?? 'No content',
                photoUrl: post['photo'] ?? '',
                timestamp: post['timestamp'] ?? 'Unknown time',
                profilePicUrl: post['profilePic'] ?? '',
                postId: post['id'] ?? '',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankingsView() {
    return RefreshIndicator(
      onRefresh: _refreshRankings,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _rankingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: ProductivityRankingDashboard(rankings: snapshot.data!),
            ),
          );
        },
      ),
    );
  }
}
//   // Widget for the feed of posts (fetch posts from tasks)
//  Widget _buildPostsFeed() {
//     return StreamBuilder<List<Map<String, dynamic>>>(
//       stream: _postsStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SliverFillRemaining(
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//          if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const SliverFillRemaining(
//             child: Center(child: Text('No posts available.', style: TextStyle(color: Colors.white))),
//           );
//         }

//         final posts = snapshot.data!;

//         return SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (context, index) {
//               final post = posts[index];
//               return  Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 child: PostCard(
//                 userName: post['userName'] ?? 'Unknown User',
//                 content: post['content'] ?? 'No content',
//                 photoUrl: post['photo'],
//                 timestamp: post['timestamp'] ?? 'Unknown time',
//                 profilePicUrl: post['profilePic'],
//                 postId: post['id'] ?? '',),
//               );
//             },
//             childCount: posts.length,
//           ),
//         );
//       },
//     );
//   }

//   // Widget for the ranking dashboard
//     Widget _buildRankingDashboard() {
//   return StreamBuilder<List<Map<String, dynamic>>>(
//     stream:RankingsService().fetchProductivityRankings(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
      
//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//         return const Center(
//           child: Text('No ranking data available', 
//             style: TextStyle(color: Colors.white))
//         );
//       }
      
//       return ProductivityRankingDashboard(rankings: snapshot.data!);
//     },
//   );
// }

