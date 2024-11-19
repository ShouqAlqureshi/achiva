import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;
  Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData =
          FirebaseAuth.instance.currentUser?.providerData.first;

      if (AppleAuthProvider().providerId == providerData!.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(AppleAuthProvider());
      } else if (GoogleAuthProvider().providerId == providerData.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(GoogleAuthProvider());
      }

      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      log("$e");
    }
  }

  // Method to delete user from Firestore and FirebaseAuth
  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current logged-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // Get user's phone number (or use user.uid if using UIDs as document IDs)
      String? userUid = user.uid;

      //delete subcollection goals and goals[tasks]
      Future<QuerySnapshot> goals = FirebaseFirestore.instance
          .collection('Users')
          .doc(userUid)
          .collection("goals")
          .get();
      goals.then((value) async {
        for (var goalsDoc in value.docs) {
          DocumentReference goalsDocRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userUid)
              .collection("goals")
              .doc(goalsDoc.id);
          Future<QuerySnapshot> tasks = FirebaseFirestore.instance
              .collection('Users')
              .doc(userUid)
              .collection("goals")
              .doc(goalsDoc.id)
              .collection("tasks")
              .get();
          tasks.then(
            (value) async {
              for (var tasksDoc in value.docs) {
                DocumentReference tasksDocRef = FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userUid)
                    .collection("goals")
                    .doc(goalsDoc.id)
                    .collection("tasks")
                    .doc(tasksDoc.id);
                await tasksDocRef.delete();
              }
            },
          );
          await goalsDocRef.delete();
        }
      });
      // Delete the user document from Firestore
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userUid); // Use user.uid if using UIDs

      await userDocRef.delete();

      // Delete the user from FirebaseAuth
      try {
        await deleteUserAccount(user);
      } on FirebaseAuthException catch (e) {
        log("$e");

        if (e.code == "requires-recent-login") {
          await _reauthenticateAndDelete();
        }
      }

      // Show success message and navigate to the login screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully.')),
        );
      }

      // Navigate to the login screen (or any other screen you prefer)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/phoneauth');
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Account"),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator while deleting account
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Are you sure you want to delete your account?",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red, // Set button color to red for warning
                    ),
                    onPressed: _deleteAccount,
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  Future<void> deleteUserAccount(auth) async {
    try {
      final user = auth;
      if (user != null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration process is canceled successfully.'),
          ),
        );

      } else {
        log('No user is currently signed in.');
      }
    } catch (e) {
      log('Error deleting user account: $e');
    }
  }
}