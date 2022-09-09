import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat/private_chat_screen.dart';

class PrivateChatsListScreen extends StatelessWidget {
  const PrivateChatsListScreen({Key? key}) : super(key: key);

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
//TODO: add a way to start a private chat here

class ChatsList extends StatelessWidget {
  const ChatsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('privateChats')
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
        final currentUserChats = chatsData
            ?.where(
              (element) => element.id.contains('${currentUser?.uid}'),
            )
            .toList();
        // **

        return Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: currentUserChats?.length ?? 0,
            itemBuilder: (context, index) => ChatItem(
              currentUser: currentUser,
              individualChatData: currentUserChats?[index],
            ),
          ),
        );
      },
    );
  }
}

class ChatItem extends StatelessWidget {
  const ChatItem({super.key, required this.individualChatData, required this.currentUser});

  final DocumentSnapshot<Object?>? individualChatData;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot<Object?>>? participantsData;

    Future _getParticipants() async {
      QuerySnapshot participantsSnapshot = await FirebaseFirestore.instance
          .collection('privateChats/${individualChatData?.id}/participantsData')
          .get();
      participantsData = participantsSnapshot.docs;
    }

    return FutureBuilder(
      future: _getParticipants(),
      builder: (context, participantsSnapshot) {
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
        String lastMessage = individualChatData?['lastMessage'] == ''
            ? '"This Chat is Empty"'
            : individualChatData?['lastMessage'];
        bool chatEmpty = individualChatData?['lastMessage'] == '';
        bool isLastSenderYou = individualChatData?['lastSender'] == currentUser?.uid;
        final otherUserId =
            participantsData?.firstWhereOrNull((element) => element.id != currentUser?.uid)?.id;

        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection('usersData').doc(otherUserId).snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> otherUserDataSnapshot) {
            if (otherUserDataSnapshot.connectionState == ConnectionState.waiting ||
                otherUserDataSnapshot.connectionState == ConnectionState.none) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final DocumentSnapshot<Object?>? otherUserData = otherUserDataSnapshot.data;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: const BorderSide(
                    color: Colors.teal,
                    width: 2.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                color: Colors.grey[800],
                splashColor: Colors.amber,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => PrivateChatScreen(
                          chatId: individualChatData?.id ?? '', otherUser: otherUserData),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2,
                            color: Colors.amber,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: CircleAvatar(
                          radius: 23,
                          backgroundImage: NetworkImage(
                            otherUserData?['userImageUrl'] ?? '',
                          ),
                        ),
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
                                    otherUserData?['username'] ?? '',
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
