import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:achiva/utilities/local_notification.dart';

class TaskOperations {
  static Future<bool> deleteTask(
    BuildContext context, 
    DocumentReference taskRef,
    String goalName,
  ) async {
    bool wasDeleted = false;
    bool isLoading = false;
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AlertDialog(
                    title: const Text('Error'),
                    content: const Text('Failed to load task details'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  );
                }

                final taskData = snapshot.data?.data() as Map<String, dynamic>?;
                final bool isRepeating = taskData != null && 
                                       taskData.containsKey('redundancyId') && 
                                       taskData['redundancyId'] != null;
                final String taskName = taskData?['name'] ?? '';

                Widget dialogContent;
                if (isLoading) {
                  dialogContent = const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Deleting task...'),
                        ],
                      ),
                    ),
                  );
                } else if (!isRepeating) {
                  dialogContent = AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text(
                      'Delete Task',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Are you sure you want to delete this task? This action cannot be undone.',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          setState(() => isLoading = true);
                          try {
                            await LocalNotification.cancelNotification(
                              taskName: taskName,
                              goalName: goalName,
                            );
                            await taskRef.delete();
                            wasDeleted = true;
                            Navigator.of(dialogContext).pop();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Task deleted successfully')),
                            );
                          } catch (e) {
                            setState(() => isLoading = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting task: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                } else {
                  dialogContent = AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text(
                      'Delete Weekly Task',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'This is a weekly task. Would you like to delete just this one or all future tasks?',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        child: const Text('Delete This Only', 
                          style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          setState(() => isLoading = true);
                          try {
                            await LocalNotification.cancelNotification(
                              taskName: taskName,
                              goalName: goalName,
                            );
                            await taskRef.delete();
                            wasDeleted = true;
                            Navigator.of(dialogContext).pop();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Task deleted successfully')),
                            );
                          } catch (e) {
                            setState(() => isLoading = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting task: $e')),
                            );
                          }
                        },
                      ),
                      TextButton(
                        child: const Text('Delete All Weekly Tasks', 
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          setState(() => isLoading = true);
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
                              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                              await LocalNotification.cancelNotification(
                                taskName: data['name'] ?? '',
                                goalName: goalName,
                              );
                              batch.delete(doc.reference);
                            }
                            
                            await batch.commit();
                            wasDeleted = true;
                            Navigator.of(dialogContext).pop();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Tasks deleted successfully')),
                            );
                          } catch (e) {
                            setState(() => isLoading = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting tasks: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                }

                return dialogContent;
              },
            );
          },
        );
      },
    );

    return wasDeleted;
  }
}