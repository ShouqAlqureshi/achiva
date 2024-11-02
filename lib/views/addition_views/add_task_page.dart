// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:achiva/utilities/loading.dart';
import 'package:achiva/views/addition_views/add_redundence_tasks.dart';
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
    super.key,
    required this.goalName,
    required this.goalDate,
    required this.goalVisibility,
  });

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedRecurrence;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<Map<String, dynamic>> createdTasks = [];
  final taskManager = RecurringTaskManager();
  Map<String, dynamic> taskData = {};
  bool _isTaskNameValid = true;
  bool _isDateValid = true;
  bool _isStartTimeValid = true;
  bool _isEndTimeValid = true;

  // Add a task to the list
  Future<void> _createGoalAndAddTask() async {
    showLoadingDialog(context);
    setState(() {
      _isTaskNameValid = _taskNameController.text.isNotEmpty;
      _isDateValid = _selectedDate != null;
      _isStartTimeValid = _startTime != null;
      _isEndTimeValid = _endTime != null &&
          (_endTime!.hour > _startTime!.hour ||
              (_endTime!.hour == _startTime!.hour &&
                  _endTime!.minute > _startTime!.minute));
    });

    if (!_isTaskNameValid ||
        !_isDateValid ||
        !_isStartTimeValid ||
        !_isEndTimeValid) {
      Navigator.of(context).pop(); //dismiss loading
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

      if (goalSnapshot.exists) {
        log("The goal name exists, try changing the name");
        Navigator.of(context).pop(); //dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("The goal name exists, try changing the name")),
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
              : null,
          recurrenceType: _selectedRecurrence ??
              'No recurrence', // Default to 'No recurrence'
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          taskName: _taskNameController.text,
          usergoallistrefrence: goalsCollectionRef,
          goalDate: widget.goalDate,
        );

        if (createdTasks.isNotEmpty) {
          log("Recurring tasks created successfully");
          await goalsCollectionRef.doc(widget.goalName).update({
            'notasks': FieldValue.increment(createdTasks
                .length) // -1 because we already set it to 1 initially
          });
        }
      } else {
        await goalsCollectionRef
            .doc(widget.goalName)
            .collection('tasks')
            .add(taskData);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
      // Show success message only when the goal and task are successfully created
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Goal created and task added successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      log("$e");
      Navigator.of(context).pop(); //dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating goal and adding task: $e')),
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
      // Check if the end time is earlier than the start time
      if (_startTime != null && pickedTime.hour < _startTime!.hour ||
          (_startTime!.hour == pickedTime.hour &&
              pickedTime.minute <= _startTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End Time cannot be earlier than Start Time.')),
        );
        return; // Do not update the end time
      }

      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Add Tasks',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Space for AppBar
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 5)
                    ],
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Task Name Field (unchanged)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Task Name',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _taskNameController,
                            maxLength: 50,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'^\s*$')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Enter task name',
                              errorText: _isTaskNameValid ? null : 'Required',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description and Location Row (unchanged)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _descriptionController,
                                  maxLength: 100,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(100),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'^\s*$')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Enter description',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _locationController,
                                  maxLength: 100,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(100),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'^\s*$')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Enter location',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Recurrence and Day Row (updated)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurrence',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40, // Match height with date picker
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: _selectedRecurrence,
                                      isExpanded: true,
                                      hint: Text(
                                        'No recurrence',
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text('No recurrence'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Weekly',
                                          child: Text('Weekly recurrence'),
                                        ),
                                      ],
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedRecurrence = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Day',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      ' *',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    height: 40, // Consistent height
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: !_isDateValid
                                            ? Colors.red
                                            : !_isDateValid
                                                ? Colors.red
                                                : Colors.grey[300]!,
                                        width: !_isDateValid ? 2 : 1,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedDate != null
                                                ? DateFormat('dd.MM.yyyy')
                                                    .format(_selectedDate!)
                                                : 'Select Date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isDateValid
                                                  ? Colors.black
                                                  : Colors.red,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Time Row (updated with consistent styling)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Time-From',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      ' *',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectStartTime(context),
                                  child: Container(
                                    height: 40, // Consistent height
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: !_isStartTimeValid
                                              ? Colors.red
                                              : !_isDateValid
                                                  ? Colors.red
                                                  : Colors.grey[300]!,
                                          width: !_isDateValid ? 2 : 1,
                                        )),

                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _startTime != null
                                                ? _startTime!.format(context)
                                                : 'Select',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isStartTimeValid
                                                  ? Colors.black
                                                  : Colors.red,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.access_time, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Time-To',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const Text(
                                      ' *',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectEndTime(context),
                                  child: Container(
                                    height: 40, // Consistent height
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: !_isEndTimeValid
                                              ? Colors.red
                                              : !_isDateValid
                                                  ? Colors.red
                                                  : Colors.grey[300]!,
                                          width: !_isDateValid ? 2 : 1,
                                        )),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _endTime != null
                                                ? _endTime!.format(context)
                                                : 'Select',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isEndTimeValid
                                                  ? Colors.black
                                                  : Colors.red,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.access_time, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Save Button (updated with consistent styling)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 30, 12, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _createGoalAndAddTask,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
