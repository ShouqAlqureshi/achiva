import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskOperations {
  /// Shows a confirmation dialog and handles the task deletion process
  /// Returns a Future<bool> indicating whether the deletion was successful
  static Future<bool> deleteTask(BuildContext context, DocumentReference taskRef) async {
    bool wasDeleted = false;
    
    // Show confirmation dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await taskRef.delete();
                  wasDeleted = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                  Navigator.of(context).pop(); // Close dialog
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    return wasDeleted;
  }
}