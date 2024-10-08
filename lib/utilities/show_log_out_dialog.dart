import 'package:flutter/material.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        // ignore: prefer_const_constructors
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 54, 52, 58),
          title: const Icon(Icons.exit_to_app),
          content: const Text(
            "Are you sure you want to log out ?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                )),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text(
                  "Log out",
                  style: TextStyle(color: Colors.white),
                ))
          ],
        );
      }).then((value) => value ?? false);
}
