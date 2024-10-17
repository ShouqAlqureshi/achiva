import 'dart:developer';

import 'package:achiva/views/addition_views/add_redundence_tasks.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Needed for input formatters

class AddTaskIndependentlyPage extends StatefulWidget {
  final String goalName;
  final DateTime goalDate;
  final bool goalVisibility;

  const AddTaskIndependentlyPage({
    super.key,
    required this.goalName,
    required this.goalDate,
    required this.goalVisibility,
  });

  @override
  _AddTaskIndependentlyPageState createState() =>
      _AddTaskIndependentlyPageState();
}

class _AddTaskIndependentlyPageState extends State<AddTaskIndependentlyPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedRecurrence;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<Map<String, dynamic>> createdTasks = [];
  Map<String, dynamic> taskData = {};
  final taskManager = RecurringTaskManager();
  bool _isTaskNameValid = true;
  bool _isDateValid = true;
  bool _isStartTimeValid = true;
  bool _isEndTimeValid = true;

  // Add a task to the list
  Future<void> _createGoalAndAddTask() async {
    setState(() {
      _isTaskNameValid = _taskNameController.text.isNotEmpty;
      _isDateValid = _selectedDate != null;
      _isStartTimeValid = _startTime != null;
      _isEndTimeValid = _endTime != null;
    });
    if (!_isTaskNameValid ||
        !_isDateValid ||
        !_isStartTimeValid ||
        !_isEndTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String? userPhoneNumber = user.phoneNumber;
      if (userPhoneNumber == null) {
        throw Exception(
            "Phone number is not available for the logged-in user.");
      }

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('phoneNumber', isEqualTo: userPhoneNumber)
          .limit(1)
          .get();

      DocumentReference userDocRef;
      if (userSnapshot.docs.isEmpty) {
        userDocRef = await FirebaseFirestore.instance.collection('Users').add({
          'phoneNumber': userPhoneNumber,
        });
      } else {
        userDocRef = userSnapshot.docs.first.reference;
      }

      CollectionReference goalsCollectionRef = userDocRef.collection('goals');
      DocumentSnapshot goalSnapshot =
          await goalsCollectionRef.doc(widget.goalName).get();

      if (!goalSnapshot.exists) {
        log("the goal name does not exists.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("the goal name does not exists.")),
        );
        return;
      }
      // Create the goal
      await goalsCollectionRef.doc(widget.goalName).set({
        'name': widget.goalName,
        'date': widget.goalDate.toIso8601String(),
        'visibility': widget.goalVisibility,
        'notasks': 1, // Initially set to 1 as we're adding one task
      });

      // Prepare task data
      taskData = {
        'taskName': _taskNameController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'startTime': _startTime!.format(context),
        'endTime': _endTime!.format(context),
        'recurrence': _selectedRecurrence ?? 'No recurrence',
      };

      // Add the task
      if (_selectedRecurrence == "Weekly") {
        createdTasks = await taskManager.addRecurringTask(
          goalName: widget.goalName,
          startDate: _selectedDate!, // Ensure _selectedDate is non-null
          startTime: _startTime!, // Ensure _startTime is non-null
          endTime: _endTime!, // Ensure _endTime is non-null
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null, // Safely pass null if location is empty
          recurrenceType: _selectedRecurrence ??
              'No recurrence', // Default to 'No recurrence'
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null, // Safely pass null if description is empty
          taskName: _taskNameController.text,
          usergoallistrefrence: goalsCollectionRef,
          goalDate: widget.goalDate,
        );

        if (createdTasks.isNotEmpty) {
          log("Recurring tasks created successfully");
          await goalsCollectionRef
              .doc(widget.goalName)
              .update({'notasks': FieldValue.increment(createdTasks.length)});
        }
      } else {
        await goalsCollectionRef
            .doc(widget.goalName)
            .collection('tasks')
            .add(taskData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('task added successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      log("$e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  // Method to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: widget.goalDate,
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Method to select start time
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  // Method to select end time
  Future<void> _selectEndTime(BuildContext context) async {
    // Ensure that the start time is selected before allowing the user to pick an end time
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time first.')),
      );
      return; // Exit the method early if no start time is set
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _endTime) {
      // Convert both times to DateTime for comparison
      final DateTime startDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final DateTime endDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Check if the selected end time is before the start time
      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End time cannot be before start time.')),
        );
      } else {
        setState(() {
          _endTime = pickedTime; // Update the end time if valid
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Add Tasks'), backgroundColor: Colors.grey[200]),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Container to hold the form fields
              Container(
                alignment: Alignment
                    .center, // Centers the content inside the container
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Task Name
                    TextField(
                      controller: _taskNameController,
                      maxLength: 100, // Set the maximum number of characters
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Task Name (mandatory)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded edges
                        ),
                        errorText:
                            _isTaskNameValid ? null : 'Task Name is required',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      maxLength: 100, // Set the maximum number of characters
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded edges
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextField(
                      controller: _locationController,
                      maxLength: 100, // Set the maximum number of characters
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded edges
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                                : 'Select Date (mandatory)',
                            style: TextStyle(
                              color: _isDateValid ? Colors.black : Colors.red,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _startTime != null
                                ? 'Start Time: ${_startTime!.format(context)}'
                                : 'Select Start Time (mandatory)',
                            style: TextStyle(
                              color:
                                  _isStartTimeValid ? Colors.black : Colors.red,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _selectStartTime(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // End Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _endTime != null
                                ? 'End Time: ${_endTime!.format(context)}'
                                : 'Select End Time (mandatory)',
                            style: TextStyle(
                              color:
                                  _isEndTimeValid ? Colors.black : Colors.red,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _selectEndTime(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recurrence
                    DropdownButtonFormField<String>(
                      value: _selectedRecurrence,
                      decoration: InputDecoration(
                        labelText: 'Recurrence',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          enabled: true,
                          child: Text('No recurrence'),
                        ),
                        DropdownMenuItem(
                            value: 'Weekly', child: Text('Weekly recurrence')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRecurrence = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add Task Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurple, // Set button background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12), // Add padding
                    ),
                    onPressed: _createGoalAndAddTask,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
