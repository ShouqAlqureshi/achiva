import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class Validators {
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
    return !RegExp(r'^\+[0-9]{12,14}$').hasMatch(phonenumber);
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
