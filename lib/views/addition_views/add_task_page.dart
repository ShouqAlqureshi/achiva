import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Needed for input formatters

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
  final TextEditingController _recurrenceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<Map<String, dynamic>> _tasks = [];

  bool _isTaskNameValid = true;
  bool _isDateValid = true;
  bool _isStartTimeValid = true;
  bool _isEndTimeValid = true;

  // Add a task to the list
  void _addTask() {
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
        const SnackBar(
            content: Text(
                'Please fill in all required fields (Task Name, Date, Start Time, End Time)')),
      );
      return;
    }

    // Calculate the duration in hours and minutes
    final startTimeInMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endTimeInMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final durationInMinutes = endTimeInMinutes - startTimeInMinutes;
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    final duration = '${hours}h ${minutes}m';

    setState(() {
      _tasks.add({
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
        'duration': duration,
        'recurrence': _recurrenceController.text.isNotEmpty
            ? _recurrenceController.text
            : null,
      });

      // Clear the fields after adding the task
      _taskNameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _recurrenceController.clear();
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
    });
  }

  // Save the goal and tasks to Firestore
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
        // If no user found, create a new user
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
        // If the goal doesn't exist, create it
        await goalsCollectionRef.doc(widget.goalName).set({
          'name': widget.goalName,
          'date': widget.goalDate.toIso8601String(),
          'visibility': widget.goalVisibility,
          'notasks': _tasks.length,
        });
      }

      // Add tasks to Firestore
      for (var task in _tasks) {
        await goalsCollectionRef
            .doc(widget.goalName)
            .collection('tasks')
            .add(task);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and tasks added successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tasks'),backgroundColor: Colors.grey[200]),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Container to hold the form fields
              Container(
                  alignment: Alignment.center,  // Centers the content inside the container
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
                    TextField(
                      controller: _recurrenceController,
                      keyboardType: TextInputType.number, // Only digits allowed
                      decoration: InputDecoration(
                        labelText: 'Recurrence (optional, numbers only)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded edges
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Row for Add Task and Save Goal Buttons, make them closer to each other
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
                    onPressed: _addTask,
                    child: const Text(
                      'Add Task',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Space between buttons
                  // Save Goal Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurple, // Set button background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12), // Add padding
                    ),
                    onPressed: _saveGoal,
                    child: const Text(
                      'Save Goal',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display Subtasks as cards centered
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Center(
                    // Center the card
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(task['taskName']),
                        subtitle: Text(
                            'Date: ${task['date']} | Duration: ${task['duration']}'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
