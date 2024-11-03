import 'dart:developer';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Sharedgoal extends StatefulWidget {
  Sharedgoal({super.key});

  @override
  State<Sharedgoal> createState() => _SharedgoalState();
}

class _SharedgoalState extends State<Sharedgoal> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

Future<void> showFriendListDialog(
    BuildContext context, String sharedID, String goalID) async {
  String userId = await FirebaseAuth.instance.currentUser!.uid;

  // Get user's friends from Firestore
  final friends = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('friends')
      .get()
      .then((snapshot) => snapshot.docs.map((doc) => doc.id).toList());

  // Check if there are any friends
  if (friends.isEmpty) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Friends Yet"),
        content:
            const Text("You don't have any friends yet. Go out and make some!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Show dialog with friend list
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Color.fromARGB(255, 77, 64, 98),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Friends", style: TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white60),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendId = friends[index];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(friendId)
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
                    fullName = '$fname $lname';
                  }

                  photoUrl = userData['photo'];
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sharedGoal')
                      .doc(sharedID)
                      .collection('goalInvitations')
                      .where('toUserID', isEqualTo: friendId)
                      .snapshots(),
                  builder: (context, inviteSnapshot) {
                    bool isInvited = false;
                    if (inviteSnapshot.hasData &&
                        inviteSnapshot.data!.docs.isNotEmpty) {
                      isInvited = true;
                    }

                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Icon(Icons.account_circle,
                                    size: 60, color: Colors.grey[400])
                                : null,
                          ),
                          title: Text(fullName,
                              style: TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: Icon(
                              isInvited
                                  ? Icons.check_circle_outline_outlined
                                  : Icons.group_add,
                              color: Colors.white70,
                            ),
                            onPressed: () async {
                              if (!isInvited) {
                                await _inviteCollaborator(
                                  context,
                                  userId,
                                  friendId,
                                  sharedID,
                                  goalID,
                                );
                              }
                            },
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

Future<bool> _inviteCollaborator(
  BuildContext context,
  String userId,
  String friendId,
  String sharedID,
  String goalID,
) async {
  try {
    final uuid = Uuid();
    final String invitationID = uuid.v4();

    QuerySnapshot requestDoc = await FirebaseFirestore.instance
        .collection('sharedGoal')
        .doc(sharedID)
        .collection("goalInvitations")
        .where('fromUserID', isEqualTo: userId)
        .where('toUserID', isEqualTo: friendId)
        .limit(1)
        .get();

    if (requestDoc.docs.isNotEmpty) {
      Flushbar(
        message: 'Invitation already sent',
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ).show(context);
      return false;
    }

    await FirebaseFirestore.instance
        .collection('sharedGoal')
        .doc(sharedID)
        .collection('goalInvitations')
        .doc(invitationID)
        .set({
      'InvitationID': invitationID,
      'goalID': goalID,
      'fromUserID': userId,
      'toUserID': friendId,
      'status': 'pending',
      'InviteAt': FieldValue.serverTimestamp(),
    });
    Flushbar(
      message: 'Friend request sent successfully',
      duration: Duration(seconds: 3),
      backgroundColor: const Color.fromARGB(255, 39, 109, 41),
    ).show(context);

    return true;
  } catch (e) {
    Flushbar(
      message: 'Failed to send Invite: $e',
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
    ).show(context);

    return false;
  }
}
