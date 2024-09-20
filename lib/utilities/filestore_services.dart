import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:achiva/models/goal.dart';

class FirestoreService {
  final CollectionReference goalCollection =
      FirebaseFirestore.instance.collection('goals');

  Future<void> addGoal(Goal goal) {
    return goalCollection.add(goal.toJson());
  }

  Stream<List<Goal>> getGoals() {
    return goalCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Goal.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
