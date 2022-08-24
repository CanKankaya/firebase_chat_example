import 'package:flutter/material.dart';

class OtherUserDataScreen extends StatelessWidget {
  final Map<String, dynamic>? user;

  const OtherUserDataScreen({super.key, required this.user});

  //TODO: Fill this page aswell, with new data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        user?['userImageUrl'] ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Card(
                        child: Text(
                          user?['username'] ?? '',
                        ),
                      ),
                      Card(
                        child: Text(
                          user?['userDetail'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
