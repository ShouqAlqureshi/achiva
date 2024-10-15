/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchFriendsScreen extends StatefulWidget {
  @override
  _SearchFriendsScreenState createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

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
    if (!userDoc.exists) {
      await userDocRef.set({
        'username': FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',
        'phoneNumber': FirebaseAuth.instance.currentUser!.phoneNumber ?? 'N/A',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await userDocRef.collection('friendRequests').get();
    await userDocRef.collection('sentRequests').get();
    await userDocRef.collection('friends').get();
  }

  void _searchFriendsByPhoneNumber() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        QuerySnapshot results = await FirebaseFirestore.instance
            .collection('Users')
            .where('phoneNumber', isEqualTo: query)
            .get();

        if (results.docs.isEmpty) {
          // No users found with the given phone number
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No users found with that phone number.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            _searchResults = results.docs;
          });
        }
      } catch (e) {
        // Log the error and show a message
        print('Error fetching users: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(DocumentSnapshot friend) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String friendId = friend.id;

      DocumentReference requestRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(friendId)
          .collection('friendRequests')
          .doc(userId);

      await requestRef.set({
        'userId': userId,
        'username': FirebaseAuth.instance.currentUser!.displayName,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      DocumentReference sentRequestRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('sentRequests')
          .doc(friendId);

      await sentRequestRef.set({
        'userId': friendId,
        'username': friend['fname'] + ' ' + friend['lname'], // Assuming you want to display the full name
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(DocumentSnapshot request) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String friendId = request.id;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('friendRequests')
          .doc(friendId)
          .update({'status': 'accepted'});

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .set({
        'userId': friendId,
        'username': request['username'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(friendId)
          .collection('friends')
          .doc(userId)
          .set({
        'userId': userId,
        'username': FirebaseAuth.instance.currentUser!.displayName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(DocumentSnapshot request) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String friendId = request.id;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('friendRequests')
          .doc(friendId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request rejected!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot> _getFriendRequests() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> _getFriends() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('friends')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Friends',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
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
                  borderSide: BorderSide(color: Colors.purple),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _searchFriendsByPhoneNumber,
              child: Text(
                'Search',
                style: TextStyle(fontSize: 18,color: Colors.white,),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot friend = _searchResults[index];
                  return Card(
                    elevation: 3.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(friend['fname'] + ' ' + friend['lname']),
                      subtitle: Text(friend['phoneNumber'] ?? 'No Phone Number'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        color: Colors.blue,
                        onPressed: () => _sendFriendRequest(friend),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Incoming Friend Requests Section
            Text(
              'Incoming Friend Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFriendRequests(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final requests = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot request = requests[index];
                      return Card(
                        elevation: 3.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(request['username'] ?? 'Unknown User'),
                          subtitle: Text('Pending...'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                color: Colors.green,
                                onPressed: () => _acceptFriendRequest(request),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                color: Colors.red,
                                onPressed: () => _rejectFriendRequest(request),
                              ),
                            ],
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
*/
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
    String pattern = r'^\+966\d{8,12}$';
    RegExp regExp = RegExp(pattern);

    if (value.isEmpty || value.trim().isEmpty) {
      return 'Phone number cannot be empty or contain only spaces';
    } else if (!regExp.hasMatch(value)) {
      return 'Phone number must start with +966 and contain 8-12 digits';
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
      appBar: AppBar(
        title: Text(
          'Search Friends',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    borderSide: BorderSide(color: Colors.purple),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
                validator: (value) => _validatePhoneNumber(value!),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchFriendsByPhoneNumber,
              child: Text(
                'Search',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot friend = _searchResults[index];
                  bool isCurrentUser = friend['phoneNumber'] == _currentUserPhoneNumber;

                  return Card(
                    elevation: 3.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(friend['fname'] + ' ' + friend['lname']),
                      subtitle: Text(friend['phoneNumber'] ?? 'No Phone Number'),
                      trailing: isCurrentUser
                          ? null
                          : IconButton(
                              icon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person),
                                  Icon(Icons.add),
                                ],
                              ),
                              color: Colors.blue,
                              onPressed: () => _sendFriendRequest(friend),
                            ),
                    ),
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
