import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_chat_example/widgets/error_message.dart';
import 'package:firebase_chat_example/widgets/alert_dialog.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/other_userdata_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(),
          body: Column(
            children: [
              Expanded(
                child: Messages(),
              ),
              NewMessage(),
            ],
          ),
        ),
      ),
    );
  }
}

class NewMessage extends StatelessWidget {
  NewMessage({Key? key}) : super(key: key);
  final ValueNotifier<String> _enteredMessage = ValueNotifier<String>('');

  final _controller = TextEditingController();

  void _sendMessage() async {
    final auth = FirebaseAuth.instance;
    FirebaseFirestore.instance.collection('chats/dJa1VvWu8w3ECOCV6tUb/messages').add({
      'text': _enteredMessage.value,
      'createdAt': Timestamp.now(),
      'userId': auth.currentUser?.uid,
    });
    _controller.clear();
    _enteredMessage.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        height: 65,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                autocorrect: true,
                enableSuggestions: true,
                textCapitalization: TextCapitalization.sentences,
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Send a message...'),
                onChanged: (val) {
                  _enteredMessage.value = val.trim();
                },
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _enteredMessage,
              builder: (_, String value, __) {
                return IconButton(
                  onPressed: value.isEmpty ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: value.isEmpty ? Colors.grey : Colors.amber,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Messages extends StatelessWidget {
  Messages({Key? key}) : super(key: key);

  final ValueNotifier<int> _itemCount = ValueNotifier<int>(10);

  _deleteMessage(messageId) async {
    await FirebaseFirestore.instance
        .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Messages build method ran');

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats/dJa1VvWu8w3ECOCV6tUb/messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const Center(
        //     child: CircularProgressIndicator(),
        //   );
        // } else
        {
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                print('DEBUG: Messages waiting for participantsData');
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final deviceSize = MediaQuery.of(context).size;
              final documents = snapshot.data?.docs;
              print('DEBUG: set message data');
              final participantsData = userSnapshot.data?.docs;
              print('DEBUG: set participantsData');
              final scrollController = ScrollController();
              print('DEBUG: built the widget');

              return RefreshIndicator(
                onRefresh: () async {
                  //TODO scroll up after refresh, doesnt work atm, scroll down works fine

                  if ((documents?.length ?? 0) > _itemCount.value) {
                    _itemCount.value += 10;
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.linear,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You are already seeing all messages'),
                      ),
                    );
                  }
                },
                child: ValueListenableBuilder(
                  valueListenable: _itemCount,
                  builder: (_, int itemCountValue, Widget? child) {
                    return ListView.builder(
                      controller: scrollController,
                      reverse: true,
                      itemCount: (documents?.length ?? 0) > itemCountValue
                          ? itemCountValue
                          : (documents?.length ?? 0),
                      itemBuilder: (context, index) {
                        bool isMe =
                            documents?[index]['userId'] == FirebaseAuth.instance.currentUser?.uid;
                        final whichParticipant = participantsData?.firstWhere(
                          (element) {
                            return element['userId'] == documents?[index]['userId'];
                          },
                        );
                        DateTime dt = (documents?[index]['createdAt'] as Timestamp).toDate();
                        final isToday = dt.day == DateTime.now().day;
                        String formattedDate =
                            isToday ? DateFormat.Hm().format(dt) : DateFormat.yMMMMd().format(dt);

                        return Dismissible(
                          key: ValueKey(documents?[index]),
                          background: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.green,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Not a delete',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                          ),
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.red,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  'Delete',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                                Icon(Icons.delete)
                              ],
                            ),
                          ),
                          dismissThresholds: const {
                            DismissDirection.startToEnd: 0.6,
                            DismissDirection.endToStart: 0.6,
                          },
                          direction:
                              isMe ? DismissDirection.horizontal : DismissDirection.startToEnd,
                          onDismissed: (direction) {},
                          confirmDismiss: (DismissDirection dismissDirection) async {
                            switch (dismissDirection) {
                              case DismissDirection.startToEnd:
                                {
                                  errorMessage(
                                    context,
                                    'Don\'t slide me to the left please',
                                    'Uhm ok...',
                                    () => {},
                                    true,
                                  );
                                  break;
                                }
                              case DismissDirection.endToStart:
                                {
                                  _deleteMessage(documents?[index].id);
                                  break;
                                }
                              default:
                                break;
                            }
                            return false;
                          },
                          child: InkWell(
                            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                            splashColor: Colors.amber,
                            onLongPress: () {
                              showMyDialog(
                                context,
                                true,
                                'Message Detail',
                                'Sent by \'${whichParticipant?['username']}\'',
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
                                  mainAxisAlignment:
                                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isMe ? Colors.white : Colors.black,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(15),
                                          topRight: const Radius.circular(15),
                                          bottomLeft: isMe
                                              ? const Radius.circular(15)
                                              : const Radius.circular(0),
                                          bottomRight: isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(15),
                                        ),
                                      ),
                                      width: deviceSize.width * 0.65,
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
                                          if (!isMe)
                                            Text(
                                              whichParticipant?['username'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? Colors.black : Colors.white,
                                              ),
                                            ),
                                          if (!isMe) const SizedBox(height: 5),
                                          Text(
                                            documents?[index]['text'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isMe ? Colors.black : Colors.white,
                                            ),
                                            textAlign: isMe ? TextAlign.end : TextAlign.start,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe
                                                  ? const Color.fromARGB(255, 60, 60, 60)
                                                  : const Color.fromARGB(255, 195, 195, 195),
                                            ),
                                            textAlign: isMe ? TextAlign.end : TextAlign.start,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  left: isMe ? null : deviceSize.width * 0.65 - 22,
                                  right: isMe ? deviceSize.width * 0.65 - 22 : null,
                                  child: GestureDetector(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OtherUserDataScreen(
                                            whichParticipantData: [
                                              whichParticipant?['userId'] ?? '',
                                              whichParticipant?['userImageUrl'] ?? '',
                                              whichParticipant?['username'] ?? '',
                                              whichParticipant?['userDetail'] ?? '',
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                          color: Colors.amber,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(
                                          whichParticipant?['userImageUrl'] ?? '',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  // child: Messages(),
                ),
              );
            },
          );
        }
      },
    );
  }
}
