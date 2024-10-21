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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Friend Requests'),
        centerTitle: true,
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
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final friendRequests = snapshot.data?.docs ?? [];
          if (friendRequests.isEmpty) {
            return noPendingFriendRequestsWidget();
          }

          return StreamBuilder<List<DocumentSnapshot>>(
            stream: _filteredFriendRequestsStream(friendRequests),
            builder: (context, filteredSnapshot) {
              if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final filteredFriendRequests = filteredSnapshot.data ?? [];
              if (filteredFriendRequests.isEmpty) {
                return noPendingFriendRequestsWidget();
              }

              return ListView(
                children: filteredFriendRequests.map((doc) {
                  var friendRequestData = doc.data() as Map<String, dynamic>;
                  String userId = friendRequestData['userId'];
                  String requestId = friendRequestData['requestId'];
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;

                      String fullName = "Anonymous";
                      String? photoUrl;

                      if (userData != null) {
                        String username = userData['username'] ?? "";
                        String fname = userData['fname'] ?? "";
                        String lname = userData['lname'] ?? "";

                        if (username.isNotEmpty) {
                          fullName = username;
                        } else if (fname.isNotEmpty || lname.isNotEmpty) {
                          fullName = '$fname $lname'.trim();
                        }

                        photoUrl = userData['photo'];
                      }

                      return FriendRequestCard(
                        name: fullName,
                        pictureUrl: photoUrl,
                        onAccept: () {
                          _acceptFriendRequest(
                              currentUserId, userId, requestId);
                        },
                        onReject: () {
                          _rejectFriendRequest(
                              currentUserId, userId, requestId);
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // Stream for filtering valid friend requests
  Stream<List<DocumentSnapshot>> _filteredFriendRequestsStream(
      List<DocumentSnapshot> friendRequests) async* {
    List<DocumentSnapshot> validFriendRequests = [];

    for (var request in friendRequests) {
      var friendRequestData = request.data() as Map<String, dynamic>;
      String userId = friendRequestData['userId'];

      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        validFriendRequests.add(request);
      }
    }

    yield validFriendRequests;
  }

  Widget noPendingFriendRequestsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'lib/images/no-results.png',
                fit: BoxFit.contain,
                height: 100,
              ),
              SizedBox(height: 40),
              Text(
                'You have no pending friend requests.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acceptFriendRequest(
      String currentUserId, String friendId, String requestId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(friendId)
        .delete();

    FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('sentRequests')
        .doc(currentUserId)
        .delete();

    FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('RequestsStatus')
        .doc(requestId)
        .set({'requestId': requestId, 'Status': "accepted"});


    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .set({'userId': friendId});

    FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUserId)
        .set({'userId': currentUserId});
  }

  void _rejectFriendRequest(
      String currentUserId, String friendId, String requestId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(friendId)
        .delete();

    FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('sentRequests')
        .doc(currentUserId)
        .delete();

    FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('RequestsStatus')
        .doc(requestId)
        .set({'requestId': requestId, 'Status': "rejected"});
  }
}

class FriendRequestCard extends StatelessWidget {
  final String name;
  final String? pictureUrl;
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
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)), // Made corners more rounded
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(255, 66, 32, 101),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(15), // Increased padding slightly
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.9),
                backgroundImage:
                    pictureUrl != null ? NetworkImage(pictureUrl!) : null,
                child: pictureUrl == null
                    ? Icon(Icons.account_circle,
                        size: 60, color: Colors.grey[400])
                    : null,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors
                        .white, // Changed text color to white for contrast
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 71, 141, 74),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Accept', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: onReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 186, 38, 27),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
