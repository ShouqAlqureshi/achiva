package com.example.achiva

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
// val integrityManager = IntegrityManagerFactory.create(applicationContext)
// val integrityTokenRequest = IntegrityTokenRequest.builder()
//     .setCloudProjectNumber(YOUR_PROJECT_NUMBER)
//     .build()

// integrityManager.requestIntegrityToken(integrityTokenRequest)
//     .addOnSuccessListener { response ->
//         val token = response.token()
//         // Pass this token back to Flutter for further use.
//     }
//     .addOnFailureListener { exception ->
//         // Handle error.
//     }
//     val safetyNetClient = SafetyNet.getClient(this)
// safetyNetClient.verifyWithRecaptcha(SITE_KEY)
//     .addOnSuccessListener { response ->
//         val token = response.tokenResult
//         // Pass the token back to Flutter
//     }
//     .addOnFailureListener { exception ->
//         // Handle the error.
//     }