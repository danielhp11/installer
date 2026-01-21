import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget card({required Widget child}) {
  return Card(
    elevation: 1.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}