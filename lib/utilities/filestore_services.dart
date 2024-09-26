import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:achiva/models/goal.dart';
import '../models/models.dart';


class FirestoreService {
  final CollectionReference goalCollection =
      FirebaseFirestore.instance.collection('goals');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to get user profile data
  Future<User?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();

      if (doc.exists) {
        return User.fromDocument(doc); // Assuming UserProfile has a fromDocument method
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null; // Return null if there's an error or no data found
  }



  Future<void> addGoal(Goal goal) {
    return goalCollection.add(goal.toJson());
  }


}




  

