import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatParticipantsScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? docData;

  const ChatParticipantsScreen({super.key, required this.docData});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>>? usersData;

    _getUsers() async {
      var snapshot = await FirebaseFirestore.instance.collection('usersData').get();
      usersData = snapshot.docs.map((e) => e.data()).toList();
      return usersData;
    }

    return FutureBuilder(
      future: _getUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Scaffold(
              appBar: AppBar(),
              body: ListView.builder(
                itemCount: docData?.length,
                itemBuilder: (context, index) {
                  final whichUser = usersData?.firstWhere((element) {
                    return element['userId'] == docData?[index]['userId'];
                  });
                  return Text(whichUser?['username']);
                },
              ),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
