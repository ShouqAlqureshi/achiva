import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:achiva/utilities/local_notification.dart';

class TaskNotificationManager {
  static Future<void> updateTaskNotification({
    required String oldTaskName,
    required String oldGoalName,
    required String newTaskName,
    required String newGoalName,
    required DateTime newDateTime,
    bool isRecurring = false,
  }) async {
    try {
      // Cancel the previous notification first
      await LocalNotification.cancelNotification(
        taskName: oldTaskName,
        goalName: oldGoalName,
      );

      // For recurring tasks, we might want to handle differently
      if (isRecurring) {
        
        await LocalNotification.scheduleTaskHourNotification(
          taskName: newTaskName,
          dueDate: newDateTime,
          goalName: newGoalName,
        );
      } else {
        // For non-recurring tasks, schedule a single notification
        await LocalNotification.scheduleTaskHourNotification(
          taskName: newTaskName,
          dueDate: newDateTime,
          goalName: newGoalName,
        );
      }
    } catch (e) {
      debugPrint('Error updating task notification: $e');
      // You might want to show a snackbar or handle the error appropriately
    }
  }

  static Future<void> updateAllWeeklyTaskNotifications({
    required List<QueryDocumentSnapshot> tasks,
    required String newTaskName,
    required String goalName,
  }) async {
    for (var task in tasks) {
      final taskData = task.data() as Map<String, dynamic>;
      final DateTime taskDate = DateFormat('yyyy-MM-dd').parse(taskData['date']);
      final TimeOfDay startTime = _parseTimeString(taskData['startTime']);
      
      final DateTime taskDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        startTime.hour,
        startTime.minute,
      );

      await updateTaskNotification(
        oldTaskName: taskData['taskName'],
        oldGoalName: goalName,
        newTaskName: newTaskName,
        newGoalName: goalName,
        newDateTime: taskDateTime,
        isRecurring: true,
      );
    }
  }

  static TimeOfDay _parseTimeString(String timeStr) {
    try {
      timeStr = timeStr.trim().toUpperCase();
      final DateTime dateTime = DateFormat('hh:mm a').parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      debugPrint('Error parsing time string: $e');
      return TimeOfDay.now();
    }
  }
}