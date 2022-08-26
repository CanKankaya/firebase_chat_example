import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/providers/reply_provider.dart';

import 'package:firebase_chat_example/widgets/alert_dialog.dart';

import 'package:firebase_chat_example/screens/other_user/other_userdata_screen.dart';
import 'package:firebase_chat_example/screens/chat/public_chat_participants_screen.dart';

class PublicChatScreen extends StatelessWidget {
  PublicChatScreen({super.key, required this.chatId});

  final String chatId;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    DocumentSnapshot<Object?>? chatData;

    Future _getAndSetChatData() async {
      chatData = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    }

    if (chatId == '') {
      return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: const [
            Center(
              child: Text('Chat Id is empty for some reason'),
            ),
          ],
        ),
      );
    } else {
      return FutureBuilder(
        future: _getAndSetChatData(),
        builder: (context, chatSnapshot) {
          return StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('chats/$chatId/participantsData').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> participantsSnapshot) {
              if (participantsSnapshot.connectionState == ConnectionState.waiting ||
                  participantsSnapshot.connectionState == ConnectionState.none) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                final participantsData = participantsSnapshot.data?.docs;
                final foundUser = participantsData?.firstWhereOrNull(
                  (element) => element.id == currentUser?.uid,
                );
                if (foundUser == null) {
                  return Scaffold(
                    appBar: AppBar(),
                    body: const Center(
                      child:
                          Text('Something Went Wrong, \n You May Have Been Removed From Chat :('),
                    ),
                  );
                } else {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: WillPopScope(
                      onWillPop: () {
                        Provider.of<ReplyProvider>(context, listen: false).closeReply();
                        return Future.value(true);
                      },
                      child: Scaffold(
                        appBar: AppBar(
                          actions: [
                            IconButton(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PublicChatParticipantsScreen(
                                      creatorId: chatData?['chatCreatorId'],
                                      chatId: chatId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.manage_accounts),
                            ),
                          ],
                        ),
                        body: Column(
                          children: [
                            Messages(chatId: chatId, participantsData: participantsData),
                            const ReplyWidget(),
                            NewMessage(chatId: chatId),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    }
  }
}

class Messages extends StatelessWidget {
  final String chatId;
  final List<QueryDocumentSnapshot<Object?>>? participantsData;
  final ValueNotifier<int> _itemCount = ValueNotifier<int>(10);
  Messages({super.key, required this.chatId, this.participantsData});

  _refreshFunction() async {
    _itemCount.value += 10;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    List<QueryDocumentSnapshot<Object?>>? usersData;

    final scrollController = ScrollController();
    Future _getAndSetUserData() async {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('usersData').get();
      usersData = userSnapshot.docs;
    }

    return Expanded(
      child: FutureBuilder(
        future: _getAndSetUserData(),
        builder: (context, usersSnapshot) {
          {
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats/$chatId/messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> messagesSnapshot) {
                if (messagesSnapshot.connectionState == ConnectionState.waiting ||
                    usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                //** Firebase dependant logic here;
                final documents = messagesSnapshot.data?.docs;
                //**

                return RefreshIndicator(
                  onRefresh: () async {
                    if ((documents?.length ?? 0) > _itemCount.value) {
                      await _refreshFunction().then(
                        (_) {
                          SchedulerBinding.instance.addPostFrameCallback(
                            (_) {
                              scrollController.animateTo(
                                scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.linear,
                              );
                            },
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You are already seeing all messages'),
                        ),
                      );
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: _itemCount,
                    builder: (_, int itemCountValue, __) {
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        reverse: true,
                        itemCount: (documents?.length ?? 0) > itemCountValue
                            ? itemCountValue
                            : (documents?.length ?? 0),
                        itemBuilder: (context, index) {
                          //** Index dependant logic here */
                          final currentMessage = documents?[index];
                          bool isMe = currentMessage?['userId'] == currentUser?.uid;
                          bool isMeAbove = false;
                          if (index + 1 < (documents?.length ?? 0)) {
                            isMeAbove =
                                currentMessage?['userId'] == documents?[index + 1]['userId'];
                          } else {
                            isMeAbove = false;
                          }
                          final whichUser = usersData?.firstWhere(
                            (element) => element.id == currentMessage?['userId'],
                          );
                          final foundUser = participantsData?.firstWhereOrNull(
                            (element) => element.id == whichUser?['userId'],
                          );
                          bool doesUserBelong = foundUser == null ? false : true;
                          DateTime dt = (currentMessage?['createdAt'] as Timestamp).toDate();
                          String formattedDate = dt.day == DateTime.now().day
                              ? DateFormat.Hm().format(dt)
                              : DateFormat.yMMMMd().format(dt);
                          //** */

                          //** Reply dependant logic here */
                          final isReply = currentMessage?['repliedTo'] != '';
                          QueryDocumentSnapshot<Object?>? repliedToMessage;
                          QueryDocumentSnapshot<Object?>? repliedToUser;

                          if (isReply) {
                            repliedToMessage = documents?.firstWhereOrNull(
                              (QueryDocumentSnapshot<Object?>? element) =>
                                  element?.id == currentMessage?['repliedTo'],
                            );
                            if (repliedToMessage != null) {
                              repliedToUser = usersData?.firstWhereOrNull(
                                (element) => element.id == repliedToMessage?['userId'],
                              );
                            }
                          }
                          final isReplyToCurrentUser = currentUser?.uid == repliedToUser?['userId'];
                          final isReplyToSelf = currentMessage?['userId'] == currentUser?.uid;
                          //** */
                          return MessageWidget(
                            chatId: chatId,
                            isMe: isMe,
                            isMeAbove: isMeAbove,
                            whichUser: whichUser,
                            formattedDate: formattedDate,
                            currentMessage: currentMessage,
                            doesUserBelong: doesUserBelong,
                            isReply: isReply,
                            repliedToMessage: repliedToMessage,
                            repliedToUser: repliedToUser,
                            isReplyToCurrentUser: isReplyToCurrentUser,
                            isReplyToSelf: isReplyToSelf,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    Key? key,
    required this.chatId,
    this.currentMessage,
    this.whichUser,
    required this.isMe,
    required this.isMeAbove,
    required this.formattedDate,
    required this.isReply,
    this.repliedToMessage,
    this.repliedToUser,
    required this.isReplyToCurrentUser,
    required this.isReplyToSelf,
    required this.doesUserBelong,
  }) : super(key: key);
  final String chatId;

  final QueryDocumentSnapshot<Object?>? currentMessage;
  final QueryDocumentSnapshot<Object?>? whichUser;
  final bool isMe;
  final bool isMeAbove;
  final bool doesUserBelong;
  final String formattedDate;

  //** reply dependant login here */
  final bool isReply;
  final QueryDocumentSnapshot<Object?>? repliedToMessage;
  final QueryDocumentSnapshot<Object?>? repliedToUser;
  final bool isReplyToCurrentUser;
  final bool isReplyToSelf;
  //** */

  Future<void> _deleteMessage(messageId) async {
    await FirebaseFirestore.instance.collection('chats/$chatId/messages').doc(messageId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    Offset tapPosition = const Offset(0.0, 0.0);

    return Dismissible(
      key: ValueKey(currentMessage?.id),
      background: Container(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: const [
              Icon(Icons.reply),
              SizedBox(width: 5),
              Text(
                'Reply',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
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
      direction: isMe ? DismissDirection.horizontal : DismissDirection.startToEnd,
      onDismissed: (direction) {},
      confirmDismiss: (DismissDirection dismissDirection) async {
        switch (dismissDirection) {
          case DismissDirection.startToEnd:
            {
              Provider.of<ReplyProvider>(context, listen: false).replyHandler(
                currentMessage?.id ?? '',
                whichUser?['username'] ?? '',
                currentMessage?['text'] ?? '',
              );
              break;
            }
          case DismissDirection.endToStart:
            {
              _deleteMessage(currentMessage?.id);
              break;
            }
          default:
            break;
        }
        return false;
      },
      child: InkWell(
        onTapDown: (details) {
          tapPosition = details.globalPosition;
        },
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        splashColor: Colors.amber,
        onLongPress: () {
          FocusManager.instance.primaryFocus?.unfocus();
          showMenu(
            context: context,
            position: RelativeRect.fromRect(
              tapPosition & const Size(40, 40),
              Offset.zero & const Size(40, 40),
            ),
            items: <PopupMenuEntry>[
              PopupMenuItem(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: currentMessage?['text'] ?? '',
                    ),
                  ).then((_) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                      ),
                    );
                  });
                },
                child: Row(
                  children: const [
                    Text('Copy'),
                    SizedBox(width: 10),
                    Icon(Icons.copy),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  SchedulerBinding.instance.addPostFrameCallback(
                    (_) {
                      showMyDialog(
                        context,
                        true,
                        'Message Detail \n ',
                        'Sent by \'${whichUser?['username'] ?? ''}\'',
                        formattedDate,
                        'ok',
                        Navigator.of(context).pop,
                      );
                    },
                  );
                },
                child: Row(
                  children: const [
                    Text('Details'),
                    SizedBox(width: 10),
                    Icon(Icons.info_outline),
                  ],
                ),
              ),
            ],
          );
        },
        child: Column(
          children: [
            if (isReply)
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: deviceSize.width * 0.65,
                  ),
                  margin: const EdgeInsets.only(
                    top: 16,
                    right: 8,
                    left: 8,
                    bottom: 4,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isMe ? Colors.grey[500] : Colors.grey[700],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ',
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.black : Colors.white,
                            ),
                          ),
                          Text(
                            isReplyToCurrentUser
                                ? isReplyToSelf
                                    ? 'Yourself'
                                    : 'You'
                                : repliedToUser?['username'] ?? '\'unknown user\'',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repliedToMessage?['text'] ?? '\'this message is deleted \'',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              key: ValueKey(currentMessage?.id),
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        //**Added invisible boxes for Stack hittest bug*/
                        //**See:https://github.com/flutter/flutter/issues/19445 */
                        if (isMe) const SizedBox(width: 20),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: deviceSize.width * 0.65,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: Colors.amber,
                            ),
                            color: isMe ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft:
                                  isMe ? const Radius.circular(15) : const Radius.circular(0),
                              bottomRight:
                                  isMe ? const Radius.circular(0) : const Radius.circular(15),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          margin: EdgeInsets.only(
                            top: !isMeAbove && !isReply ? 32 : 2,
                            bottom: 2,
                            left: 8,
                            right: 8,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe && !isMeAbove)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      whichUser?['username'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    if (!doesUserBelong)
                                      const Text(
                                        ('(Removed User)'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromARGB(255, 195, 195, 195),
                                        ),
                                      ),
                                  ],
                                ),
                              if (!isMe && !isMeAbove) const SizedBox(height: 5),
                              Text(
                                currentMessage?['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe ? Colors.black : Colors.white,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                // This allocates space for the formattedDate, however the formattedDate is placed later with the Stack, look below
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.transparent,
                                ),
                                textAlign: isMe ? TextAlign.end : TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                        //**Other invisible box for hittest bug */
                        if (!isMe) const SizedBox(width: 20),
                      ],
                    ),
                    PositionedDirectional(
                      bottom: 11,
                      end: isMe ? 18 : 38,
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? const Color.fromARGB(255, 60, 60, 60)
                              : const Color.fromARGB(255, 195, 195, 195),
                        ),
                        textAlign: isMe ? TextAlign.end : TextAlign.start,
                      ),
                    ),
                    if (!isMeAbove)
                      PositionedDirectional(
                        top: isReply ? -12 : 18,
                        start: isMe ? 0 : null,
                        end: isMe ? null : 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!isMe) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserDataScreen(user: whichUser),
                                ),
                              );
                            }
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
                                whichUser?['userImageUrl'] ?? '',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReplyWidget extends StatelessWidget {
  const ReplyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Consumer<ReplyProvider>(
      builder: (_, providerValue, __) {
        bool isReplyToSelf = providerValue.username == currentUser?.displayName;

        if (providerValue.isReply) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Replying to ',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isReplyToSelf ? 'Yourself' : providerValue.username,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          providerValue.closeReply();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    providerValue.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class NewMessage extends StatelessWidget {
  final String chatId;
  final ValueNotifier<String> _enteredMessage = ValueNotifier<String>('');

  final _controller = TextEditingController();

  NewMessage({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    void _sendMessage() async {
      final textToSendId = Provider.of<ReplyProvider>(context, listen: false).messageId;
      final textToSend = _enteredMessage.value;
      _enteredMessage.value = '';
      _controller.clear();
      final currentUser = FirebaseAuth.instance.currentUser;
      Provider.of<ReplyProvider>(context, listen: false).closeReply();

      await FirebaseFirestore.instance.collection('chats/$chatId/messages').add({
        'text': textToSend,
        'createdAt': Timestamp.now(),
        'userId': currentUser?.uid ?? '',
        'repliedTo': textToSendId,
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastUpdated': DateTime.now(),
        'lastMessage': textToSend,
        'lastSender': currentUser?.displayName,
      });
    }

    final deviceOrientation = MediaQuery.of(context).orientation;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        height: deviceOrientation == Orientation.portrait ? 90 : 65,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Theme(
                    data: ThemeData.dark(),
                    child: TextField(
                      maxLines: 5,
                      minLines: 1,
                      maxLength: 200,
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
          ],
        ),
      ),
    );
  }
}
