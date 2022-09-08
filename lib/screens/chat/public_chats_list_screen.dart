import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/constants.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat/public_chat_screen.dart';

class PublicChatsListScreen extends StatelessWidget {
  PublicChatsListScreen({Key? key}) : super(key: key);

  final currentUser = FirebaseAuth.instance.currentUser;
  final chatNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  static int _counter = 0;

  @override
  Widget build(BuildContext context) {
    if (_counter == 0) {
      _counter++;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        //INFO: this is the first screen of the app so deviceData initialization is done here
        //_counter is to make sure this function only runs when you first enter this screen
        deviceWidth = MediaQuery.of(context).size.width;
        deviceHeight = MediaQuery.of(context).size.height;
        screenWidth = deviceWidth * MediaQuery.of(context).devicePixelRatio;
        screenHeight = deviceHeight * MediaQuery.of(context).devicePixelRatio;
        middleX = (screenWidth / 2).round();
        middleY = ((screenHeight / 2) - 120).round();
      });
    }

    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(),
          body: Column(
            children: const [
              ChatsList(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            label: const Text('Add'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: SizedBox(
                      height: 210,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const Text(
                            'Add a New Public Chat',
                            style: TextStyle(fontSize: 20),
                          ),
                          Form(
                            key: formKey,
                            child: TextFormField(
                              key: const ValueKey('chatName'),
                              controller: chatNameController,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(labelText: 'Chat Name'),
                              maxLength: 30,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Chat Name cant be empty';
                                } else {
                                  return null;
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  tryAddNewChat(context);
                                },
                                child: const Text('Add New Public Chat'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> tryAddNewChat(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      try {
        final String generatedId = DateTime.now().microsecondsSinceEpoch.toString();

        await FirebaseFirestore.instance.collection('chats').doc(generatedId).set({
          'chatCreatorId': currentUser?.uid,
          'chatName': chatNameController.text,
          'createdAt': DateTime.now(),
          'lastUpdated': DateTime.now(),
          'lastMessage': '',
          'lastSender': '',
        }).then((_) {
          FirebaseFirestore.instance
              .collection('chats/$generatedId/participantsData')
              .doc(currentUser?.uid)
              .set({
            'userId': currentUser?.uid,
          });
        });
        chatNameController.text = '';
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeyy, added a new chat'),
            ),
          );
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
          ),
        );
      }
    }
  }
}

class ChatsList extends StatelessWidget {
  const ChatsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('lastUpdated', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> chatsSnapshot) {
        if (chatsSnapshot.connectionState == ConnectionState.none ||
            chatsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        //** Firebase dependant logic here;
        final chatsData = chatsSnapshot.data?.docs;
        // **

        return Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: chatsData?.length ?? 0,
            itemBuilder: (context, index) => ChatItem(
              currentUser: currentUser,
              individualChatData: chatsData?[index],
            ),
          ),
        );
      },
    );
  }
}

class ChatItem extends StatelessWidget {
  const ChatItem({super.key, required this.individualChatData, required this.currentUser});

  final QueryDocumentSnapshot<Object?>? individualChatData;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats/${individualChatData?.id}/participantsData')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> participantsSnapshot) {
        if (participantsSnapshot.connectionState == ConnectionState.waiting ||
            participantsSnapshot.connectionState == ConnectionState.none) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        //**index dependant logic here */
        DateTime dt = (individualChatData?['lastUpdated'] as Timestamp).toDate();
        String formattedDate = dt.day == DateTime.now().day
            ? DateFormat.Hm().format(dt)
            : DateFormat.yMMMMd().format(dt);

        final participantsData = participantsSnapshot.data?.docs;
        int index =
            participantsData?.map((e) => e.id).toList().indexOf(currentUser?.uid ?? '') ?? -1;
        final bool userBelongs = index != -1;
        String lastMessage = individualChatData?['lastMessage'] == ''
            ? '"This Chat is Empty"'
            : individualChatData?['lastMessage'];
        bool chatEmpty = individualChatData?['lastMessage'] == '';
        bool isLastSenderYou = individualChatData?['lastSender'] == currentUser?.uid;

        //** */

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(
                color: userBelongs ? Colors.teal : Colors.red,
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            color: Colors.grey[800],
            highlightColor: userBelongs ? Colors.teal.withOpacity(0.3) : Colors.red,
            splashColor: userBelongs ? Colors.teal : Colors.red,
            onPressed: () {
              if (userBelongs) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicChatScreen(
                      chatId: individualChatData?.id ?? '',
                    ),
                  ),
                );
              } else {
                simplerErrorMessage(
                  context,
                  'You Shall Not Pass!',
                  '',
                  null,
                  true,
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            //
                            Expanded(
                              child: Text(
                                individualChatData?['chatName'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: chatEmpty
                                    ? ''
                                    : isLastSenderYou
                                        ? 'You: '
                                        : '${individualChatData?['lastSender']}: ',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: lastMessage,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
