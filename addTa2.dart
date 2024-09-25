import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // for formatting dates and times

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
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _recurrenceController = TextEditingController();

  // Save the goal and tasks to Firestore for the user with the same phone number as the logged-in user
  Future<void> _saveTask() async {
    if (_taskNameController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all mandatory fields (Task Name, Date, Time)')),
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
        });
      }

      // Add the task to the 'tasks' sub-collection under the created goal
      await goalsCollectionRef
          .doc(widget.goalName)
          .collection('tasks')
          .add({
        'taskName': _taskNameController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime!.format(context),
        'duration': _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
        'recurrence': _recurrenceController.text.isNotEmpty
            ? _recurrenceController.text
            : null,
      });

      // Show a success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: $e')),
      );
    }
  }

  // Method to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Method to select time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name (mandatory)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate != null
                        ? 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                        : 'Select Date (mandatory)'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedTime != null
                        ? 'Time: ${_selectedTime!.format(context)}'
                        : 'Select Time (mandatory)'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectTime(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recurrenceController,
                decoration: const InputDecoration(
                  labelText: 'Recurrence (optional)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveTask,
                child: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
