import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Validators {
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    if (!isValidEmail(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  bool isNotValidPhoneNumber(String phonenumber) {
    return !RegExp(r'^\+[0-9]{12,12}$').hasMatch(phonenumber.trim());
  }

  Future<bool> isGoalNameValid(String goalname, BuildContext context) async {
    if (goalname.trim().isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final String? userPhoneNumber = user.phoneNumber;
        if (userPhoneNumber == null) {
          throw Exception(
              "Phone number is not available for the logged-in user.");
        }

        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('phoneNumber', isEqualTo: userPhoneNumber)
            .limit(1)
            .get();

        DocumentReference userDocRef;
        if (userSnapshot.docs.isEmpty) {
          userDocRef =
              await FirebaseFirestore.instance.collection('Users').add({
            'phoneNumber': userPhoneNumber,
          });
        } else {
          userDocRef = userSnapshot.docs.first.reference;
        }

        CollectionReference goalsCollectionRef = userDocRef.collection('goals');
        DocumentSnapshot goalSnapshot =
            await goalsCollectionRef.doc(goalname).get();

        if (goalSnapshot.exists) {
          log("The goal name exists, try changing the name");
          return false;
        } else {
          return true;
        }
      } catch (e) {
        log("Error in validating goal name:$e");
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> isEmailUnique(String email,
      [FirebaseFirestore? firestore]) async {
    try {
      // Use the provided firestore instance or the default one
      firestore ??= FirebaseFirestore.instance;

      // Reference to the Users collection
      CollectionReference users = firestore.collection('Users');

      // Query the collection for documents where 'email' field matches the given email
      QuerySnapshot querySnapshot =
          await users.where('email', isEqualTo: email).limit(1).get();

      // If the query returns no documents, the email is unique
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      log('Error checking email uniqueness: $e');
      // In case of an error, we can't confirm uniqueness, so return false
      return false;
    }
  }

  String? validatePhoneNum(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number required";
    }
    if (isNotValidPhoneNumber(value)) {
      return "Invalid phone number ex.+966531567889";
    }
    return null;
  }

  String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return "Code field is required";
    }
    if (value.length < 6) {
      return "code must be 6 digits";
    }
    return null;
  }
}
