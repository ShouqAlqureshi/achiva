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
  

Future<bool> isEmailUnique(String email) async {
  try {
    // Reference to the Users collection
    CollectionReference users = FirebaseFirestore.instance.collection('Users');

    // Query the collection for documents where 'email' field matches the given email
    QuerySnapshot querySnapshot = await users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    // If the query returns no documents, the email is unique
    return querySnapshot.docs.isEmpty;
  } catch (e) {
    log('Error checking email uniqueness: $e');
    // In case of an error, we can't confirm uniqueness, so return false
    return false;
  }
}

}
