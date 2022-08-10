import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_chat_example/widgets/alert_dialog.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(),
        body: Column(
          children: const [
            Expanded(child: Messages()),
            NewMessage(),
          ],
        ),
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

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
        .add({
      'text': _enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': user?.uid,
      'username': user?.displayName,
      'userImageUrl': user?.photoURL,
    });
    _controller.clear();
    setState(() {
      _enteredMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                autocorrect: true,
                enableSuggestions: true,
                textCapitalization: TextCapitalization.sentences,
                controller: _controller,
                decoration:
                    const InputDecoration(labelText: 'Send a message...'),
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
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          final documents = snapshot.data?.docs;
          return ListView.builder(
            reverse: true,
            itemCount: documents?.length ?? 0,
            itemBuilder: (context, index) {
              bool isMe = documents?[index]['userId'] ==
                  FirebaseAuth.instance.currentUser?.uid;
              // final whichUserId = documents?[index]['userId'];
              return InkWell(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                splashColor: Colors.amber,
                onLongPress: () {
                  DateTime dt =
                      (documents?[index]['createdAt'] as Timestamp).toDate();
                  String formattedDate =
                      DateFormat('yyyy-MM-dd – kk:mm').format(dt);
                  showMyDialog(
                    context,
                    true,
                    'Message Detail',
                    'Sent by \'${documents?[index]['username']}\'',
                    formattedDate,
                    'ok',
                    Navigator.of(context).pop,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      key: ValueKey(documents?[index].id),
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white : Colors.black,
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
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                documents?[index]['username'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.black : Colors.white,
                                ),
                              ),
                              Text(
                                documents?[index]['text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                ),
                                textAlign:
                                    isMe ? TextAlign.end : TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      left: isMe ? null : 120,
                      right: isMe ? 120 : null,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          documents?[index]['userImageUrl'] ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}
