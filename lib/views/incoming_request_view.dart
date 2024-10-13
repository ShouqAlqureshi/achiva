import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomingRequestsPage extends StatelessWidget {
  const IncomingRequestsPage({super.key});

  // Fetch current user ID
  String _getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _getCurrentUserId();
    // String currentUserId = "c4FDYNv72uOEKWxH3BeFIOZls8z2"; for testig
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Friend Requests'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserId)
            .collection('friendRequests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a single loading indicator for the whole process
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final friendRequests = snapshot.data?.docs ?? [];
          if (friendRequests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the column vertically
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Center the column horizontally
                  children: [
                    Image.asset(
                      'lib/images/no-results.png',
                      fit: BoxFit.contain,
                      height: 100,
                    ),
                    SizedBox(
                        height:
                            20), // Add some spacing between the image and text
                    Text(
                      'You have no pending friend requests yet.',
                      style: TextStyle(
                          fontSize: 16), // Optional: Customize text style
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            children: friendRequests.map((doc) {
              var friendRequestData = doc.data() as Map<String, dynamic>;
              String userId = friendRequestData['userId'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserDetails(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  // Handle cases where user data is missing or incomplete
                  var userData = userSnapshot.data;
                  String fullName = "Anonymous";
                  String? photoUrl;

                  if (userData != null) {
                    String username = userData['username'] ?? "";
                    String fname = userData['fname'] ?? "";
                    String lname = userData['lname'] ?? "";

                    // Set the full name based on available data
                    if (username.isNotEmpty) {
                      fullName = username;
                    } else if (fname.isNotEmpty || lname.isNotEmpty) {
                      fullName = '$fname $lname'.trim();
                    }

                    // Get the photo URL if available
                    photoUrl = userData['photo'];
                  }

                  return FriendRequestCard(
                    name: fullName,
                    pictureUrl: photoUrl,
                    onAccept: () {
                      _acceptFriendRequest(currentUserId, userId, doc.id);
                    },
                    onReject: () {
                      _rejectFriendRequest(currentUserId, userId, doc.id);
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Fetch user details (fname, lname, photo) from Users collection by userId
  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    } else {
      return null;
    }
  }

  // Accept friend request: update status and add user to friends
  void _acceptFriendRequest(
      String currentUserId, String userId, String requestId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'accepted'}); // user 1

    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('sentRequests')
        .doc(currentUserId)
        .update({'status': 'accepted'}); // user 2

    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friends')
        .doc(userId)
        .set({'userId': userId}); // user 1

    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('friends')
        .doc(currentUserId)
        .set({'userId': currentUserId}); // user 2
  }

  // Reject friend request: update status to rejected
  void _rejectFriendRequest(
      String currentUserId, String userId, String requestId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'rejected'}); // user 1

    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('sentRequests')
        .doc(currentUserId)
        .update({'status': 'rejected'}); // user 2
  }
}

class FriendRequestCard extends StatelessWidget {
  final String name;
  final String? pictureUrl; // Nullable to handle cases where no photo exists
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const FriendRequestCard({
    super.key,
    required this.name,
    required this.pictureUrl,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // color: Colors.deepPurple,  for dark mode
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: pictureUrl != null
                  ? NetworkImage(pictureUrl!)
                  : null, // Use image if available
              child: pictureUrl == null
                  ? Icon(Icons.account_circle,
                      size: 60) // Default icon if no photo
                  : null,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  // color: Colors.white, for dark mode
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 71, 141, 74),
              ),
              child: Text('Accept', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: onReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 186, 38, 27),
              ),
              child: Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
