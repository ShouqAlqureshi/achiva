import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utilities/show_log_out_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<MenuAction>(onSelected: (value) async {
            switch (value) {
              case MenuAction.logout:
                try {
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseAuth.instance.signOut();
                    } else {
                      throw UserNotLoggedInAuthException();
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/phoneauth', (_) => false);
                  }
                } on UserNotLoggedInAuthException catch (_) {
                  showErrorDialog(context, "null user; user is not loged in");
                }
            }
          }, itemBuilder: (context) {
            return const [
              PopupMenuItem<MenuAction>(
                  value: MenuAction.logout, child: Text("Log out")),
            ];
          }),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome buddy",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
