import 'package:achiva/views/activity/incoming_request_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestStatus extends StatefulWidget {
  const RequestStatus({super.key});

  @override
  State<RequestStatus> createState() => _RequestStatusState();
}

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

  DateTime _getDateTime(Map<String, dynamic> data) {
    // Check for timestamp first
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    if (timestamp != null) {
      return timestamp.toDate();
    }

    // Check for InviteAt
    Timestamp? inviteAt = data['InviteAt'] as Timestamp?;
    if (inviteAt != null) {
      return inviteAt.toDate();
    }

    return DateTime.now(); // fallback
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('RequestsStatus')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, friendRequestSnapshot) {
        if (friendRequestSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (friendRequestSnapshot.hasError) {
          return Center(child: Text('Error: ${friendRequestSnapshot.error}'));
        }

        final friendRequestsStatus = friendRequestSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sharedGoal')
              .doc("63c7dc8d-8ee1-495e-8e81-a647bbd124c2")// we need the shared key from the goals after adding 
              .collection('goalInvitations')
              .where('fromUserID', isEqualTo: currentUserId)
              .orderBy('InviteAt', descending: false)
              .snapshots(),
          builder: (context, goalInvitationSnapshot) {
            if (goalInvitationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (goalInvitationSnapshot.hasError) {
              return Center(
                  child: Text('Error: ${goalInvitationSnapshot.error}'));
            }

            final goalInvitations = goalInvitationSnapshot.data?.docs ?? [];

            if (friendRequestsStatus.isEmpty && goalInvitations.isEmpty) {
              return reuse.noPendingFriendRequestsWidget(
                  'You have no updates on your friend requests.');
            }

            final combinedList = [...friendRequestsStatus, ...goalInvitations];
            combinedList.sort((a, b) {
              final Map<String, dynamic> dataA =
                  a.data() as Map<String, dynamic>;
              final Map<String, dynamic> dataB =
                  b.data() as Map<String, dynamic>;

              DateTime dateA = _getDateTime(dataA);
              DateTime dateB = _getDateTime(dataB);

              return dateA.compareTo(dateB);
            });

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + bottomPadding + 80,
              ),
              itemCount: combinedList.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.grey,
                height: 32,
                thickness: 0.5,
                indent: 70,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                var doc = combinedList[index];
                var data = doc.data() as Map<String, dynamic>;
                bool isGoalInvitation = data.containsKey('InvitationID');
                String userId =
                    isGoalInvitation ? data['fromUserID'] : data['userId'];
                final status = isGoalInvitation
                    ? data['status']
                    : data['Status'] ?? "pending";

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Icon(Icons.account_circle,
                                    size: 60, color: Colors.grey[400])
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fullName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isGoalInvitation) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Goal Collab",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  isGoalInvitation
                                      ? "has $status your goal collaboration invite"
                                      : "has $status your friend request",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Icon(
                            status == "accepted"
                                ? Icons.check_circle
                                : status == "rejected"
                                    ? Icons.circle
                                    : Icons.access_time_filled,
                            color: status == "accepted"
                                ? Colors.green
                                : status == "rejected"
                                    ? Colors.red
                                    : const Color.fromARGB(255, 90, 89, 89),
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
      },
    );
  }
}
