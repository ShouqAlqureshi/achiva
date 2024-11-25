import 'package:achiva/utilities/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Add this import for combineLatest2

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
  final String currentUserId = getCurrentUserId();
  List<String> sharedIDs = [
    "63c7dc8d-8ee1-495e-8e81-a647bbd124c2"
  ]; //for testing only
  Map<String, String> goalNames = {}; // Store goal names by sharedID

  DateTime _getDateTime(Map<String, dynamic> data) {
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    if (timestamp != null) return timestamp.toDate();

    Timestamp? inviteAt = data['InviteAt'] as Timestamp?;
    if (inviteAt != null) return inviteAt.toDate();

    return DateTime.now();
  }

  Future<void> _fetchGoalNames(List<String> sharedIDs) async {
    for (String sharedID in sharedIDs) {
      try {
        final goalDoc = await FirebaseFirestore.instance
            .collection('sharedGoal')
            .doc(sharedID)
            .get();

        if (goalDoc.exists) {
          final data = goalDoc.data();
          if (data != null && data.containsKey('name')) {
            goalNames[sharedID] = data['name'];
          } else {
            goalNames[sharedID] = 'Undefined Name';
          }
        }
      } catch (e) {
        print('Error fetching goal name for $sharedID: $e');
        goalNames[sharedID] = 'Undefined Name';
      }
    }
  }

  Stream<List<QueryDocumentSnapshot>> getCombinedStream() {
    // Stream for friend requests
    final friendRequestsStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('RequestsStatus')
        .orderBy('timestamp', descending: false)
        .snapshots();

    // Stream for shared IDs
    final sharedIDsStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('goals')
        .where('sharedID', isNull: false)
        .snapshots();

    // Combine the streams using RxDart's CombineLatestStream
    return CombineLatestStream.combine2(
      friendRequestsStream,
      sharedIDsStream,
      (QuerySnapshot friendRequests, QuerySnapshot sharedIDDocs) async {
        // Store shared IDs
        sharedIDs.addAll(
            sharedIDDocs.docs.map((doc) => doc['sharedID'] as String).toList());
        sharedIDDocs.docs.map((doc) => doc['sharedID'] as String).toList();

        // Fetch goal names for all shared IDs
        await _fetchGoalNames(sharedIDs);

        // Get goal invitations for each shared ID
        List<QueryDocumentSnapshot> goalInvitations = [];
        if (sharedIDs.isNotEmpty) {
          for (String sharedID in sharedIDs) {
            final invitationsSnapshot = await FirebaseFirestore.instance
                .collection('sharedGoal')
                .doc(sharedID)
                .collection('goalInvitations')
                .where('fromUserID', isEqualTo: currentUserId)
                .orderBy('InviteAt', descending: false)
                .get();
            goalInvitations.addAll(invitationsSnapshot.docs);
          }
        }

        // Combine and sort all documents
        List<QueryDocumentSnapshot> combinedDocs = [
          ...friendRequests.docs,
          ...goalInvitations
        ];

        combinedDocs.sort((a, b) {
          final dateA = _getDateTime(a.data() as Map<String, dynamic>);
          final dateB = _getDateTime(b.data() as Map<String, dynamic>);
          return dateA.compareTo(dateB);
        });

        return combinedDocs;
      },
    ).asyncMap((event) => event);
  }

  Widget _buildUserInfo(
      String userId, bool isGoalInvitation, String status, String? sharedID) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>?;
        String fullName = "Anonymous";
        String? photoUrl;

        if (userData != null) {
          String username = userData['username'] ?? "";
          String fname = userData['fname'] ?? "";
          String lname = userData['lname'] ?? "";

          fullName = username.isNotEmpty ? username : '$fname\t$lname'.trim();
          photoUrl = userData['photo'];
        }

        // Get goal name if it's a goal invitation
        String goalName = 'Undefined Name';
        if (isGoalInvitation && sharedID != null) {
          goalName = goalNames[sharedID] ?? 'Undefined Name';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
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
              Expanded(
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
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Goal Collab",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isGoalInvitation
                          ? "has $status your $goalName goal collaboration invite"
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
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: getCombinedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final combinedDocs = snapshot.data ?? [];

        if (combinedDocs.isEmpty) {
          return noResults('You have no updates on your friend requests.');
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 80),
          itemCount: combinedDocs.length,
          separatorBuilder: (context, index) => const Divider(
            color: Colors.grey,
            height: 32,
            thickness: 0.5,
            indent: 70,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            var doc = combinedDocs[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isGoalInvitation = data.containsKey('InvitationID');
            String userId =
                isGoalInvitation ? data['toUserID'] : data['userId'];
            final status =
                isGoalInvitation ? data['status'] : data['Status'] ?? "pending";
            final sharedID = isGoalInvitation ? data['sharedID'] : null;

            return _buildUserInfo(userId, isGoalInvitation, status, sharedID);
          },
        );
      },
    );
  }
}
