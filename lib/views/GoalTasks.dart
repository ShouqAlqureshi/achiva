import 'package:achiva/views/CreatePostPage.dart';
import 'package:achiva/views/addition_views/add_task_%20independently_page%20.dart';
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
    return FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('goals')
        .doc(widget.goalDocument.id)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      int completedTasks = snapshot.docs
          .where((task) => (task.data() as Map<String, dynamic>)['completed'] == true)
          .length;

      double progress = (completedTasks / snapshot.docs.length) * 100;
      return progress.roundToDouble();
    });
  }


void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
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
            Text(
              task['taskName'] ?? 'Task Details',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,

              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _buildDetailRow('Date', task['date']),
              _buildDetailRow('Description', task['description']),
              _buildDetailRow('Duration', task['duration']),
              _buildDetailRow('Start Time', task['startTime']),
              _buildDetailRow('End Time', task['endTime']),
              _buildDetailRow('Location', task['location']),
              _buildDetailRow('Recurrence', task['recurrence']),
            ],
          ),
content: SingleChildScrollView(
  child: ListBody(
    children: <Widget>[
      _buildDetailRow('Date', task['date']),
      _buildDetailRow('Description', task['description']),
      _buildDetailRow('Duration', task['duration']),
      _buildDetailRow('Start Time', task['startTime']),
      _buildDetailRow('End Time', task['endTime']),
      _buildDetailRow('Location', task['location']),
      _buildDetailRow('Recurrence', task['recurrence']),
    ],
  ),
),
actions: <Widget>[
  TextButton(
    child: Text('Edit', style: TextStyle(color: Colors.black)),
    onPressed: () {
      // TODO: Implement edit functionality
      Navigator.of(context).pop();
    },
  ),
],

          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.black)),
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(String title, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'Not set',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
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
            title: Text('Uncheck Task',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
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
      // Implement your code for marking a task as complete
    }

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
              title: Text('Task Completed!',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
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
              title: Text('Task Completed!',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
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
                    ).then((value) async{
                      if(value == true){
                        var tasks = await widget.goalDocument.reference
                            .collection('tasks')
                            .orderBy('startTime')
                            .get();
                        updateStreak(tasks.docs);
                      }
                      return null;
                    }

                    );
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
  // void _toggleTaskCompletion(BuildContext context, DocumentReference taskRef,
  //     bool currentStatus, String taskName)
  // {
  //   if (!currentStatus){
  //     // Checking an uncompleted task
  //     _updateTaskStatus(context, taskRef, true);
  //
  //     // Check the visibility of the goal before asking to post
  //     if (widget.goalDocument['visibility'] == false) {
  //       // If the goal is not visible, show completion message only
  //       showDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             backgroundColor: Colors.white,
  //             title: Text('Task Completed!',
  //                 style: TextStyle(
  //                     color: Colors.black, fontWeight: FontWeight.bold)),
  //             content: Text('Congratulations on completing your task!',
  //                 style: TextStyle(color: Colors.black)),
  //             actions: <Widget>[
  //               TextButton(
  //                 child: Text('OK', style: TextStyle(color: Colors.black)),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     } else {
  //       // If the goal is visible, ask about posting
  //       showDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             backgroundColor: Colors.white,
  //             title: Text('Task Completed!',
  //                 style: TextStyle(
  //                     color: Colors.black, fontWeight: FontWeight.bold)),
  //             content: Text(
  //                 'Congratulations on completing your task!\nDo you want to make a post about it?',
  //                 style: TextStyle(color: Colors.black)),
  //             actions: <Widget>[
  //               TextButton(
  //                 child: Text('No', style: TextStyle(color: Colors.black)),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //               TextButton(
  //                 child: Text('Yes', style: TextStyle(color: Colors.black)),
  //                 onPressed: () async {
  //                   Navigator.of(context).pop(); // Close the current dialog
  //                   String goalId = widget.goalDocument.id;
  //                   String taskId = taskRef.id;
  //                   // Show the CreatePostDialog
  //                   bool? result = await showDialog<bool>(
  //                     context: context,
  //                     builder: (BuildContext context) {
  //                       return CreatePostDialog(
  //                         userId: widget.userId,
  //                         goalId: goalId,
  //                         taskId: taskId,
  //                       );
  //                     },
  //                   ).then((value) async{
  //                     if(value == true){
  //                       var tasks = await widget.goalDocument.reference
  //                           .collection('tasks')
  //                           .orderBy('startTime')
  //                           .get();
  //                       updateStreak(tasks.docs);
  //                     }
  //                     return null;
  //                   }
  //
  //                   );
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     }
  //   }
  // }

  Future<void> _updateTaskStatus(
      BuildContext context, DocumentReference taskRef, bool isCompleted) async {
    try {
      if (isCompleted) {
        // Marking the task as completed, add 'completedDate'
        await taskRef.update({
          'completed': true,
'wasPreviouslyCompleted': true,
'completedDate': FieldValue.serverTimestamp(), // Add current timestamp as completedDate

        });
      } else {
        // Unmarking the task, remove 'completedDate'
        await taskRef.update({
          'completed': false,
await taskRef.update({
  'completedDate': FieldValue.delete(), // Remove the completedDate field
});
var tasks = await widget.goalDocument.reference
    .collection('tasks')
    .orderBy('startTime')
    .get();
updateStreak(tasks.docs);

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
    .where('phoneNumber', isEqualTo: userPhoneNumber)
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

  DateTime getLatestEndTime(List<DocumentSnapshot> tasks) {
    return tasks.map((task) {
      var date = task["date"]; // Should be in format "2024-10-23"
      var time = task["endTime"]; // Should be in format like "8:10 PM"

      // Ensure time is not null and trim any extra spaces
      if (date is String && time is String) {
        // Replace non-breaking spaces with regular spaces
        time = time.replaceAll(
            String.fromCharCode(0xA0), ' '); // Replace non-breaking spaces
        time = time.replaceAll(RegExp(r'\s+'), ' ').trim(); // Normalize spaces

        print(
            "Parsed time string: '$time' with code points: ${time.codeUnits}");
        print(
            "Hex representation: ${time.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).toList()}");

        DateTime parsedTime;
        try {
          DateFormat timeFormat = DateFormat.jm("en_US"); // Specify locale
          parsedTime = timeFormat.parseStrict(time); // Use strict parsing
        } catch (e) {
          print("Error parsing time: '$time'. Exception: $e");
          // Fallback parsing method
          try {
            parsedTime = DateFormat("h:mm a").parseStrict(time);
          } catch (e) {
            print("Fallback error: $e");
            throw Exception("Invalid time format: '$time'");
          }
        }

        // Parse the date part
        DateTime taskDate = DateTime.parse(date); // Parse date string

        // Combine the date and time to create a full DateTime object
        DateTime taskDateTime = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
        return taskDateTime;
      } else {
        throw Exception("Invalid date or time format");
      }
    }).reduce((a, b) => a.isAfter(b) ? a : b); // Return the latest DateTime
  }

  bool isAnyTaskCompleted(List<DocumentSnapshot> tasks) {
    return tasks.any((task) => task["completed"]);
  }

  bool isBeforeEndTime(List<DocumentSnapshot> tasks) {
    DateTime latestEndTime = getLatestEndTime(tasks);
    DateTime now = DateTime.now();
    return now.isBefore(latestEndTime);
  }
  // Use this function to check if at least one task is completed and if it's before the latest end time.
  bool isAnyTaskCompletedBeforeEndTime(List<DocumentSnapshot> tasks) {
    return isAnyTaskCompleted(tasks) && isBeforeEndTime(tasks);
  }

  updateStreak(List<DocumentSnapshot> tasks, {taskOne}) async {
    var postsSnapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("allPosts")
        .get();

    // التحقق من وجود مهمة في جميع المهام
    bool hasTaskId(List<DocumentSnapshot> tasks) {
      for (var post in postsSnapshot.docs) {
        var postTaskId = post['taskId'];
        if (tasks.any((task) => task.id == postTaskId)) {
          return true;
        }
      }
      return false;
    }

    // التحقق من وجود مهمة معينة فقط
    bool hasTaskIdForSingleTask(String taskId) {
      for (var post in postsSnapshot.docs) {
        if (post['taskId'] == taskId) {
          return true;
        }
      }
      return false;
    }

    var goalDocRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("goals")
        .doc(widget.goalDocument.id);

    var goalSnapshot = await goalDocRef.get();
    bool isGoalCompleted = goalSnapshot.data()?['completed'] ?? false;
    bool isGoalFinished = goalSnapshot.data()?['finished'] ?? false;

    bool isAnyTaskCompleted = this.isAnyTaskCompleted(tasks);
    bool isBeforeEndTime = this.isBeforeEndTime(tasks);
    bool hasMatchingTaskId = hasTaskId(tasks);

    // إذا تم استيفاء الشروط، قم بزيادة الـ streak وتحديث wasPreviouslyCompleted
    if (hasMatchingTaskId && isAnyTaskCompleted && isBeforeEndTime && !isGoalCompleted) {
      await goalDocRef.update({"completed": true});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"streak": FieldValue.increment(1)});
      print("Streak increased by 1!");
    } else {
      DateTime latestEndTime = getLatestEndTime(tasks);

      if (DateTime.now().isAfter(latestEndTime) && !hasMatchingTaskId && !isGoalFinished) {
        await goalDocRef.update({"completed": false, "finished": true});
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({"streak": 0});
        print("Streak reset to 0 due to end time.");
      } else if (taskOne != null) {
        // في حالة إلغاء تفعيل مهمة واحدة

      }
    }
    // print(taskOne);
    // bool isHasTaskIdForSingleTask = taskOne["completed"] == false && hasTaskIdForSingleTask(taskOne.id);
    // print("isHasTaskIdForSingleTask: $isHasTaskIdForSingleTask");
    //
    // if (isHasTaskIdForSingleTask && !hasMatchingTaskId) {
    //   await goalDocRef.update({"completed": false});
    //   await FirebaseFirestore.instance
    //       .collection("Users")
    //       .doc(FirebaseAuth.instance.currentUser!.uid)
    //       .update({"streak": 0});
    //   print("Streak reset to 0 due to incomplete task.");
    //
    //   // تحديث wasPreviouslyCompleted للمهمة المحددة فقط
    //   await FirebaseFirestore.instance
    //       .collection("Users")
    //       .doc(FirebaseAuth.instance.currentUser!.uid)
    //       .collection('goals')
    //       .doc(widget.goalDocument.id)
    //       .collection('tasks')
    //       .doc(taskOne.id)
    //       .update({"wasPreviouslyCompleted": false});
    // }
  }
  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
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
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 100 ? Colors.green : WellBeingColors.lightMaroon,
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
                                onTap: () => _showTaskDetails(context, task),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 22.0, bottom: 40.0, right: 22.0),
                                  child: Column(
                                    crossAxisAlignment:
CrossAxisAlignment.start,
children: [
  SizedBox(height: 16), // Increased space above task details
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,

                                        children: [
                                          Expanded(
                                            child: Text(
                                              taskName,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: isCompleted
                                                    ? Colors.grey
                                                    : Colors.black,
                                                decoration: isCompleted
                                                    ? TextDecoration.lineThrough
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
                              );
                            },
                            indicatorBuilder: (_, index) {
                              final taskDoc = tasks[index];
                              final task = taskDoc.data() as Map<String, dynamic>;
                              updateStreak(tasks);
                              final isCompleted = task['completed'] ?? false;
                              final taskName =
                                  task['taskName'] ?? 'Unnamed Task';
                              return GestureDetector(
                                onTap: () async {
                                  print(taskDoc.data());
                                  _toggleTaskCompletion(
                                      context,
                                      taskDoc.reference,
                                      isCompleted,
                                      taskName
                                  );
                                  if (isCompleted == false) {
                                    var tasks = await widget
                                        .goalDocument.reference
                                        .collection('tasks')
                                        .orderBy('startTime')
                                        .get();
                                    print('objectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobjectobject');
                                    updateStreak(tasks.docs,taskOne: taskDoc.data());
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
              },
              backgroundColor: Color.fromARGB(255, 66, 32, 101),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
