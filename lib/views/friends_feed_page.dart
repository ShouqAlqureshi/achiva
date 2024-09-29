import 'package:flutter/material.dart';

class FriendsFeedScreen extends StatelessWidget {
  const FriendsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends Feed"),
      ),
      body: const Center(
        child: Text("Friends Feed Content Here"),
      ),
    );
  }
}
