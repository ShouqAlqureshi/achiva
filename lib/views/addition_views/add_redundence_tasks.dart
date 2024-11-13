
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../utilities/local_notification.dart';

class RecurringTaskManager {
  final Uuid _uuid = Uuid();

  Future<List<Map<String, dynamic>>> addRecurringTask({
    required String goalName,
    required DateTime startDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String? location,
    required String? recurrenceType,
    required String? description,
    required String taskName,
    required CollectionReference usergoallistrefrence,
    required DateTime goalDate,
  }) async {
    // Fetch the goal end date from Firestore
    DateTime endDate = goalDate;

    // Determine the day of week from the start date
    int dayOfWeek = startDate.weekday;

    final String redundancyId = _uuid.v4();
    List<Map<String, dynamic>> tasks = [];

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (currentDate.weekday == dayOfWeek) {
        final DateTime taskStart = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          startTime.hour,
          startTime.minute,
        );

        final DateTime taskEnd = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          endTime.hour,
          endTime.minute,
        );

        Map<String, dynamic> task = await _addTaskToFirestore(
          taskName,
          currentDate,
          redundancyId,
          taskStart,
          taskEnd,
          location ??
              'Unknown location', // Provide a default value or handle null
          recurrenceType ?? 'None', // Provide a default value for recurrence
          description ?? '', // Provide an empty string if description is null
          goalName,
          calcDuration(startTime, endTime),
          usergoallistrefrence,
        );

        tasks.add(task);
      }
      LocalNotification.scheduleTaskDueNotification(
        taskName: taskName,
        dueDate: currentDate.add(Duration(hours:  startTime.hour, minutes: startTime.minute)),
        goalName: goalName,
      );
      currentDate = currentDate.add(Duration(days: 1));
    }

    return tasks;
  }

  // Future<DateTime> _getGoalEndDate(
  //     String goalName, CollectionReference usergoallistrefrence) async {
  //   try {
  //     DocumentSnapshot goalDoc = await usergoallistrefrence.doc(goalName).get();
  //     if (goalDoc.exists) {
  //       DateTime endDate = DateTime.parse(goalDoc.get('date') as String);

  //       return endDate;
  //     } else {
  //       throw Exception('Goal not found');
  //     }
  //   } catch (e) {
  //     print('Error fetching goal end date: $e');
  //     throw e;
  //   }
  // }

  Future<Map<String, dynamic>> _addTaskToFirestore(
    String taskName,
    DateTime date,
    String redundancyId,
    DateTime starttime,
    DateTime endtime,
    String? location,
    String recurrenceType,
    String? description,
    String goalName,
    String duration,
    usergoallistrefrence,
  ) async {
    final String taskId = _uuid.v4();
    final Map<String, dynamic> task = {
      'taskName': taskName,
      'id': taskId,
      'description': description,
      'location': location,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'startTime': formatTime(starttime),
      'endTime': formatTime(endtime),
      'recurrence': recurrenceType,
      'redundancyId': redundancyId,
      'duration': duration,
    };

    await usergoallistrefrence
        .doc(goalName)
        .collection('tasks')
        .doc(taskId)
        .set(task);
    return task;
  }
}

String formatTime(DateTime dateTime) {
  return DateFormat.jm().format(dateTime);
}

String calcDuration(TimeOfDay starttime, TimeOfDay endtime) {
  // Calculate the duration in hours and minutes
  final startTimeInMinutes = starttime.hour * 60 + starttime.minute;
  final endTimeInMinutes = endtime.hour * 60 + endtime.minute;
  final durationInMinutes = endTimeInMinutes - startTimeInMinutes;
  final hours = durationInMinutes ~/ 60;
  final minutes = durationInMinutes % 60;
  return '${hours}h ${minutes}m';
}

// Usage example for testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final taskManager = RecurringTaskManager();
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .where('phoneNumber', isEqualTo: "+966552808911")
      .limit(1)
      .get();
  DocumentReference userDocRef;
  userDocRef = userSnapshot.docs.first.reference;
  CollectionReference goalsCollectionRef = userDocRef.collection('goals');
  try {
    List<Map<String, dynamic>> createdTasks =
        await taskManager.addRecurringTask(
      goalName: "no",
      startDate: DateTime(2024, 9, 20), // This date determines the day of week
      startTime: TimeOfDay(hour: 10, minute: 0),
      endTime: TimeOfDay(hour: 12, minute: 0),
      location: "Office",
      recurrenceType: "weekly",
      description: "Team meeting for Project X",
      taskName: "weekly recurrence test",
      usergoallistrefrence: goalsCollectionRef,
      goalDate: DateTime(2024),
    );

    log("Created tasks:");
    for (var task in createdTasks) {
      log(task as String);
    }
  } catch (e) {
    log("Error creating recurring tasks: $e");
  }
}

