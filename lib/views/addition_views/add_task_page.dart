/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


<<<<<<< HEAD:lib/views/add_task_page.dart
//this is without the card
=======


>>>>>>> 6c139f0faa75141c64d1e5b9e3d48e0a92abd69a:lib/views/addition_views/add_task_page.dart
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

                    title: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 107, 33, 243),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        _tasks[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Color.fromARGB(255, 107, 33, 243),
                        ),
                      ),
                    ),

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


//this is with card 
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

      // Show a success message and navigate to the home page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and tasks added successfully')),
      );
      // Navigate to the home page instead of login
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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


//this is with task info
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _recurrenceController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _tasks = [];

  // Add a task to the list
  void _addTask() {
    if (_taskNameController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields (Task Name, Date, Time)')),
      );
      return;
    }

    setState(() {
      _tasks.add({
        'taskName': _taskNameController.text,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'location': _locationController.text.isNotEmpty ? _locationController.text : null,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime!.format(context),
        'duration': _durationController.text.isNotEmpty ? _durationController.text : null,
        'recurrence': _recurrenceController.text.isNotEmpty ? _recurrenceController.text : null,
      });

      // Clear the fields after adding the task
      _taskNameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _durationController.clear();
      _recurrenceController.clear();
      _selectedDate = null;
      _selectedTime = null;
    });
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
        });
      }

      // Add each task to the 'tasks' sub-collection under the created goal
      for (var task in _tasks) {
        await goalsCollectionRef.doc(widget.goalName).collection('tasks').add(task);
      }

      // Show a success message and navigate to the home page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and tasks added successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
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
      appBar: AppBar(title: const Text('Add Tasks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Task Name
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name (mandatory)',
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
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

              // Time Picker
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

              // Duration
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Recurrence
              TextField(
                controller: _recurrenceController,
                decoration: const InputDecoration(
                  labelText: 'Recurrence (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Add Task Button
              ElevatedButton(
                onPressed: _addTask,
                child: const Text('Add Task'),
              ),
              const SizedBox(height: 16),

              // Display Subtasks
              ListView.builder(
                shrinkWrap: true,
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return ListTile(
                    title: Text(task['taskName']),
                    subtitle: Text(task['date']),
                  );
                },
              ),

              // Save Goal Button
              ElevatedButton(
                onPressed: _saveGoal,
                child: const Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

    if (!_isTaskNameValid || !_isDateValid || !_isStartTimeValid || !_isEndTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields (Task Name, Date, Start Time, End Time)')),
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
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'location': _locationController.text.isNotEmpty ? _locationController.text : null,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'startTime': _startTime!.format(context),
        'endTime': _endTime!.format(context),
        'duration': duration,
        'recurrence': _recurrenceController.text.isNotEmpty ? _recurrenceController.text : null,
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
        });
      }

      // Add each task to the 'tasks' sub-collection under the created goal
      for (var task in _tasks) {
        await goalsCollectionRef.doc(widget.goalName).collection('tasks').add(task);
      }

      // Show a success message and navigate to the home page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and tasks added successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      // Handle any errors
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
      firstDate: today, // Prevent selecting dates before today
      lastDate: widget.goalDate, // Prevent selecting dates after goal date
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
      appBar: AppBar(title: const Text('Add Tasks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Container to hold the form fields
              Container(
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
                        border: OutlineInputBorder(),
                        errorText: _isTaskNameValid ? null : 'Task Name is required',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
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
                              color: _isStartTimeValid ? Colors.black : Colors.red,
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
                              color: _isEndTimeValid ? Colors.black : Colors.red,
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
                      keyboardType: TextInputType.number, // Digits only keyboard
                      decoration: const InputDecoration(
                        labelText: 'Recurrence (optional, numbers only)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add Task Button
              ElevatedButton(style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // Set button background color
                ),
                onPressed: _addTask,
                child: const Text('Add Task',
                  style: TextStyle(
                    color: Colors.white,
                  ),),
              ),
              const SizedBox(height: 16),

              // Display Subtasks as cards
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(task['taskName']),
                      subtitle: Text('Date: ${task['date']} | Duration: ${task['duration']}'),
                    ),
                  );
                },
              ),

              // Save Goal Button
              ElevatedButton(style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // Set button background color
                ),
                onPressed: _saveGoal,
                child: const Text('Save Goal',
                  style: TextStyle(
                    color: Colors.white,
                  ),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

