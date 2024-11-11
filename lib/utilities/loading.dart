import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    ),
  );
}

Widget noResults(String massage) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/images/no-results.png',
              fit: BoxFit.contain,
              height: 100,
            ),
            SizedBox(height: 40),
            Text(
              massage,
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
    ),
  );
}
