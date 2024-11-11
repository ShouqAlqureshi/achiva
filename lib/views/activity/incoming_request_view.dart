import 'dart:developer';

import 'package:achiva/utilities/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class IncomingRequestsPage extends StatefulWidget {
  const IncomingRequestsPage({Key? key}) : super(key: key);

  @override
  _IncomingRequestsPageState createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, String> goalNames = {};

  Stream<List<QueryDocumentSnapshot>> getCombinedStream() {
    final friendRequestsStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final goalInvitationsStream = FirebaseFirestore.instance
        .collectionGroup('goalInvitations')
        .where('toUserID', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return CombineLatestStream.combine2(
      friendRequestsStream,
      goalInvitationsStream,
      (QuerySnapshot friendRequests, QuerySnapshot goalInvitations) async {
        List<QueryDocumentSnapshot> combinedDocs = [
          ...friendRequests.docs,
          ...goalInvitations.docs
        ];

        // Fetch goal names for goal invitations
        for (var doc in goalInvitations.docs) {
          String sharedID = doc['sharedID'];
          await _fetchGoalName(sharedID);
        }

        return combinedDocs;
      },
    ).asyncMap((event) => event);
  }

  Future<void> _fetchGoalName(String sharedID) async {
    if (!goalNames.containsKey(sharedID)) {
      try {
        final goalDoc = await FirebaseFirestore.instance
            .collection('sharedGoal')
            .doc(sharedID)
            .get();

        if (goalDoc.exists) {
          final data = goalDoc.data();
          if (data != null && data.containsKey('goalName')) {
            goalNames[sharedID] = data['goalName'];
          } else {
            goalNames[sharedID] = 'Undefined Goal';
          }
        }
      } catch (e) {
        print('Error fetching goal name for $sharedID: $e');
        goalNames[sharedID] = 'Undefined Goal';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: getCombinedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return noResults(
              'You have no pending requests/invitations.');
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            var request = requests[index];
            var data = request.data() as Map<String, dynamic>;
            bool isGoalInvitation = data.containsKey('sharedID');
            String userId =
                isGoalInvitation ? data['fromUserID'] : data['userId'];
            String? sharedID = isGoalInvitation ? data['sharedID'] : null;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                var userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                String fullName = userData?['username'] ??
                    "${userData?['fname']} ${userData?['lname']}";
                String? photoUrl = userData?['photo'];

                return FriendRequestCard(
                  name: fullName,
                  pictureUrl: photoUrl,
                  isGoalInvitation: isGoalInvitation,
                  goalName: isGoalInvitation
                      ? goalNames[sharedID] ?? 'Loading...'
                      : null,
                  onAccept: () => _handleAccept(
                      isGoalInvitation, userId, request.id, sharedID),
                  onReject: () => _handleReject(
                      isGoalInvitation, userId, request.id, sharedID),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleAccept(bool isGoalInvitation, String userId, String requestId,
      String? sharedID) {
    if (isGoalInvitation) {
      _acceptcollab(currentUserId, sharedID!, requestId);
    } else {
      _acceptFriendRequest(currentUserId, userId, requestId);
    }
  }

  void _handleReject(bool isGoalInvitation, String userId, String requestId,
      String? sharedID) {
    if (isGoalInvitation) {
      _rejectcollab(currentUserId, sharedID!, requestId);
    } else {
      _rejectFriendRequest(currentUserId, userId, requestId);
    }
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
        .set({
      'requestId': requestId,
      'userId': currentUserId,
      'Status': "accepted",
      'timestamp': FieldValue.serverTimestamp(),
    });

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

  Future<void> _acceptcollab(
      String currentUserId, String sharedId, String invitationId) async {
    await FirebaseFirestore.instance
        .collection('sharedGoal')
        .doc(sharedId)
        .collection('goalInvitations')
        .doc(invitationId)
        .update({
      'status': "accepted",
    });
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
        .set({
      'requestId': requestId,
      'userId': currentUserId,
      'Status': "rejected",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectcollab(
      String currentUserId, String sharedId, String invitationId) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('sharedGoal')
        .doc(sharedId)
        .collection('goalInvitations')
        .doc(invitationId);

    try {
      DocumentSnapshot docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.update({'status': "rejected"});
        log('Document updated successfully.');
      } else {
        log('Document does not exist at path: ${docRef.path}');
      }
    } catch (e) {
      log('Error updating document: $e');
    }
  }
}

class FriendRequestCard extends StatelessWidget {
  final String name;
  final String? pictureUrl;
  final bool isGoalInvitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String? goalName;

  const FriendRequestCard(
      {super.key,
      required this.name,
      required this.pictureUrl,
      required this.onAccept,
      required this.onReject,
      required this.isGoalInvitation,
      required this.goalName});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              Row(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                // Wrap Text in Expanded
                                child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow:
                                  TextOverflow.ellipsis, // Handle overflow
                            )),
                          ],
                        ),
                        if (isGoalInvitation) ...[
                          SizedBox(height: 7),
                          Text(
                            "has wants to collab on $goalName ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white, // Changed text color to white for contrast
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 71, 141, 74),
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 186, 38, 27),
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        Text('Reject', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
