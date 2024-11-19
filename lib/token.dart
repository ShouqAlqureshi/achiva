import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

const platform = MethodChannel('com.achiva.app/integrity');

Future<String> getIntegrityToken() async {
  try {
    final String result = await platform.invokeMethod('getIntegrityToken');
    CheckToken().checkIntegrityToken(result);
    return result;
  } on PlatformException catch (e) {
    log("Failed to get integrity token: ${e.message}");
    return "";
  }
}
const platform2 = MethodChannel('com.example.app/recaptcha');

Future<String> getRecaptchaToken() async {
  try {
    final String result = await platform2.invokeMethod('getRecaptchaToken');
    return result;
  } on PlatformException catch (e) {
    print("Failed to get recaptcha token: ${e.message}");
    return "";
  }
}

class CheckToken {
  Future<void> checkIntegrityToken(String token) async {
    final Uri url = Uri.parse(
        'https://playintegrity.googleapis.com/v1/$token:decodeIntegrityToken');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_ACCESS_TOKEN', // Optional: Only if required
        },
        body: jsonEncode({/* request body if needed */}),
      );

      if (response.statusCode == 200) {
        // Process the response
        final data = jsonDecode(response.body);
        print('Token Check Successful: $data');
      } else {
        print('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }


Future<bool> verifyRecaptcha(String responseToken) async {
  final Uri url = Uri.parse('https://www.google.com/recaptcha/api/siteverify');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'secret': "6Lcy5E4qAAAAAO8aCkNMl4NBPpcZboOz6YVXZ3wr",
        'response': responseToken,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['success'] ?? false; // Check if the verification was successful
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    print('An error occurred: $e');
    return false;
  }
}

}
