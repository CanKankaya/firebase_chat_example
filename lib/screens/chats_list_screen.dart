import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

//TODO: Add some way to create a new Chat

//TODO: Make users able to join or leave chats

  @override
  Widget build(BuildContext context) {
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
  final QueryDocumentSnapshot<Object?>? individualChatData;

  ChatItem({super.key, required this.individualChatData});
  final currentUser = FirebaseAuth.instance.currentUser;

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

        print(participantsData);
        // final QueryDocumentSnapshot<Object?>? whichParticipant = participantsData?.firstWhere(
        //   (element) {
        //     if (element.exists) {
        //       return element['userId'] == currentUser?.uid;
        //     } else {
        //       return false;
        //     }
        //   },
        // );
        // print(whichParticipant);

        return InkWell(
          splashColor: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: individualChatData?.id ?? '',
                ),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.construction),
              Column(
                children: [
                  Text(individualChatData?.id ?? ''),
                  Text(formattedDate),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
