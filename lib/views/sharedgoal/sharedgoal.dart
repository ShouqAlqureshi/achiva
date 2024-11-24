import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SharedGoalManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSharedGoal({
    required String goalName,
    required String date,
    required bool visibility,
    required String sharedID,
    required String goalID,
    required BuildContext context,
    required bool isOwner,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Add to sharedGoal collection
      await _firestore.collection('sharedGoal').doc(sharedID).set({
        'name': goalName,
        'date': date,
        'visibility': visibility,
        'notasks': 0,
        'sharedID': sharedID,
        'goalID': goalID,
        'createdBy': user.uid,
        'participants': {
          user.uid: {
            'role': isOwner ? 'owner' : 'participant',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        }
      });

      // Also add to user's personal goals collection
      final userRef = _firestore.collection('Users').doc(user.uid);
      await userRef.collection('goals').doc(goalID).set({
        'name': goalName,
        'date': date,
        'visibility': visibility,
        'notasks': 0,
        'sharedID': sharedID,
        'isShared': true,
      });
    } catch (e) {
      print('Error creating shared goal: $e');
      throw e;
    }
  }

  Future<void> addTaskToSharedGoal({
    required String sharedID,
    required Map<String, dynamic> taskData,
    required BuildContext context,
  }) async {
    try {
      // Add task only to sharedGoal collection
      await FirebaseFirestore.instance
          .collection('sharedGoal')
          .doc(sharedID)
          .collection('tasks')
          .add({
        ...taskData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // Update task count
      await _firestore.collection('sharedGoal').doc(sharedID).update({
        'notasks': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding task to shared goal: $e');
      throw e;
    }
  }

  Future<void> addParticipant(String sharedID, String userID) async {
    try {
      await _firestore.collection('sharedGoal').doc(sharedID).update({
        'participants.$userID': {
          'role': 'participant',
          'joinedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('Error adding participant: $e');
      throw e;
    }
  }

  Future<void> handleInvitationResponse({
    required String invitationID,
    required String sharedID,
    required String goalID,
    required String response,
    required BuildContext context,
  }) async {
    try {
      final String userId = _auth.currentUser!.uid;

      // Get user's details
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Update invitation status
      await _firestore
          .collection('sharedGoal')
          .doc(sharedID)
          .collection('goalInvitations')
          .doc(invitationID)
          .update({
        'status': response,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (response == 'accepted') {
        // Get the shared goal data
        final sharedGoalDoc =
            await _firestore.collection('sharedGoal').doc(sharedID).get();
        if (!sharedGoalDoc.exists) {
          throw Exception('Shared goal not found');
        }

        final sharedGoalData = sharedGoalDoc.data()!;

        // Create participant data
        final participantData = {
          'userId': userId,
          'phoneNumber': userData['phoneNumber'],
          'role': 'participant',
          'joinedAt': FieldValue.serverTimestamp()
        };

        // Add participant to the shared goal
        await _firestore.collection('sharedGoal').doc(sharedID).update({
          'participants': FieldValue.arrayUnion([participantData])
        });

        // Add the goal to the participant's personal goals
        await _firestore
            .collection('Users')
            .doc(userId)
            .collection('goals')
            .doc(goalID)
            .set({
          ...sharedGoalData,
          'sharedID': sharedID,
          'isShared': true,
          'userRole': 'participant'
        });

        _showSuccessMessage(context, 'Successfully joined shared goal');
      }

      _showSuccessMessage(
          context, 'Invitation ${response.toLowerCase()} successfully');
    } catch (e) {
      _showErrorMessage(context, 'Failed to process invitation: $e');
    }
  }

  Future<void> leaveSharedGoal({
    required String sharedID,
    required String goalID,
    required BuildContext context,
  }) async {
    try {
      final String userId = _auth.currentUser!.uid;

      // Get the shared goal to check user's role
      final sharedGoalDoc =
          await _firestore.collection('sharedGoal').doc(sharedID).get();
      if (!sharedGoalDoc.exists) {
        throw Exception('Shared goal not found');
      }

      final sharedGoalData = sharedGoalDoc.data()!;

      // Check if user is the owner
      if (sharedGoalData['owner']['userId'] == userId) {
        // If owner is leaving, archive the goal instead of deleting
        await _firestore.collection('sharedGoal').doc(sharedID).update({
          'status': 'archived',
          'archivedAt': FieldValue.serverTimestamp(),
          'archivedBy': userId
        });

        // Notify all participants that the goal has been archived
        // Implementation of notification system would go here
      } else {
        // If participant is leaving, remove them from participants array
        final participants = List.from(sharedGoalData['participants']);
        participants.removeWhere((p) => p['userId'] == userId);

        await _firestore
            .collection('sharedGoal')
            .doc(sharedID)
            .update({'participants': participants});
      }

      // Remove goal from user's personal goals
      await _firestore
          .collection('Users')
          .doc(userId)
          .collection('goals')
          .doc(goalID)
          .delete();

      _showSuccessMessage(context, 'Successfully left shared goal');
    } catch (e) {
      _showErrorMessage(context, 'Failed to leave shared goal: $e');
    }
  }

  // Future<void> addTaskToSharedGoal({
  //   required String sharedID,
  //   required Map<String, dynamic> taskData,
  //   required BuildContext context,
  // }) async {
  //   try {
  //     final String userId = _auth.currentUser!.uid;

  //     // Add creator information to task data
  //     final enhancedTaskData = {
  //       ...taskData,
  //       'createdBy': userId,
  //       'createdAt': FieldValue.serverTimestamp(),
  //     };

  //     // Add task to shared goal's tasks collection
  //     await _firestore
  //         .collection('sharedGoal')
  //         .doc(sharedID)
  //         .collection('tasks')
  //         .add(enhancedTaskData);

  //     // Update task count
  //     await _firestore
  //         .collection('sharedGoal')
  //         .doc(sharedID)
  //         .update({
  //       'notasks': FieldValue.increment(1)
  //     });

  //     _showSuccessMessage(context, 'Task added to shared goal successfully');
  //   } catch (e) {
  //     _showErrorMessage(context, 'Failed to add task to shared goal: $e');
  //   }
  // }

  // Helper methods remain the same
  void _showSuccessMessage(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: Color.fromARGB(255, 39, 109, 41),
    ).show(context);
  }

  void _showErrorMessage(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
    ).show(context);
  }
}

class _SharedgoalState {
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
      "sharedID": sharedID,
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
