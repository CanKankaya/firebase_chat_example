import 'package:flutter/material.dart';

class ReplyProvider with ChangeNotifier {
  bool isReply = false;
  String messageId = '';
  String username = '';
  String message = '';

  replyHandler(String id, String name, String mes) {
    isReply = true;
    messageId = id;
    username = name;
    message = mes;
    notifyListeners();
  }

  closeReply() {
    isReply = false;
    messageId = '';
    username = '';
    message = '';
    notifyListeners();
  }
}
