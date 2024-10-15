import 'package:achiva/views/CreatePostPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalTasks extends StatelessWidget {
  final DocumentSnapshot goalDocument;
  final double progress = 65.0;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

   GoalTasks({Key? key, required this.goalDocument}) : super(key: key);

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Text(task['taskName'] ?? 'Task Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date: ${task['date'] ?? 'Not set'}'),
                Text('Description: ${task['description'] ?? 'No description'}'),
                Text('Duration: ${task['duration'] ?? 'Not set'}'),
                Text('Start Time: ${task['startTime'] ?? 'Not set'}'),
                Text('End Time: ${task['endTime'] ?? 'Not set'}'),
                Text('Location: ${task['location'] ?? 'No location'}'),
                Text('Recurrence: ${task['recurrence'] ?? 'No recurrence'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Edit'),
              onPressed: () {
                // TODO: Implement edit functionality
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
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

  void _toggleTaskCompletion(BuildContext context, DocumentReference taskRef,
      bool currentStatus, String taskName) async {
    if (currentStatus) {
      // Unchecking a completed task
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Uncheck Task'),
            content:
                Text('Are you sure you want to mark this task as incomplete?'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
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
      await _updateTaskStatus(context, taskRef, true);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Task Completed!'),
            content: Text(
                'Congratulations on completing your task!\nDo you want to make a post about it?'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
                 onPressed: () {
                  // String userId = userId;
                  String goalId = goalDocument.id;
                  String taskId = taskRef.id;
              Navigator.of(context).pop(); // Close the dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostPage(userId: userId, goalId: goalId, taskId: taskId),
                ),
              ); // Navigate to the Create Post page if 'Yes' is selected
            },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _updateTaskStatus(
      BuildContext context, DocumentReference taskRef, bool isCompleted) async {
    try {
      await taskRef.update({'completed': isCompleted});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String taskName = '';
    String? date;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String location = '';
    String recurrence = '';
    String description = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Task Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a task name' : null,
                    onSaved: (value) => taskName = value!,
                  ),
                TextFormField(
  decoration: InputDecoration(labelText: 'Date'),
  readOnly: true,
  onTap: () async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    
    if (pickedDate != null) {
      // Format the date to a string (e.g., 'yyyy-MM-dd')
      date = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  },
  validator: (value) {
    return date == null ? 'Please select a date' : null;
  },
  controller: TextEditingController(text: date), // Show the selected date
),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Start Time'),
                    readOnly: true,
                    onTap: () async {
                      startTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                    },
                    validator: (value) =>
                        startTime == null ? 'Please select a start time' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'End Time'),
                    readOnly: true,
                    onTap: () async {
                      endTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                    },
                    validator: (value) =>
                        endTime == null ? 'Please select an end time' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Location'),
                    onSaved: (value) => location = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Recurrence'),
                    onSaved: (value) => recurrence = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    onSaved: (value) => description = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  _addTaskToFirestore(context, {
                    'taskName': taskName,
                    'date': date!,
                    'startTime': startTime!.format(context),
                    'endTime': endTime!.format(context),
                    'location': location,
                    'recurrence': recurrence,
                    'description': description,
                    'duration': _calculateDuration(startTime!, endTime!),
                    'completed': false,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
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
      await goalDocument.reference.collection('tasks').add(taskData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalData = goalDocument.data() as Map<String, dynamic>;
    final String goalName = goalData['name'];

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
        Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 66, 32, 101),
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
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          goalName,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      // Progress indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 165, 148, 153)),
                          ),
                          Text(
                            '${progress.round()}%',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
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
                      stream: goalDocument.reference
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
                              final task = taskDoc.data() as Map<String, dynamic>;
                              final taskName =task['taskName'] ?? 'Unnamed Task';
                              final startTime = task['startTime'] ?? 'Not set';
                              final date = task['date'] ?? 'Not set';
                              final isCompleted = task['completed'] ?? false;

                            return GestureDetector(
                                onTap: () => _showTaskDetails(context, task),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 22.0, bottom: 40.0, right: 22.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              final task =
                                  taskDoc.data() as Map<String, dynamic>;
                              final isCompleted = task['completed'] ?? false;
                              final taskName = task['taskName'] ?? 'Unnamed Task';
                              return GestureDetector(
                                onTap: () => _toggleTaskCompletion(context,
                                    taskDoc.reference, isCompleted, taskName),
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
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: Color.fromARGB(255, 66, 32, 101),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
