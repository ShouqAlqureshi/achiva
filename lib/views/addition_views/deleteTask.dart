import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskOperations {
  /// Shows a confirmation dialog and handles the task deletion process
  /// Returns a Future<bool> indicating whether the deletion was successful
  static Future<bool> deleteTask(
    BuildContext context, 
    DocumentReference taskRef,
  ) async {
    bool wasDeleted = false;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<DocumentSnapshot>(
              future: taskRef.get(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Return empty widget while loading
                }

                if (snapshot.hasError) {
                  return AlertDialog(
                    title: Text('Error'),
                    content: Text('Failed to load task details'),
                    actions: [
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                }

                final taskData = snapshot.data?.data() as Map<String, dynamic>?;
                final bool isRepeating = taskData != null && 
                                       taskData.containsKey('redundancyId') && 
                                       taskData['redundancyId'] != null;

                if (!isRepeating) {
                  // Simple delete dialog for non-repeating tasks
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text(
                      'Delete Task',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Are you sure you want to delete this task? This action cannot be undone.',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Cancel', style: TextStyle(color: Colors.black)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          try {
                            await taskRef.delete();
                            wasDeleted = true;
                            Navigator.of(dialogContext).pop();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Task deleted successfully')),
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting task: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                }

                // Dialog for repeating tasks
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text(
                    'Delete Weekly Task',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'This is a weekly task. Would you like to delete just this one or all future tasks?',
                    style: TextStyle(color: Colors.black),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel', style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Delete This Only', 
                        style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        try {
                          await taskRef.delete();
                          wasDeleted = true;
                          Navigator.of(dialogContext).pop();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Task deleted successfully')),
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Error deleting task: $e')),
                          );
                        }
                      },
                    ),
                    TextButton(
                      child: Text('Delete All Weekly Tasks', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        try {
                          final String redundancyId = taskData!['redundancyId'];
                          final timestamp = taskData['timestamp'];
                          final tasksCollection = taskRef.parent;
                          
                          final querySnapshot = await tasksCollection
                            .where('redundancyId', isEqualTo: redundancyId)
                            .where('timestamp', isGreaterThanOrEqualTo: timestamp)
                            .get();
                          
                          final batch = FirebaseFirestore.instance.batch();
                          for (var doc in querySnapshot.docs) {
                            batch.delete(doc.reference);
                          }
                          await batch.commit();
                          
                          wasDeleted = true;
                          Navigator.of(dialogContext).pop();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Tasks deleted successfully'),
                            ),
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Error deleting tasks: $e')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    return wasDeleted;
  }
}