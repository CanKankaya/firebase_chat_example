import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat/public_chat_screen.dart';

class PublicChatsListScreen extends StatelessWidget {
  const PublicChatsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final chatNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> tryAddNewChat() async {
      if (formKey.currentState!.validate()) {
        try {
          Navigator.pop(context);
          final String generatedId = DateTime.now().microsecondsSinceEpoch.toString();

          await FirebaseFirestore.instance.collection('chats').doc(generatedId).set({
            'chatCreatorId': currentUser?.uid,
            'chatName': chatNameController.text,
            'createdAt': DateTime.now(),
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
                                  tryAddNewChat();
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
}

class ChatsList extends StatelessWidget {
  const ChatsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> chatsSnapshot) {
        if (chatsSnapshot.connectionState == ConnectionState.waiting ||
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
        DateTime dt = (individualChatData?['createdAt'] as Timestamp).toDate();
        String formattedDate = DateFormat.yMMMMd().format(dt);
        final participantsData = participantsSnapshot.data?.docs;
        int index =
            participantsData?.map((e) => e.id).toList().indexOf(currentUser?.uid ?? '') ?? -1;
        final bool userBelongs = index != -1;
        //** */

        return InkWell(
          splashColor: Colors.amber,
          onTap: () {
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.chat,
                      color: Colors.white,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        individualChatData?['chatName'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
