// User Model
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String username;
  String fname;
  String lname;
  String email;
  String gender;
  String photo;
  String phoneNumber;
  int streak;
  int productivity;
  int noGoals;
  int noFriends;
  List<Friend> friends;

  User({
    required this.username,
    required this.fname,
    required this.lname,
    required this.email,
    required this.gender,
    required this.photo,
    required this.phoneNumber,
    required this.streak,
    required this.productivity,
    required this.noGoals,
    required this.noFriends,
    required this.friends,
  });
  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return User(
      username: data['username'] ?? '', // Map the username field
      fname: data['firstName'] ?? '', // If the field is missing, default to an empty string
      lname: data['lastName'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      photo: data['photo'] ?? '', // URL or path to the user's photo
      phoneNumber: data['phoneNumber'] ?? '',
      streak: data['streak'] ?? 0, // Default to 0 if the field is missing
      productivity: data['productivity'] ?? 0, // Default to 0 if the field is missing
      noGoals: data['noGoals'] ?? 0, // Default to 0 if the field is missing
      noFriends: data['noFriends'] ?? 0, // Default to 0 if the field is missing
      friends: data['friends'] ?? 0, // Assuming Friend has a fromDocument method
    );
  }

}

// Friend Model
class Friend {
  String friendsUsername;
  String status;

  Friend({required this.friendsUsername, required this.status});
}


// Task Model
class Task {
  int id;
  String name;
  String description;
  String location;
  String date;
  String time;
  int duration;
  String status;
  RepeatingTask? repeatingTask;
  Post? post;
  List<Reaction> reactions;

  Task({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.repeatingTask,
    this.post,
    required this.reactions,
  });
}

// Repeating Task Model
class RepeatingTask {
  int mainTaskId;
  String frequency;
  List<RelatedTask> relatedTasks;

  RepeatingTask({
    required this.mainTaskId,
    required this.frequency,
    required this.relatedTasks,
  });
}

// Related Task Model
class RelatedTask {
  int taskId;
  String date;
  String status;

  RelatedTask({
    required this.taskId,
    required this.date,
    required this.status,
  });
}

// Post Model
class Post {
  int taskId;
  String photo;
  int noReaction;
  String postDate;

  Post({
    required this.taskId,
    required this.photo,
    required this.noReaction,
    required this.postDate,
  });
}

// Reaction Model
class Reaction {
  String friendsUsername;
  String emoji;

  Reaction({
    required this.friendsUsername,
    required this.emoji,
  });
}