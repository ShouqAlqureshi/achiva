import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskPage extends StatefulWidget {
  final String goalName;
  final DateTime goalDate;
  final bool goalVisibility;

  const AddTaskPage({
    Key? key,
    required this.goalName,
    required this.goalDate,
    required this.goalVisibility,
  }) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _taskController = TextEditingController();
  List<String> _tasks = [];

  // Add a task to the list
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_taskController.text);
      });
      _taskController.clear();
    }
  }

  // Save the goal and tasks to Firestore for the user with the same phone number as the logged-in user
  Future<void> _saveGoal() async {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one task')),
      );
      return;
    }

    try {
      // Get the current logged-in user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // Get the current logged-in user's phone number
      final String? userPhoneNumber = user.phoneNumber;

      if (userPhoneNumber == null) {
        throw Exception("Phone number is not available for the logged-in user.");
      }

      // Query the Firestore 'Users' collection for a user with the same phone number
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('phoneNumber', isEqualTo: userPhoneNumber)
          .limit(1)
          .get();

      DocumentReference userDocRef;

      if (userSnapshot.docs.isEmpty) {
        // If no user found, create a new user with the phone number
        userDocRef = await FirebaseFirestore.instance.collection('Users').add({
          'phoneNumber': userPhoneNumber,
          // Add other user details if needed here
        });
      } else {
        // If user exists, get their document reference
        userDocRef = userSnapshot.docs.first.reference;
      }

      // Check if the 'goals' sub-collection exists for the user
      CollectionReference goalsCollectionRef = userDocRef.collection('goals');

      DocumentSnapshot goalSnapshot =
          await goalsCollectionRef.doc(widget.goalName).get();

      if (!goalSnapshot.exists) {
        // If the goal doesn't exist, create it using the goal name as the document ID
        await goalsCollectionRef.doc(widget.goalName).set({
          'name': widget.goalName,
          'date': widget.goalDate.toIso8601String(),
          'visibility': widget.goalVisibility,
          'notasks': _tasks.length,
          'progress': 50, // You can adjust this based on task completion
        });
      }

      // Add each task to the 'tasks' sub-collection under the created goal
      for (String task in _tasks) {
        await goalsCollectionRef
            .doc(widget.goalName)
            .collection('tasks')
            .add({
          'task': task,
        });
      }

      // Show a success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and tasks added successfully')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tasks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTask,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_tasks[index]),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveGoal,
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}
