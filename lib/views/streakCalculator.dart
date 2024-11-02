import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Fixed import

class StreakCalculator {
  static const String LAST_CHECK_KEY = 'last_streak_check';
  static bool _isInitialized = false;
  
  // Initialize streak checking when app starts
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check if we need to update streak
    await _checkAndUpdateStreak();
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static Future<void> _checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(LAST_CHECK_KEY) ?? 0;
    final now = DateTime.now();
    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);

    // If we haven't checked today, update the streak
    if (!isSameDay(now, lastCheckDate)) {
      await updateStreak();
      // Save the current time as last check
      await prefs.setInt(LAST_CHECK_KEY, now.millisecondsSinceEpoch);
    }
  }

  static Future<void> updateStreak() async {
    final userDoc = FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    // Get all posts sorted by postDate
    var postsSnapshot = await userDoc
        .collection("allPosts")
        .orderBy('postDate', descending: true)
        .get();
    
    // If there are no posts, reset streak
    if (postsSnapshot.docs.isEmpty) {
      await _resetStreak(userDoc);
      return;
    }

    // Convert posts to list of dates and normalize them (remove time component)
    List<DateTime> postDates = postsSnapshot.docs
        .map((doc) {
          DateTime postDate = (doc.data()['postDate'] as Timestamp).toDate();
          return DateTime(postDate.year, postDate.month, postDate.day);
        })
        .toList();

    // Calculate streak based on consecutive posts
    int streak = _calculateStreak(postDates);

    // Update streak and streakStartDate in Firestore
    if (streak > 0) {
      DateTime streakStartDate = DateTime.now().subtract(Duration(days: streak - 1));
      await userDoc.update({
        'streak': streak,
        'streakStartDate': Timestamp.fromDate(streakStartDate)
      });
    } else {
      await _resetStreak(userDoc);
    }
  }

  static int _calculateStreak(List<DateTime> postDates) {
    if (postDates.isEmpty) return 0;

    // Sort dates in descending order (most recent first)
    postDates.sort((a, b) => b.compareTo(a));
    
    DateTime now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day
    );

    // Check if there's a post today
    if (!isSameDay(postDates[0], now)) {
      return 0;  // Reset streak if no post today
    }

    int streak = 1;  // Start with 1 for today
    DateTime expectedDate = now;

    // Count consecutive days
    for (int i = 0; i < postDates.length; i++) {
      if (isSameDay(postDates[i], expectedDate)) {
        if (i < postDates.length - 1) {
          // Look for the next expected date
          expectedDate = expectedDate.subtract(Duration(days: 1));
        }
      } else if (!isSameDay(postDates[i], postDates[i - 1])) {
        // If we find a gap, stop counting
        break;
      }
      // If it's the same day as the previous post, continue checking
    }

    // Count how many days we went back successfully
    streak = now.difference(expectedDate).inDays + 1;
    return streak;
  }

  static Future<void> _resetStreak(DocumentReference userDoc) async {
    await userDoc.update({
      'streak': 0,
      'streakStartDate': Timestamp.fromDate(DateTime.now())
    });
  }
}