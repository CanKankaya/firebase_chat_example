import 'package:flutter/material.dart';

class OtherUserDataScreen extends StatelessWidget {
  final List<String> whichParticipantData;

  const OtherUserDataScreen({super.key, required this.whichParticipantData});

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
                        whichParticipantData[1],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Card(
                        child: Text(
                          whichParticipantData[2],
                        ),
                      ),
                      Card(
                        child: Text(
                          whichParticipantData[3],
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
