import 'package:achiva/views/streakCalculator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:achiva/views/FriendsFeed/friends_feed_page.dart';

// Widget for each post card (display post content)
class PostCard extends StatefulWidget {
  final String userName;
  final String content;
  final String? photoUrl;
  final String timestamp;
  final String? profilePicUrl;
  final String? postId;
  final String userId; 
  final VoidCallback onPostDeleted; 

  const PostCard({
    required this.userName,
    required this.content,
    this.photoUrl,
    required this.timestamp,
    this.profilePicUrl,
    this.postId,
    required this.userId,
    required this.onPostDeleted,
     Key? key,

  }): super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
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
// Add delete post function
  Future<void> _deletePost() async {
    try {
      // Show confirmation dialog
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ?? false;

      if (!confirmDelete) return;

      // Delete the post from Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('allPosts')
          .doc(widget.postId)
          .delete();
          widget.onPostDeleted();
          await StreakCalculator.handlePostDeleted();


      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('Failed to delete post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete post'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
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
        final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserPost = currentUser?.uid == widget.userId;
    return GestureDetector(
      onLongPress: _showEmojiPicker,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        children: [
           Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
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
                      if (isCurrentUserPost)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _deletePost,
                          tooltip: 'Delete post',
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
                            children: reactions.entries
                              .groupBy((entry) => entry.value)
                              .entries
                              .map((entry) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 4),
                                    Text('${entry.value.length}', style: const TextStyle(fontSize: 14)),
                                  ],
                                );
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
extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
    <K, List<E>>{},
    (Map<K, List<E>> map, E element) => map..putIfAbsent(keyFunction(element), () => <E>[]).add(element),
  );
}
