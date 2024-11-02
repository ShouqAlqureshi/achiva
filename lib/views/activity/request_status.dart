import 'package:achiva/views/activity/incoming_request_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestStatus extends StatefulWidget {
  const RequestStatus({super.key});

  @override
  State<RequestStatus> createState() => _RequestStatusState();
}

// Fetch current user ID
String getCurrentUserId() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }
  return user.uid;
}

class _RequestStatusState extends State<RequestStatus> {
  final reuse = IncomingRequestsPage();
  String currentUserId = getCurrentUserId();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('RequestsStatus')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final friendRequestsStatus = snapshot.data?.docs ?? [];
        if (friendRequestsStatus.isEmpty) {
          return reuse.noPendingFriendRequestsWidget(
              'You have no updates on your friend requests.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: friendRequestsStatus.length,
          separatorBuilder: (context, index) => const Divider(
            color: Colors.grey,
            height: 32, // Total height of the divider area
            thickness: 0.5, // Actual line thickness
            indent: 70, // Left padding to align with text
            endIndent: 16, // Right padding
          ),
          itemBuilder: (context, index) {
            var doc = friendRequestsStatus[index];
            var friendRequestData = doc.data() as Map<String, dynamic>;
            String userId = friendRequestData['userId'];
            final reqstatus = friendRequestData["Status"] ?? "pending";

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                    fullName = '$fname\t$lname';
                  }

                  photoUrl = userData['photo'];
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Avatar - fixed size
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(Icons.account_circle,
                                size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      const SizedBox(width: 15),
                      // Text content - flexible and constrained
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                            Text(
                              "has $reqstatus your friend request",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Status icon - fixed size
                      Icon(
                        reqstatus == "accepted"
                            ? Icons.check_circle
                            : Icons.circle,
                        color:
                            reqstatus == "accepted" ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 15),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
