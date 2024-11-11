import 'package:achiva/views/CreatePostPage.dart';
import 'package:achiva/views/addition_views/add_task_%20independently_page%20.dart';
import 'package:achiva/views/editTask.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:achiva/utilities/colors.dart';
import 'package:timelines/timelines.dart';

class GoalTasks extends StatefulWidget {
  final DocumentSnapshot goalDocument;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  GoalTasks({Key? key, required this.goalDocument}) : super(key: key);
  @override
  _GoalTasksState createState() => _GoalTasksState();
}

class _GoalTasksState extends State<GoalTasks> {
  double _progress = 0.0;
  late Stream<double> _progressStream;

  @override
  void initState() {
    super.initState();
    _progressStream = _createProgressStream();
  }

  Stream<double> _createProgressStream() {
    return widget.goalDocument.reference
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      int completedTasks = snapshot.docs
          .where((task) =>
              (task.data() as Map<String, dynamic>)['completed'] == true)
          .length;

      double progress = (completedTasks / snapshot.docs.length) * 100;
      return progress.roundToDouble();
    });
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task,
      DocumentReference taskRef, bool isCompleted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task['taskName'] ?? 'Task Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCompleted && widget.goalDocument['visibility'] == true)
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context)
                              .pop(); // Close the current dialog
                          String goalId = widget.goalDocument.id;
                          String taskId = taskRef.id;
                          // Show the CreatePostDialog
                          bool? result = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return CreatePostDialog(
                                userId: widget.userId,
                                goalId: goalId,
                                taskId: taskId,
                              );
                            },
                          ).then((value) async {
                            if (value == true) {
                              var tasks = await widget.goalDocument.reference
                                  .collection('tasks')
                                  .orderBy('startTime')
                                  .get();
                            }
                            return null;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.transparent),
                          elevation: WidgetStateProperty.all(
                              0), // Remove button shadow
                          padding: WidgetStateProperty.all(
                              EdgeInsets.zero), // Remove padding
                        ),
                        child: Image.asset("lib/images/post.png",
                            fit: BoxFit.contain,
                            height: 30,
                            color: Colors.grey[800]),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 15,
              )
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Date', task['date'], "lib/images/date.png"),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDetailRow('Description', task['description'],
                    "lib/images/description.png"),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDetailRow(
                    'Duration', task['duration'], "lib/images/duration.png"),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDetailRow('Start Time', task['startTime'],
                    "lib/images/startTime.png"),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDetailRow(
                    'End Time', task['endTime'], "lib/images/endTime.png"),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDetailRow(
                    'Location', task['location'], "lib/images/location.png"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Edit', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the details dialog
                _editTask(context, taskRef, task);
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the details dialog
                _deleteTask(context, taskRef);
              },
            ),
          ],
        );
      },
    );
  }

  void _editTask(BuildContext context, DocumentReference taskRef,
      Map<String, dynamic> taskData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditTaskDialog(
          taskRef: taskRef,
          taskData: taskData,
        );
      },
    );
  }

  void _deleteTask(BuildContext context, DocumentReference taskRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Delete Task',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await taskRef.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close both dialogs
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTaskCompletion(BuildContext context, DocumentReference taskRef,
      bool currentStatus, String taskName) {
    if (currentStatus) {
      // Unchecking a completed task
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(
                  'lib/images/uncheck.png',
                  fit: BoxFit.contain,
                  height: 60,
                ),
                Text('Uncheck Task',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
            content: Text(
                'Are you sure you want to mark this task as incomplete?',
                style: TextStyle(color: Colors.black)),
            actions: <Widget>[
              TextButton(
                child: Text('No', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateTaskStatus(context, taskRef, false);
                },
              ),
            ],
          );
        },
      );
    } else {
      // Checking an uncompleted task
      _updateTaskStatus(context, taskRef, true);

      // Check the visibility of the goal before asking to post
      if (widget.goalDocument['visibility'] == false) {
        // If the goal is not visible, show completion message only
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Image.asset(
                    'lib/images/check.png',
                    fit: BoxFit.contain,
                    height: 60,
                  ),
                  Text('Task Completed!',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
              content: Text('Congratulations on completing your task!',
                  style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // If the goal is visible, ask about posting
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Image.asset(
                    'lib/images/post.png',
                    fit: BoxFit.contain,
                    height: 60,
                  ),
                  Text('Task Completed!',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
              content: Text(
                  'Congratulations on completing your task!\nDo you want to make a post about it?',
                  style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                TextButton(
                  child: Text('No', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Yes', style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the current dialog
                    String goalId = widget.goalDocument.id;
                    String taskId = taskRef.id;
                    // Show the CreatePostDialog
                    bool? result = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return CreatePostDialog(
                          userId: widget.userId,
                          goalId: goalId,
                          taskId: taskId,
                        );
                      },
                    ).then((value) async {
                      if (value == true) {
                        var tasks = await widget.goalDocument.reference
                            .collection('tasks')
                            .orderBy('startTime')
                            .get();
                      }
                      return null;
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _updateTaskStatus(
      BuildContext context, DocumentReference taskRef, bool isCompleted) async {
    try {
      if (isCompleted) {
        // Marking the task as completed, add 'completedDate'
        await taskRef.update({
          'completed': true,
          'wasPreviouslyCompleted': true,
          'completedDate': FieldValue.serverTimestamp(),
          // Add current timestamp as completedDate
        });
      } else {
        // Unmarking the task, remove 'completedDate'
        await taskRef.update({
          'completed': false,
          'completedDate': FieldValue.delete(),
          // Remove the completedDate field
        });
        var tasks = await widget.goalDocument.reference
            .collection('tasks')
            .orderBy('startTime')
            .get();
      }

      // Trigger a rebuild of the widget tree
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String? selectedRecurrence;
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    bool isTaskNameValid = true;
    bool isDateValid = true;
    bool isStartTimeValid = true;
    bool isEndTimeValid = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: taskNameController,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                            FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Task Name (mandatory)',
                            errorText: isTaskNameValid
                                ? null
                                : 'Task Name is required',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter a task name'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                            FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: locationController,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                            FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Location (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDate != null
                                    ? 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'
                                    : 'Select Date (mandatory)',
                                style: TextStyle(
                                  color:
                                      isDateValid ? Colors.black : Colors.red,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final DateTime now = DateTime.now();
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now,
                                  lastDate: DateTime(now.year + 1),
                                );
                                if (pickedDate != null &&
                                    pickedDate != selectedDate) {
                                  selectedDate = pickedDate;
                                  isDateValid = true;
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                startTime != null
                                    ? 'Start Time: ${startTime!.format(context)}'
                                    : 'Select Start Time (mandatory)',
                                style: TextStyle(
                                  color: isStartTimeValid
                                      ? Colors.black
                                      : Colors.red,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () async {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null &&
                                    pickedTime != startTime) {
                                  startTime = pickedTime;
                                  isStartTimeValid = true;
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                endTime != null
                                    ? 'End Time: ${endTime!.format(context)}'
                                    : 'Select End Time (mandatory)',
                                style: TextStyle(
                                  color: isEndTimeValid
                                      ? Colors.black
                                      : Colors.red,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () async {
                                if (startTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please select a start time first.')),
                                  );
                                  return;
                                }
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null &&
                                    pickedTime != endTime) {
                                  final DateTime startDateTime = DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                    startTime!.hour,
                                    startTime!.minute,
                                  );
                                  final DateTime endDateTime = DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  if (endDateTime.isBefore(startDateTime)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'End time cannot be before start time.')),
                                    );
                                  } else {
                                    endTime = pickedTime;
                                    isEndTimeValid = true;
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRecurrence,
                          decoration: InputDecoration(
                            labelText: 'Recurrence',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: null, child: Text('No recurrence')),
                            DropdownMenuItem(
                                value: 'Weekly',
                                child: Text('Weekly recurrence')),
                          ],
                          onChanged: (String? newValue) {
                            selectedRecurrence = newValue;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              final User? user =
                                  FirebaseAuth.instance.currentUser;
                              if (user == null)
                                throw Exception("User not logged in");

                              final String? userPhoneNumber = user.phoneNumber;
                              if (userPhoneNumber == null) {
                                throw Exception(
                                    "Phone number is not available for the logged-in user.");
                              }

                              QuerySnapshot userSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .where('phoneNumber',
                                          isEqualTo: userPhoneNumber)
                                      .limit(1)
                                      .get();

                              DocumentReference userDocRef;
                              if (userSnapshot.docs.isEmpty) {
                                userDocRef = await FirebaseFirestore.instance
                                    .collection('Users')
                                    .add({
                                  'phoneNumber': userPhoneNumber,
                                });
                              } else {
                                userDocRef = userSnapshot.docs.first.reference;
                              }

                              CollectionReference tasksCollectionRef =
                                  userDocRef.collection('tasks');

                              Map<String, dynamic> taskData = {
                                'taskName': taskNameController.text,
                                'description':
                                    descriptionController.text.isNotEmpty
                                        ? descriptionController.text
                                        : null,
                                'location': locationController.text.isNotEmpty
                                    ? locationController.text
                                    : null,
                                'date': DateFormat('yyyy-MM-dd')
                                    .format(selectedDate!),
                                'startTime': startTime!.format(context),
                                'endTime': endTime!.format(context),
                                'recurrence':
                                    selectedRecurrence ?? 'No recurrence',
                                'completed': false,
                              };

                              if (selectedRecurrence == "Weekly") {
                                // Implement weekly recurrence logic here
                                // You may need to create a RecurringTaskManager class similar to the one in the AddTaskIndependentlyPage
                              } else {
                                await tasksCollectionRef.add(taskData);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Task added successfully')),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error adding task: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endMinutes - startMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  void _addTaskToFirestore(
      BuildContext context, Map<String, dynamic> taskData) async {
    try {
      await widget.goalDocument.reference.collection('tasks').add(taskData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Widget _buildDetailRow(String title, String? value, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            image,
            fit: BoxFit.contain,
            height: 20,
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            '$title: ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not set',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalData = widget.goalDocument.data() as Map<String, dynamic>;
    final String goalName = goalData['name'];
    final goalDate = DateTime.parse(goalData['date']);
    final bool visibilty = goalData['visibility'];
    final bool _isGoalDateValid = !goalDate.isBefore(DateTime.now());
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 30, 12, 48),
                  Color.fromARGB(255, 77, 64, 98),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          goalName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // Updated Progress Indicator
                      StreamBuilder<double>(
                        stream: _progressStream,
                        builder: (context, snapshot) {
                          final progress = snapshot.data ?? 0.0;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 45,
                                width: 45,
                                child: CircularProgressIndicator(
                                  value: progress / 100,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 100
                                        ? Colors.green
                                        : WellBeingColors.lightMaroon,
                                  ),
                                ),
                              ),
                              if (progress >= 100)
                                const Icon(
                                  Icons.check,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  size: 20,
                                )
                              else
                                Text(
                                  '${progress.round()}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Tasks Timeline
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: widget.goalDocument.reference
                          .collection('tasks')
                          .orderBy('startTime')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('No tasks found for this goal.'));
                        }

                        final tasks = snapshot.data!.docs;

                        return Timeline.tileBuilder(
                          theme: TimelineThemeData(
                            nodePosition: 0.1,
                            connectorTheme: ConnectorThemeData(
                              thickness: 3.3,
                              color: Color(0xFFBDBDBD),
                            ),
                            indicatorTheme: IndicatorThemeData(
                              size: 40.0, // Increased from 20.0 to 30.0
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          builder: TimelineTileBuilder.connected(
                            contentsAlign: ContentsAlign.basic,
                            connectionDirection: ConnectionDirection.before,
                            itemCount: tasks.length,
                            contentsBuilder: (_, index) {
                              final taskDoc = tasks[index];
                              final task =
                                  taskDoc.data() as Map<String, dynamic>;
                              final taskName =
                                  task['taskName'] ?? 'Unnamed Task';
                              final startTime = task['startTime'] ?? 'Not set';
                              final date = task['date'] ?? 'Not set';
                              final isCompleted = task['completed'] ?? false;
                              return GestureDetector(
                                onTap: () => _showTaskDetails(context, task,
                                    taskDoc.reference, isCompleted),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 22.0, bottom: 40.0, right: 22.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                                height:
                                                    16), // Increased space above task details
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    taskName,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isCompleted
                                                          ? Colors.grey
                                                          : Colors.black,
                                                      decoration: isCompleted
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  startTime,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              date,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey[700],
                                        size: 15, // Adjust the size as needed
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            indicatorBuilder: (_, index) {
                              final taskDoc = tasks[index];
                              final task =
                                  taskDoc.data() as Map<String, dynamic>;
                              final isCompleted = task['completed'] ?? false;
                              final taskName =
                                  task['taskName'] ?? 'Unnamed Task';
                              return GestureDetector(
                                onTap: () async {
                                  print(taskDoc.data());
                                  _toggleTaskCompletion(context,
                                      taskDoc.reference, isCompleted, taskName);
                                  if (isCompleted == false) {
                                    var tasks = await widget
                                        .goalDocument.reference
                                        .collection('tasks')
                                        .orderBy('startTime')
                                        .get();
                                  }
                                },
                                child: Container(
                                  width: 30.0, // Increased from 20.0 to 30.0
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.white,
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.green
                                          : Color(0xFFBDBDBD),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 20.0)
                                      : null,
                                ),
                              );
                            },
                            connectorBuilder: (_, index, connectorType) {
                              final task =
                                  tasks[index].data() as Map<String, dynamic>;
                              final isCompleted = task['completed'] ?? false;
                              return SolidLineConnector(
                                color: isCompleted
                                    ? Colors.green
                                    : Color(0xFFBDBDBD),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                if (_isGoalDateValid) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTaskIndependentlyPage(
                        goalName: goalName,
                        goalDate: goalDate,
                        goalVisibility: visibilty,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal date has already passed.'),
                      backgroundColor: Colors.red,
                      duration:
                          Duration(seconds: 3), // How long it stays visible
                    ),
                  );
                }
              },
              backgroundColor: _isGoalDateValid
                  ? Color.fromARGB(255, 66, 32, 101)
                  : Colors.grey,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
