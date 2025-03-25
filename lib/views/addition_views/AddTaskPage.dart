// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:achiva/utilities/loading.dart';
import 'package:achiva/views/addition_views/RecurringTaskManager.dart';
import 'package:achiva/views/addition_views/TaskHelper.dart';
import 'package:achiva/views/sharedgoal/sharedgoal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../utilities/local_notification.dart';

class AddTaskPage extends StatefulWidget {
  final String goalName;
  final DateTime goalDate;
  final bool goalVisibility;
  final bool isSharedGoal;
  final String? sharedKey;
  final bool isIndependent;

  const AddTaskPage({
    super.key,
    required this.goalName,
    required this.goalDate,
    required this.goalVisibility,
    this.isSharedGoal = false,
    this.sharedKey,
    this.isIndependent = false,
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

  String? _taskNameError;
  String? _dateError;
  String? _startTimeError;
  String? _endTimeError;
  bool _isGoalDateValid = true;
  final TaskRepository _taskRepository = TaskRepository();
  Future<void> _createGoalAndAddTask() async {
    showLoadingDialog(context);

    final validation = TaskValidator.validate(
      taskName: _taskNameController.text,
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      goalDate: widget.goalDate,
    );

    setState(() {
      _taskNameError = validation.taskNameError;
      _dateError = validation.dateError;
      _startTimeError = validation.startTimeError;
      _endTimeError = validation.endTimeError;
    });

    if (!validation.isValid) {
      Navigator.of(context).pop();
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

      final userDocRef = await _taskRepository.getUserDocument();

      CollectionReference goalsCollectionRef = widget.isSharedGoal
          ? FirebaseFirestore.instance.collection('sharedGoal')
          : userDocRef.collection('goals');

      if (!widget.isIndependent && !widget.isSharedGoal) {
        DocumentSnapshot goalSnapshot =
            await goalsCollectionRef.doc(widget.goalName).get();

        if (goalSnapshot.exists) {
          log("The goal name exists, try changing the name");
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("The goal name exists, try changing the name")),
          );
          return;
        }

        await _taskRepository.createGoal(
          goalName: widget.goalName,
          goalDate: widget.goalDate,
          goalVisibility: widget.goalVisibility,
        );
      }

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

      if (_selectedRecurrence == "Weekly") {
        createdTasks = await taskManager.addRecurringTask(
          goalName: widget.goalName,
          startDate: _selectedDate!,
          startTime: _startTime!,
          endTime: _endTime!,
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          recurrenceType: _selectedRecurrence ?? 'No recurrence',
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          taskName: _taskNameController.text,
          usergoallistrefrence: goalsCollectionRef,
          goalDate: widget.goalDate,
          isSharedGoal: widget.isSharedGoal,
          sharedkey: widget.sharedKey ?? "",
        );

        if (createdTasks.isNotEmpty) {
          log("Recurring tasks created successfully");
          widget.isSharedGoal
              ? await _taskRepository.updateTaskCount(
                  goalName: widget.goalName,
                  increment: createdTasks.length,
                  isShared: widget.isSharedGoal,
                  sharedKey: widget.sharedKey,
                )
              : await goalsCollectionRef.doc(widget.goalName).update(
                  {'notasks': FieldValue.increment(createdTasks.length)});
        }
      } else {
        if (widget.isSharedGoal) {
          await SharedGoalManager().addTaskToSharedGoal(
            sharedID: widget.sharedKey ?? "",
            taskData: taskData,
            context: context,
          );
        } else {
          await _taskRepository.addTask(
            goalName: widget.goalName,
            taskData: taskData,
            isShared: widget.isSharedGoal,
            sharedKey: widget.sharedKey,
          );

          if (widget.isIndependent) {
            await goalsCollectionRef
                .doc(widget.goalName)
                .update({'notasks': FieldValue.increment(1)});
          }
        }
      }

      LocalNotification.scheduleTaskDueNotification(
        taskName: _taskNameController.text,
        dueDate: _selectedDate!.add(
            Duration(hours: _startTime!.hour, minutes: _startTime!.minute)),
        goalName: widget.goalName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      log("Error creating goal and adding task: $e");
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

//user select the day
  Future<void> _selectDate(BuildContext context) async {
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = widget.goalDate;

    setState(() {
      _isGoalDateValid = !lastDate.isBefore(firstDate);
    });

    if (lastDate.isBefore(firstDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Goal date has already passed. Please update the goal date.'),
        ),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateError = null;
      });
    }
  }

//user select the time
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        _startTimeError = null;
        _endTimeError = null;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time first.')),
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    //new time has been picked
    if (pickedTime != null && pickedTime != _endTime) {
     
      final DateTime startDateTime =
          DateTimeHelper.combineDateWithTime(DateTime.now(), _startTime);

      final DateTime endDateTime =
          DateTimeHelper.combineDateWithTime(DateTime.now(), pickedTime);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End time cannot be before start time.')),
        );
      } else {
        setState(() {
          _endTime = pickedTime;
          _endTimeError = null;
        });
      }
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
                const SizedBox(height: 80),
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
                          TextField(
                            controller: _taskNameController,
                            maxLength: 50,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'^\s*$')),
                            ],
                            onChanged: (value) {
                              if (_taskNameError != null) {
                                setState(() => _taskNameError = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter task name',
                              errorText: _taskNameError,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                  height: 40,
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
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'No recurrence',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Weekly',
                                          child: Text(
                                            'Weekly recurrence',
                                            style: TextStyle(fontSize: 13),
                                          ),
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
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: !_isGoalDateValid
                                            ? Colors.red
                                            : _dateError != null
                                                ? Colors.red
                                                : Colors.grey[300]!,
                                        width: !_isGoalDateValid ? 2 : 1,
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
                                                ? DateTimeHelper
                                                    .formatForDisplay(
                                                        _selectedDate!)
                                                : 'Select Date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: !_isGoalDateValid ||
                                                      _dateError != null
                                                  ? Colors.red
                                                  : Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: !_isGoalDateValid ||
                                                  _dateError != null
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!_isGoalDateValid)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Goal date has passed',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                  onTap: () => _selectStartTime(context),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: _startTimeError!.isNotEmpty
                                            ? Colors.red
                                            : _dateError != null
                                                ? Colors.red
                                                : Colors.grey[300]!,
                                        width: !_isGoalDateValid ? 2 : 1,
                                      ),
                                      color: Colors.white,
                                    ),
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
                                              color: _startTimeError != null
                                                  ? Colors.red
                                                  : Colors.black,
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
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: _endTimeError!.isNotEmpty
                                            ? Colors.red
                                            : _dateError != null
                                                ? Colors.red
                                                : Colors.grey[300]!,
                                        width: !_isGoalDateValid ? 2 : 1,
                                      ),
                                      color: Colors.white,
                                    ),
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
                                              color: _endTimeError != null
                                                  ? Colors.red
                                                  : Colors.black,
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
                          if (widget.isIndependent)
                            TextButton(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
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
