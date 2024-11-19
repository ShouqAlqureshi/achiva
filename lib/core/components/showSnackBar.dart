import 'package:flutter/material.dart';

void showSnackBarWidget(
    {int? seconds,
    required String message,
    required bool successOrNot,
    required BuildContext context}) {
  SnackBar snackBarItem() => SnackBar(
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(12), topLeft: Radius.circular(12))),
        duration: Duration(seconds: seconds ?? 2),
        padding: const EdgeInsets.all(12),
        content: Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(message,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        backgroundColor: successOrNot ? Colors.green : Colors.red,
      );
  ScaffoldMessenger.of(context).showSnackBar(snackBarItem());
}
