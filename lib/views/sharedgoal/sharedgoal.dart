import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Sharedgoal extends StatefulWidget {
  const Sharedgoal({super.key});

  @override
  State<Sharedgoal> createState() => _SharedgoalState();

  Future<void> showFriendListDialog(BuildContext context) async {
    // Get user's friends from Firestore
    final friends = await FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('friends')
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => doc.id).toList());

    // Check if there are any friends
    if (friends.isEmpty) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No Friends Yet"),
          content: const Text(
              "You don't have any friends yet. Go out and make some!"),
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
          width: double.maxFinite, // Optional: Set width to max
          height: 300, // Specify a height for the dialog
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

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? Icon(Icons.account_circle,
                                  size: 60, color: Colors.grey[400])
                              : null,
                        ),
                        title: Text(fullName,
                            style: TextStyle(color: Colors.white70)),
                        // trailing: IconButton(
                        //   icon: const Icon(Icons.group_add,
                        //       color: Colors.white70),
                        //   onPressed: () =>
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => Sharedgoal()),
                        //   ),
                        // ),
                      ),
                      const Divider(), // Add a divider between friends
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SharedgoalState extends State<Sharedgoal> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
