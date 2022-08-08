import 'package:firebase_auth/firebase_auth.dart';
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
      body: Column(
        children: const [
          Expanded(child: Messages()),
          NewMessage(),
        ],
      ),
    );
  }
}

class NewMessage extends StatefulWidget {
  const NewMessage({
    Key? key,
  }) : super(key: key);

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  var _enteredMessage = '';
  final _controller = TextEditingController();
  void _sendMessage() {
    FirebaseFirestore.instance
        .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
        .add({
      'text': _enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'username': FirebaseAuth.instance.currentUser?.displayName,
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Send a message...'),
              onChanged: (value) {
                setState(() {
                  _enteredMessage = value.trim();
                });
              },
            ),
          ),
          IconButton(
            onPressed: _enteredMessage.isEmpty ? null : _sendMessage,
            icon: Icon(
              Icons.send,
              color: _enteredMessage.isEmpty ? Colors.grey : Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class Messages extends StatelessWidget {
  const Messages({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final documents = snapshot.data?.docs;

        return ListView.builder(
          reverse: true,
          itemCount: documents?.length,
          itemBuilder: (context, index) {
            bool isMe = documents?[index]['userId'] ==
                FirebaseAuth.instance.currentUser?.uid;
            return Row(
              key: ValueKey(documents?[index].id),
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isMe
                          ? const Radius.circular(12)
                          : const Radius.circular(0),
                      bottomRight: !isMe
                          ? const Radius.circular(12)
                          : const Radius.circular(0),
                    ),
                  ),
                  width: 140,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        documents?[index]['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        textAlign: isMe ? TextAlign.end : TextAlign.start,
                        documents?[index]['text'],
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
