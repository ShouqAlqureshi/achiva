import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskValidationResult {
  final bool isValid;
  final String? taskNameError;
  final String? dateError;
  final String? startTimeError;
  final String? endTimeError;

  TaskValidationResult({
    required this.isValid,
    this.taskNameError,
    this.dateError,
    this.startTimeError,
    this.endTimeError,
  });
}

class TaskValidator {
  static TaskValidationResult validate({
    required String taskName,
    required DateTime? date,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required DateTime goalDate,
  }) {
    String? taskNameError;
    String? dateError;
    String? startTimeError;
    String? endTimeError;

    if (taskName.isEmpty) taskNameError = 'Task name is required';
    if (date == null) {
      dateError = 'Date is required';
    } else if (date.isAfter(goalDate)) {
      dateError = 'Cannot be after goal date';
    }
    if (startTime == null) startTimeError = 'Start time is required';
    if (endTime == null) {
      endTimeError = 'End time is required';
    } else if (startTime != null) {
      if (endTime.hour < startTime.hour || 
          (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
        endTimeError = 'Must be after start time';
      }
    }

    return TaskValidationResult(
      isValid: taskNameError == null && 
               dateError == null && 
               startTimeError == null && 
               endTimeError == null,
      taskNameError: taskNameError,
      dateError: dateError,
      startTimeError: startTimeError,
      endTimeError: endTimeError,
    );
  }
}

class DateTimeHelper {
  static DateTime combineDateWithTime(DateTime date, TimeOfDay? time) {
    return DateTime(date.year, date.month, date.day, time!.hour, time.minute);
  }

  static String formatForDisplay(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}


class TaskRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TaskRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<DocumentReference> getUserDocument() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final String? userPhoneNumber = user.phoneNumber;
    if (userPhoneNumber == null) {
      throw Exception("Phone number is not available for the logged-in user.");
    }

    final userSnapshot = await _firestore
        .collection('Users')
        .where('phoneNumber', isEqualTo: userPhoneNumber)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      return await _firestore.collection('Users').add({
        'phoneNumber': userPhoneNumber,
      });
    } else {
      return userSnapshot.docs.first.reference;
    }
  }

  Future<void> createGoal({
    required String goalName,
    required DateTime goalDate,
    required bool goalVisibility,
  }) async {
    final userDocRef = await getUserDocument();
    await userDocRef.collection('goals').doc(goalName).set({
      'name': goalName,
      'date': goalDate.toIso8601String(),
      'visibility': goalVisibility,
      'notasks': 1,
    });
  }

  Future<bool> goalExists(String goalName, {bool isShared = false}) async {
    if (isShared) {
      final doc = await _firestore.collection('sharedGoal').doc(goalName).get();
      return doc.exists;
    } else {
      final userDocRef = await getUserDocument();
      final doc = await userDocRef.collection('goals').doc(goalName).get();
      return doc.exists;
    }
  }

  Future<void> addTask({
    required String goalName,
    required Map<String, dynamic> taskData,
    bool isShared = false,
    String? sharedKey,
  }) async {
    if (isShared && sharedKey != null) {
      await _firestore
          .collection('sharedGoal')
          .doc(sharedKey)
          .collection('tasks')
          .add(taskData);
    } else {
      final userDocRef = await getUserDocument();
      await userDocRef
          .collection('goals')
          .doc(goalName)
          .collection('tasks')
          .add(taskData);
    }
  }

  Future<void> addRecurringTasks({
    required String goalName,
    required List<Map<String, dynamic>> tasks,
    bool isShared = false,
    String? sharedKey,
  }) async {
    final batch = _firestore.batch();

    if (isShared && sharedKey != null) {
      final sharedGoalRef = _firestore.collection('sharedGoal').doc(sharedKey);
      final tasksCollection = sharedGoalRef.collection('tasks');
      
      for (final task in tasks) {
        final taskRef = tasksCollection.doc(task['id']);
        batch.set(taskRef, task);
      }
      
      batch.update(sharedGoalRef, {
        'notasks': FieldValue.increment(tasks.length),
      });
    } else {
      final userDocRef = await getUserDocument();
      final goalRef = userDocRef.collection('goals').doc(goalName);
      final tasksCollection = goalRef.collection('tasks');
      
      for (final task in tasks) {
        final taskRef = tasksCollection.doc(task['id']);
        batch.set(taskRef, task);
      }
      
      batch.update(goalRef, {
        'notasks': FieldValue.increment(tasks.length),
      });
    }

    await batch.commit();
  }

  Future<void> updateTaskCount({
    required String goalName,
    required int increment,
    bool isShared = false,
    String? sharedKey,
  }) async {
    if (isShared && sharedKey != null) {
      await _firestore.collection('sharedGoal').doc(sharedKey).update({
        'notasks': FieldValue.increment(increment),
      });
    } else {
      final userDocRef = await getUserDocument();
      await userDocRef.collection('goals').doc(goalName).update({
        'notasks': FieldValue.increment(increment),
      });
    }
  }
}
