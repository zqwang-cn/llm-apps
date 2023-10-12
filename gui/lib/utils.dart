import 'package:flutter/material.dart';

void showMsg(context, msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating, width: 500.0),
  );
}

void startLoading(context) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      });
}

void stopLoading(context) {
  Navigator.of(context).pop();
}
