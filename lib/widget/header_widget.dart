import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget header( BuildContext context, String title, VoidCallback onClose ) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClose,
      )
    ],
  );
}