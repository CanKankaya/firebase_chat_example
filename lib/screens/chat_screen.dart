import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/providers/reply_provider.dart';

import 'package:firebase_chat_example/widgets/alert_dialog.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/other_userdata_screen.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    if (chatId == '') {
      return WillPopScope(
        onWillPop: () => showExitPopup(context),
        child: Scaffold(
          appBar: AppBar(),
          body: Column(
            children: const [
              Text('Chat Id is empty for some reason'),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(),
          body: Column(
            children: [
              Messages(chatId: chatId),
              const ReplyWidget(),
              NewMessage(chatId: chatId),
            ],
          ),
        ),
      );
    }
  }
}

class ReplyWidget extends StatelessWidget {
  const ReplyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReplyProvider>(
      builder: (_, providerValue, __) {
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
                        'Replying to \'',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        providerValue.username,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                        ),
                      ),
                      const Text('\''),
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
    final provData = Provider.of<ReplyProvider>(context, listen: true);
    void _sendMessage() async {
      final auth = FirebaseAuth.instance;
      await FirebaseFirestore.instance.collection('chats/$chatId/messages').add({
        'text': _enteredMessage.value,
        'createdAt': Timestamp.now(),
        'userId': auth.currentUser?.uid,
        'repliedTo': provData.messageId,
      });
      provData.closeReply();
      _controller.clear();
      _enteredMessage.value = '';
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

class Messages extends StatelessWidget {
  final String chatId;

  final ValueNotifier<int> _itemCount = ValueNotifier<int>(10);

  Messages({super.key, required this.chatId});

  _deleteMessage(messageId) async {
    await FirebaseFirestore.instance.collection('chats/$chatId/messages').doc(messageId).delete();
  }

  _refreshFunction() async {
    _itemCount.value += 10;
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final scrollController = ScrollController();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats/$chatId/messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> messagesSnapshot) {
          {
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats/$chatId/participantsData')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> usersSnapshot) {
                if (usersSnapshot.connectionState == ConnectionState.waiting ||
                    messagesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                //** Firebase dependant logic here;
                final documents = messagesSnapshot.data?.docs;
                final participantsData = usersSnapshot.data?.docs;
                // **

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
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                          //**  index dependant logic here;
                          final currentMessage = documents?[index];
                          bool isMe = currentMessage?['userId'] == currentUser?.uid;
                          bool isMeAbove = false;
                          if (index + 1 < (documents?.length ?? 0)) {
                            isMeAbove =
                                currentMessage?['userId'] == documents?[index + 1]['userId'];
                          } else {
                            isMeAbove = false;
                          }
                          final whichParticipant = participantsData?.firstWhere(
                            (element) {
                              return element['userId'] == currentMessage?['userId'];
                            },
                          );
                          DateTime dt = (currentMessage?['createdAt'] as Timestamp).toDate();
                          final isToday = dt.day == DateTime.now().day;
                          String formattedDate =
                              isToday ? DateFormat.Hm().format(dt) : DateFormat.yMMMMd().format(dt);
                          Offset tapPosition = const Offset(0.0, 0.0);
                          //**

                          //** Reply dependant logic here;
                          final isReply = currentMessage?['repliedTo'] == '' ? false : true;
                          QueryDocumentSnapshot<Object?>? repliedToMessage;
                          QueryDocumentSnapshot<Object?>? repliedToUser;
                          if (isReply) {
                            repliedToMessage = documents?.firstWhere((element) {
                              return element.id == currentMessage?['repliedTo'];
                            });
                            repliedToUser = participantsData?.firstWhere((element) {
                              return element['userId'] == repliedToMessage?['userId'];
                            });
                          }
                          final isReplyToCurrentUser =
                              currentUser?.displayName == repliedToUser?['username'];
                          //**

                          return Column(
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
                                                  ? 'You'
                                                  : repliedToUser?['username'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          repliedToMessage?['text'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isMe ? Colors.black : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Dismissible(
                                key: ValueKey(currentMessage?.id),
                                background: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.green,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Reply',
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
                                direction: isMe
                                    ? DismissDirection.endToStart
                                    : DismissDirection.startToEnd,
                                onDismissed: (direction) {},
                                confirmDismiss: (DismissDirection dismissDirection) async {
                                  switch (dismissDirection) {
                                    case DismissDirection.startToEnd:
                                      {
                                        Provider.of<ReplyProvider>(context, listen: false)
                                            .replyHandler(
                                          currentMessage?.id ?? '',
                                          whichParticipant?['username'],
                                          currentMessage?['text'],
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
                                                text: currentMessage?['text'],
                                              ),
                                            ).then((_) {
                                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                                                  'Message Detail',
                                                  'Sent by \'${whichParticipant?['username']}\'',
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
                                  child: Row(
                                    key: ValueKey(currentMessage?.id),
                                    mainAxisAlignment:
                                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
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
                                                bottomLeft: isMe
                                                    ? const Radius.circular(15)
                                                    : const Radius.circular(0),
                                                bottomRight: isMe
                                                    ? const Radius.circular(0)
                                                    : const Radius.circular(15),
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
                                              crossAxisAlignment: isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                if (!isMe && !isMeAbove)
                                                  Text(
                                                    whichParticipant?['username'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isMe ? Colors.black : Colors.amber,
                                                    ),
                                                  ),
                                                if (!isMe) const SizedBox(height: 5),
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
                                          PositionedDirectional(
                                            bottom: 11,
                                            end: 18,
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
                                              start: isMe ? -20 : null,
                                              end: isMe ? null : -20,
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
