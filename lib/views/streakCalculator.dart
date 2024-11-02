import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StreakCalculator {
  static DateTime getLatestEndTime(List<DocumentSnapshot> tasks) {
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

  static bool isAnyTaskCompleted(List<DocumentSnapshot> tasks) {
    return tasks.any((task) => task["completed"]);
  }

  static bool isBeforeEndTime(List<DocumentSnapshot> tasks) {
    DateTime latestEndTime = getLatestEndTime(tasks);
    DateTime now = DateTime.now();
    return now.isBefore(latestEndTime);
  }

  static bool isAnyTaskCompletedBeforeEndTime(List<DocumentSnapshot> tasks) {
    return isAnyTaskCompleted(tasks) && isBeforeEndTime(tasks);
  }

  static Future<void> updateStreak(List<DocumentSnapshot> tasks, String goalDocumentId, {DocumentSnapshot? taskOne}) async {
    var postsSnapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("allPosts")
        .get();

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
        .doc(goalDocumentId);

    var goalSnapshot = await goalDocRef.get();
    bool isGoalCompleted = goalSnapshot.data()?['completed'] ?? false;
    bool isGoalFinished = goalSnapshot.data()?['finished'] ?? false;

    bool isAnyTaskCompleted = StreakCalculator.isAnyTaskCompleted(tasks);
    bool isBeforeEndTime = StreakCalculator.isBeforeEndTime(tasks);
    bool hasMatchingTaskId = hasTaskId(tasks);

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
      }
    }
  }
}