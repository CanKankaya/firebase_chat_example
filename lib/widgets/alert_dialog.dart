import 'package:flutter/material.dart';

Future<void> showMyDialog(
  BuildContext context,
  bool dismissable,
  String errorTitle,
  String errorText,
  String errorText2,
  String buttonText,
  Function() buttonFon,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: dismissable,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(errorTitle),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(errorText),
              Text(errorText2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: buttonFon,
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      );
    },
  );
}
