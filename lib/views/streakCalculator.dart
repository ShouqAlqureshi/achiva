import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakCalculator {
  static const String LAST_CHECK_KEY = 'last_streak_check';
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _checkAndUpdateStreak();
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isWithin24Hours(DateTime date1, DateTime date2) {
    return date1.difference(date2).inHours.abs() <= 24;
  }

  static Future<void> _checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(LAST_CHECK_KEY) ?? 0;
    final now = DateTime.now();
    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);

    if (!isSameDay(now, lastCheckDate)) {
      await updateStreak();
      await prefs.setInt(LAST_CHECK_KEY, now.millisecondsSinceEpoch);
    }
  }

static Future<void> updateStreak() async {
  final userDoc = FirebaseFirestore.instance
      .collection("Users")
      .doc(FirebaseAuth.instance.currentUser!.uid);

  // Fetch the user document
  DocumentSnapshot userSnapshot = await userDoc.get();

  // Check if 'streak' field exists
  if (!userSnapshot.exists || (userSnapshot.data() as Map<String, dynamic>?)?.containsKey('streak') != true) {
    // Initialize 'streak' and 'streakStartDate' if they don't exist
    await userDoc.set({
      'streak': 0,
      'streakStartDate': Timestamp.fromDate(DateTime.now())
    }, SetOptions(merge: true));
  }

  var postsSnapshot = await userDoc
      .collection("allPosts")
      .orderBy('postDate', descending: true)
      .get();
  
  if (postsSnapshot.docs.isEmpty) {
    await _resetStreak(userDoc);
    return;
  }

  List<DateTime> postDates = postsSnapshot.docs
      .map((doc) {
        return (doc.data()['postDate'] as Timestamp).toDate();
      })
      .toList();

  int streak = _calculateStreak(postDates);

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

    postDates.sort((a, b) => b.compareTo(a));
    DateTime now = DateTime.now();
    
    // If the most recent post is more than 24 hours ago, streak is broken
    if (!isWithin24Hours(now, postDates[0])) {
      return 0;
    }

    int streak = 1;  // Start with 1 for the most recent post
    DateTime currentDate = DateTime(
      postDates[0].year,
      postDates[0].month,
      postDates[0].day,
    );

    // Start from index 0 since we've already verified there's a recent post
    for (int i = 0; i < postDates.length - 1; i++) {
      // If this is a duplicate post for the same day, skip it
      if (isSameDay(postDates[i], postDates[i + 1])) {
        continue;
      }
      
      // Check if the next post is from the previous day
      DateTime nextExpectedDate = currentDate.subtract(Duration(days: 1));
      if (isSameDay(postDates[i + 1], nextExpectedDate)) {
        streak++;
        currentDate = nextExpectedDate;
      } else {
        // Found a gap, stop counting
        break;
      }
    }

    return streak;
  }

  static Future<void> _resetStreak(DocumentReference userDoc) async {
    await userDoc.update({
      'streak': 0,
      'streakStartDate': Timestamp.fromDate(DateTime.now())
    });
  }
}