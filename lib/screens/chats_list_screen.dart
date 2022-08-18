import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final chatNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> tryAddNewChat() async {
      if (formKey.currentState!.validate()) {
        try {
          Navigator.pop(context);

          await FirebaseFirestore.instance.collection('chats').add({
            'chatCreatorId': currentUser?.uid,
            'chatName': chatNameController.text,
            'createdAt': DateTime.now(),
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
                                child: const Text('button'),
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
            itemBuilder: (context, index) => ChatItem(individualChatData: chatsData?[index]),
          ),
        );
      },
    );
  }
}

class ChatItem extends StatelessWidget {
  ChatItem({super.key, required this.individualChatData});

  final QueryDocumentSnapshot<Object?>? individualChatData;
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  Future<void> tryAddParticipant() async {
    //
    _isLoading.value = true;

    try {
      await FirebaseFirestore.instance
          .collection('chats/${individualChatData?.id}/participantsData')
          .doc(_currentUser?.uid)
          .set({
        'userId': _currentUser?.uid,
        // 'username': _currentUser?.displayName,
        // 'userImageUrl': _currentUser?.photoURL,
        // 'userDetail': '',
      });
      _isLoading.value = false;
    } catch (error) {
      //
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime dt = (individualChatData?['createdAt'] as Timestamp).toDate();
    String formattedDate = DateFormat.yMMMMd().format(dt);

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats/${individualChatData?.id}/participantsData')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting ||
            usersSnapshot.connectionState == ConnectionState.none) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final participantsData = usersSnapshot.data?.docs;
        int index =
            participantsData?.map((e) => e.id).toList().indexOf(_currentUser?.uid ?? '') ?? -1;
        final bool userBelongs = index != -1;
        return InkWell(
          splashColor: Colors.amber,
          onTap: () {
            if (userBelongs) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
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
          child: Row(
            children: [
              const Icon(Icons.construction),
              Column(
                children: [
                  Text(individualChatData?['chatName'] ?? ''),
                  Text(formattedDate),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (userBelongs) {
                    simplerErrorMessage(
                      context,
                      'You are already a participant here',
                      '',
                      null,
                      true,
                    );
                  } else {
                    tryAddParticipant();

                    // simplerErrorMessage(
                    //   context,
                    //   'Doing nothing yet, this button will add you as a participant later',
                    //   '',
                    //   null,
                    //   true,
                    // );

                  }
                },
                icon: ValueListenableBuilder(
                    valueListenable: _isLoading,
                    builder: (_, bool loadingValue, __) {
                      return loadingValue
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.add);
                    }),
              ),
            ],
          ),
        );
      },
    );
  }
}
