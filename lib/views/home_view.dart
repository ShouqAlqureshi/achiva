import 'package:achiva/enum/menu_action.dart';
import 'package:achiva/exceptions/auth_exceptions.dart';
import 'package:achiva/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:achiva/views/add_goal_page.dart';
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
      body: Center(
               child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Achiva!',
              style: TextStyle(fontSize: 24),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddGoalPage()), // Navigate to AddGoalPage
                );
              },
              child: const Text('Add a Goal'),
            ),
          ],
        ),
      ),
    );
  }
}
