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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            expandedHeight: 160.0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildRankingDashboard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Recent Posts",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          _buildPostsFeed(),
        ],
      ),
    );
  }

  // Widget for the ranking dashboard
   Widget _buildRankingDashboard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.deepPurpleAccent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _RankingCard(user: 'Alice', score: '🏅 1500'),
                SizedBox(width: 10),
                _RankingCard(user: 'Bob', score: '🥈 1200'),
                SizedBox(width: 10),
                _RankingCard(user: 'Charlie', score: '🥉 1100'),
                SizedBox(width: 10),
                _RankingCard(user: 'David', score: '1000'),
                SizedBox(width: 10),
                _RankingCard(user: 'Eva', score: '950'),
              ],
            ),
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
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No posts available.')),
          );
        }

        final posts = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              return _PostCard(
                userName: post['userName'] ?? 'Unknown User',
                content: post['content'] ?? 'No content',
                photoUrl: post['photo'],
                timestamp: post['timestamp'] ?? 'Unknown time',
                profilePicUrl: post['profilePic'],
                postId: post['id'] ?? '',
              );
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }
}



// Widget for each post card (display post content)
class _PostCard extends StatefulWidget {
  final String userName;
  final String content;
  final String? photoUrl;
  final String timestamp;
  final String? profilePicUrl;
  final String? postId; // Add this line to receive the postId

  const _PostCard({
    required this.userName,
    required this.content,
    this.photoUrl,
    required this.timestamp,
    this.profilePicUrl,
    this.postId, // Add this line
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String? selectedEmoji;
  bool showHeart = false;
  Map<String, dynamic> reactions = {};


  final List<String> emojis = ['❤️', '😀', '😍', '👍', '🎉', '😮', '😢'];

  @override
  void initState() {
    super.initState();
    _fetchReactions();

  }

void _fetchReactions() async {
  try {
    var postDoc = await _findPostDocument(widget.postId!);
    if (postDoc == null) return;

    setState(() {
      var data = postDoc.data() as Map<String, dynamic>?;
      reactions = data?['reactions'] as Map<String, dynamic>? ?? {};
    });
  } catch (error) {
    print('Failed to fetch reactions: $error');
  }
}

  
void _showReactionsDialog() {
  // Check if there are any reactions
  bool hasReactions = reactions.entries.any((entry) => emojis.contains(entry.value));

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Reactions'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: 50,
          ),
          child: hasReactions
              ? SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: emojis.where((emoji) {
                      return reactions.entries.any((entry) => entry.value == emoji);
                    }).map((emoji) {
                      var usersReacted = reactions.entries
                          .where((entry) => entry.value == emoji)
                          .map((entry) => entry.key)
                          .toList();
                      return ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                        title: Text('${usersReacted.length}'),
                        onTap: () {
                          print('Users who reacted with $emoji: $usersReacted');
                        },
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      'No reactions yet',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  void _showEmojiPicker() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Choose a reaction'),
        content: Wrap(
          spacing: 10,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                _updateReaction(emoji);
                Navigator.of(context).pop();
              },
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            );
          }).toList(),
        ),
      );
    },
  );
}

void _updateReaction(String emoji) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Find the post document
    var postDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .collection('allPosts')
        .doc(widget.postId)
        .get();

    if (!postDoc.exists) {
      // If not found in current user's posts, search in friends' posts
      var friendsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      for (var friendDoc in friendsSnapshot.docs) {
        String friendId = friendDoc['userId'];
        postDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(friendId)
            .collection('allPosts')
            .doc(widget.postId)
            .get();

        if (postDoc.exists) break;
      }
    }

    if (!postDoc.exists) {
      throw Exception('Post document not found');
    }

    // Update the reaction field in the post document
    await postDoc.reference.update({
      'reactions.${currentUser.uid}': emoji,
    });

    setState(() {
      reactions[currentUser.uid] = emoji;
      selectedEmoji = emoji;
    });
  } catch (error) {
    print('Failed to update reaction: $error');
  }
}

Future<DocumentSnapshot?> _findPostDocument(String postId) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;

  // Search in the user's own posts first
  var postDoc = await FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser.uid)
      .collection('allPosts')
      .doc(postId)
      .get();

  if (postDoc.exists) return postDoc;

  // If not found in user's posts, search in friends' posts
  var friendsSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser.uid)
      .collection('friends')
      .get();

  for (var friendDoc in friendsSnapshot.docs) {
    String friendId = friendDoc['userId'];
    postDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('allPosts')
        .doc(postId)
        .get();

    if (postDoc.exists) return postDoc;
  }

  return null;
}

  // Handle double tap for heart reaction
  void _handleDoubleTap() {
     _updateReaction('❤️');
  setState(() {
    showHeart = true;
  });

    // Show the heart for a brief moment
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showHeart = false;
      });
    });
  }

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showEmojiPicker,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.profilePicUrl != null &&
                          widget.profilePicUrl!.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.profilePicUrl!),
                          radius: 30.0,
                        )
                      else
                        const CircleAvatar(
                          child: Icon(Icons.person),
                          radius: 30.0,
                        ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          widget.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(widget.content, style: const TextStyle(fontSize: 14.0)),
                ),
                const SizedBox(height: 10.0),
                if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: _buildImageWidget(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.timestamp,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Wrap(
                            spacing: 8,
                            children: reactions.values.toSet().map((emoji) {
                              return Text(emoji, style: const TextStyle(fontSize: 24));
                            }).toList(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            onPressed: _showReactionsDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showHeart)
            Positioned.fill(
              child: Center(
                child: Icon(Icons.favorite,
                    color: Colors.red.withOpacity(0.8), size: 80),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    return Image.network(
      widget.photoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('Error loading image: $error');
          print('Image URL: ${widget.photoUrl}');
        }
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text('Failed to load image',
              style: TextStyle(color: Colors.red[700])),
          const SizedBox(height: 5),
          if (kDebugMode)
            Text(
              'URL: ${widget.photoUrl}',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

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
}

// Widget for the ranking cards
class _RankingCard extends StatelessWidget {
  final String user;
  final String score;

  const _RankingCard({
    required this.user,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20.0,
            child: Text(user.substring(0, 1)),
          ),
          const SizedBox(height: 5.0),
          Text(
            user,
            style: const TextStyle(color: Colors.white, fontSize: 12.0),
          ),
          Text(
            score,
            style: const TextStyle(color: Colors.white, fontSize: 10.0),
          ),
        ],
      ),
    );
  }
}