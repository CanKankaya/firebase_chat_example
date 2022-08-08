import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final documents = snapshot.data?.docs;
          return ListView.builder(
            itemCount: documents?.length,
            itemBuilder: (context, index) => Container(
              padding: const EdgeInsets.all(8),
              child: Text(documents?[index]['text']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseFirestore.instance
              .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
              .add({'text': 'test here'});

          //     .listen((event) {
          //   inspect(event.docs.first['text']);
          // });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
