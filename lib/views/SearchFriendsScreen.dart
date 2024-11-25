import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/services.dart';

import 'package:uuid/uuid.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  _SearchFriendsScreenState createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController(text: '5');  // Initialize with '5'
  final _formKey = GlobalKey<FormState>();
  List<DocumentSnapshot> _searchResults = [];
  var _accept = false;
  final Map<String, bool> _requestStatuses = {};
  String? _currentUserPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    // Set cursor position after the pre-filled '5'
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length)
    );
    
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
    String pattern = r'^\d{8}$'; // Changed to 8 digits since '5' is pre-filled
    RegExp regExp = RegExp(pattern);

    if (value.isEmpty || value.trim().isEmpty) {
      return 'Phone number cannot be empty';
    } else if (!regExp.hasMatch(value.substring(1))) { // Check only the last 8 digits
      return 'Phone number must be 8 digits after 5';
    }
    return null;
  }

  Future<void> _searchFriendsByPhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      String query = "+9665" + _searchController.text.substring(1).trim();
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
            _requestStatuses.clear();
          });
          for (var doc in _searchResults) {
            await _checkFriendRequestStatus(doc.id);
          }
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

  // Check if a friend request is already sent
  Future<void> _checkFriendRequestStatus(String friendId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .collection('friendRequests')
        .doc(userId)
        .get();

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('RequestsStatus')
        .get()
        .then((value) {
      var exist = false;
      var stat = "pendding";
      for (var i in value.docs) {
        if (i.data()["userId"] == friendId) {
          exist = true;
          stat = i.data()["Status"];
        }
      }
      if (exist == true && stat == "accepted") {
       
         setState(() {
            _accept =
              true;
          });
         print("ok");
      } else {
      
          setState(() {
            _requestStatuses[friendId] =
              requestDoc.exists;
          }); // Set status based on existence
      }
    });
    print(_accept);
  }

  Future<String> _fetchUserProfilePic(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

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
       DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();
    
    String currentUserName = '${currentUserDoc['fname']} ${currentUserDoc['lname']}';
      String friendId = friend.id;
      final Uuid uuid = Uuid();
      final String requestId = uuid.v4();

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
        'requestId': requestId,
        'username':currentUserName,
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
        'requestId': requestId,
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

  // Prevent spaces in the phone number field
  void _removeWhitespace() {
    _searchController.text = _searchController.text.replaceAll(' ', '');
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.black),
              ),
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
            Text(
              'Please enter a phone number in this format:[5xxxxxxxx]"',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),

            Form(
              key: _formKey,
              child: TextFormField(
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 18),
                controller: _searchController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(9),  // Total length including pre-filled '5'
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  prefixText: '+966',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  labelText: 'Enter Phone Number',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 51, 25, 57),
                    ),
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
                      onPressed: () {
                        _removeWhitespace();
                        _searchFriendsByPhoneNumber();
                      },
                    ),
                  ),
                ),
                validator: (value) => _validatePhoneNumber(value!),
                onChanged: (value) {
                  // Ensure '5' is always at the start
                  if (!value.startsWith('5')) {
                    _searchController.text = '5' + (value.isNotEmpty ? value.substring(value.length - 1) : '');
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length)
                    );
                  }
                  _removeWhitespace();
                },
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot friend = _searchResults[index];
                  bool isCurrentUser =
                      friend['phoneNumber'] == _currentUserPhoneNumber;

                  bool isPendingRequest = _requestStatuses[friend.id] ?? false;

                  return FutureBuilder<String>(
                    future: _fetchUserProfilePic(
                        friend.id), // Fetch user profile picture
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.grey)),
                        );
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
                                    radius: 30.0,
                                    child: Icon(Icons.person),
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
                                        icon: Icon(Icons
                                            .access_time), // Clock icon for pending status
                                        color: Colors.grey,
                                        onPressed: () {
                                          _showDialog(
                                              'Friend request already sent');
                                        },
                                      )
                                    : _accept?null: IconButton(
                                        icon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person,
                                                color: Colors.white),
                                            Icon(Icons.add,
                                                color: Colors.white),
                                          ],
                                        ),
                                        onPressed: () =>
                                            _sendFriendRequest(friend),
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