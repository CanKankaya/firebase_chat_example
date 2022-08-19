import 'package:flutter/material.dart';

bool spamCheck = false;
spamFunction() async {
  await Future.delayed(
    const Duration(seconds: 2),
  );
  spamCheck = false;
}

void simplerErrorMessage(
  BuildContext context,
  String? errorText,
  String? buttonText,
  Function()? buttonFon,
  bool spamCheckOn,
) {
  if (spamCheckOn) {
    if (spamCheck == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1950),
          action: SnackBarAction(
            onPressed: () {
              buttonFon?.call();
            },
            label: buttonText ?? 'error',
          ),
          content: Text(errorText ?? ''),
        ),
      );
    } else {
      return;
    }
    spamCheck = true;
    spamFunction();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1950),
        action: SnackBarAction(
          onPressed: () {
            buttonFon?.call();
          },
          label: buttonText ?? 'error',
        ),
        content: Text(errorText ?? ''),
      ),
    );
  }
}
