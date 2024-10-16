
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchFriendsScreen extends StatefulWidget {
  @override
  _SearchFriendsScreenState createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<DocumentSnapshot> _searchResults = [];
  Map<String, bool> _requestStatuses = {}; // Track request statuses
  String? _currentUserPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(userId);

    DocumentSnapshot userDoc = await userDocRef.get();
    if (userDoc.exists) {
      setState(() {
        _currentUserPhoneNumber = userDoc['phoneNumber'];
      });
    }
  }

  String? _validatePhoneNumber(String value) {
    String pattern = r'^\+966\d{9}$'; // Exact 9 digits after +966
    RegExp regExp = RegExp(pattern);

    if (value.isEmpty || value.trim().isEmpty) {
      return 'Phone number cannot be empty or contain only spaces';
    } else if (!regExp.hasMatch(value)) {
      return 'Phone number must start with +966 and contain exactly 9 digits';
    }
    return null;
  }

  void _searchFriendsByPhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      String query = _searchController.text.trim();
      try {
        QuerySnapshot results = await FirebaseFirestore.instance
            .collection('Users')
            .where('phoneNumber', isEqualTo: query)
            .get();

        if (results.docs.isEmpty) {
          _showDialog('Phone number does not exist');
        } else {
          setState(() {
            _searchResults = results.docs;
            _requestStatuses.clear(); // Clear previous statuses
            for (var doc in _searchResults) {
              _requestStatuses[doc.id] = false; // Not pending initially
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _fetchUserProfilePic(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        return userData['photo'] ?? ''; // Fetch the profile picture URL
      } else {
        return ''; // No profile picture
      }
    } catch (e) {
      return ''; // Return an empty string if there's an error
    }
  }

  Future<void> _sendFriendRequest(DocumentSnapshot friend) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String friendId = friend.id;

      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(friendId)
          .collection('friendRequests')
          .doc(userId)
          .get();

      if (requestDoc.exists) {
        _showDialog('Friend request already sent');
        return;
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(friendId)
          .collection('friendRequests')
          .doc(userId)
          .set({
        'userId': userId,
        'username': FirebaseAuth.instance.currentUser!.displayName,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('sentRequests')
          .doc(friendId)
          .set({
        'userId': friendId,
        'username': friend['fname'] + ' ' + friend['lname'],
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _requestStatuses[friendId] = true; // Update request status locally
      });

      _showDialog('Friend request sent successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 66, 32, 101),
                Color.fromARGB(255, 77, 64, 98),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Search Friends',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message above the phone number field
            Text(
              'Please enter a phone number starting with +966',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Enter Phone Number',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 51, 25, 57)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  suffixIcon: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 66, 32, 101),
                          Color.fromARGB(255, 77, 64, 98),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: _searchFriendsByPhoneNumber,
                    ),
                  ),
                ),
                validator: (value) => _validatePhoneNumber(value!),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot friend = _searchResults[index];
                  bool isCurrentUser = friend['phoneNumber'] == _currentUserPhoneNumber;
                  bool isPendingRequest = _requestStatuses[friend.id] ?? false; // Check local request status

                  return FutureBuilder<String>(
                    future: _fetchUserProfilePic(friend.id), // Fetch user profile picture
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }

                      final profilePicUrl = snapshot.data!;

                      return Card(
                        elevation: 3.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 66, 32, 101),
                                Color.fromARGB(255, 77, 64, 98),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            leading: profilePicUrl.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(profilePicUrl),
                                    radius: 30.0,
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.person),
                                    radius: 30.0,
                                  ),
                            title: Text(
                              friend['fname'] + ' ' + friend['lname'],
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              friend['phoneNumber'] ?? 'No Phone Number',
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: isCurrentUser
                                ? null
                                : isPendingRequest
                                    ? IconButton(
                                        icon: Icon(Icons.access_time), // Clock icon for pending status
                                        color: Colors.grey,
                                        onPressed: () {
                                          _showDialog('Friend request already sent');
                                        },
                                      )
                                    : IconButton(
                                        icon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person, color: Colors.white),
                                            Icon(Icons.add, color: Colors.white),
                                          ],
                                        ),
                                        onPressed: () => _sendFriendRequest(friend),
                                      ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SearchFriendsScreen extends StatefulWidget {
//   @override
//   _SearchFriendsScreenState createState() => _SearchFriendsScreenState();
// }

// class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   List<DocumentSnapshot> _searchResults = [];
//   Map<String, bool> _requestStatuses = {}; // Track request statuses
//   String? _currentUserPhoneNumber;

//   @override
//   void initState() {
//     super.initState();
//     _initializeUserData();
//   }

//   Future<void> _initializeUserData() async {
//     String userId = FirebaseAuth.instance.currentUser!.uid;
//     DocumentReference userDocRef =
//         FirebaseFirestore.instance.collection('Users').doc(userId);

//     DocumentSnapshot userDoc = await userDocRef.get();
//     if (userDoc.exists) {
//       setState(() {
//         _currentUserPhoneNumber = userDoc['phoneNumber'];
//       });
//     }
//   }

//   String? _validatePhoneNumber(String value) {
//     String pattern = r'^\+966\d{9}$';  // Exact 9 digits after +966
//     RegExp regExp = RegExp(pattern);

//     if (value.isEmpty || value.trim().isEmpty) {
//       return 'Phone number cannot be empty';
//     } else if (!regExp.hasMatch(value)) {
//       return 'Phone number must start with +966, 9 digits';
//     }
//     return null;
//   }

//   void _searchFriendsByPhoneNumber() async {
//     if (_formKey.currentState!.validate()) {
//       String query = _searchController.text.trim();
//       try {
//         QuerySnapshot results = await FirebaseFirestore.instance
//             .collection('Users')
//             .where('phoneNumber', isEqualTo: query)
//             .get();

//         if (results.docs.isEmpty) {
//           _showDialog('Phone number does not exist');
//         } else {
//           setState(() {
//             _searchResults = results.docs;
//             _requestStatuses.clear(); // Clear previous statuses
//             // Initialize the request status for each search result
//             for (var doc in _searchResults) {
//               _requestStatuses[doc.id] = false; // Not pending initially
//             }
//           });
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error fetching users: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _sendFriendRequest(DocumentSnapshot friend) async {
//     try {
//       String userId = FirebaseAuth.instance.currentUser!.uid;
//       String friendId = friend.id;

//       DocumentSnapshot requestDoc = await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(friendId)
//           .collection('friendRequests')
//           .doc(userId)
//           .get();

//       if (requestDoc.exists) {
//         _showDialog('Friend request already sent');
//         return;
//       }

//       await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(friendId)
//           .collection('friendRequests')
//           .doc(userId)
//           .set({
//         'userId': userId,
//         'username': FirebaseAuth.instance.currentUser!.displayName,
//         'status': 'pending',
//         'requestedAt': FieldValue.serverTimestamp(),
//       });

//       await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(userId)
//           .collection('sentRequests')
//           .doc(friendId)
//           .set({
//         'userId': friendId,
//         'username': friend['fname'] + ' ' + friend['lname'],
//         'status': 'pending',
//         'requestedAt': FieldValue.serverTimestamp(),
//       });

//       setState(() {
//         _requestStatuses[friendId] = true; // Update request status locally
//       });

//       _showDialog('Friend request sent successfully');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send request: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color.fromARGB(255, 66, 32, 101),
//                 Color.fromARGB(255, 77, 64, 98),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         title: Text(
//           'Search Friends',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.w400,
//             color: Colors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Form(
//               key: _formKey,
//               child: TextFormField(
//                 controller: _searchController,
//                 style: TextStyle(fontSize: 18),
//                 decoration: InputDecoration(
//                   labelText: 'Enter Phone Number',
//                   labelStyle: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[700],
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: const Color.fromARGB(255, 51, 25, 57)),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(
//                     vertical: 12.0,
//                     horizontal: 16.0,
//                   ),
//                   suffixIcon: Container(
//                     margin: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Color.fromARGB(255, 66, 32, 101),
//                           Color.fromARGB(255, 77, 64, 98),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: IconButton(
//                       icon: Icon(Icons.search, color: Colors.white),
//                       onPressed: _searchFriendsByPhoneNumber,
//                     ),
//                   ),
//                 ),
//                 validator: (value) => _validatePhoneNumber(value!),
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _searchResults.length,
//                 itemBuilder: (context, index) {
//                   DocumentSnapshot friend = _searchResults[index];
//                   bool isCurrentUser = friend['phoneNumber'] == _currentUserPhoneNumber;
//                   bool isPendingRequest = _requestStatuses[friend.id] ?? false; // Check local request status

//                   return Card(
//                     elevation: 3.0,
//                     margin: EdgeInsets.symmetric(vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Color.fromARGB(255, 66, 32, 101),
//                             Color.fromARGB(255, 77, 64, 98),
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                       child: ListTile(
//                         title: Text(
//                           friend['fname'] + ' ' + friend['lname'],
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           friend['phoneNumber'] ?? 'No Phone Number',
//                           style: TextStyle(color: Colors.white70),
//                         ),
//                         trailing: isCurrentUser
//                             ? null

//                             : isPendingRequest
//                                 ? IconButton(
//                                     icon: Icon(Icons.access_time), // Clock icon for pending status
//                                     color: Colors.grey,
//                                     onPressed: () {
//                                       _showDialog('Friend request already sent');
//                                     },
//                                   )
//                                 : IconButton(
//                                     icon: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(Icons.person, color: Colors.white),
//                                         Icon(Icons.add, color: Colors.white),
//                                       ],
//                                     ),
//                                     onPressed: () => _sendFriendRequest(friend),
//                                   ),

//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }