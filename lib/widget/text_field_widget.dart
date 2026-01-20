import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget textFieldOnlyRead({
  required String label,
  required IconData icon,
  required String value,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return TextFormField(
    controller: TextEditingController(text: value),
    readOnly: readOnly,
    onTap: onTap,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
    validator: (v) {
      if (!readOnly && (v == null || v.isEmpty)) {
        return 'Campo requerido';
      }
      return null;
    },
  );
}

Widget textField(
    TextEditingController c, String label, IconData icon) {
  return TextFormField(
    controller: c,
    keyboardType: TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Campo requerido';
      return null;
    },
  );
}

TextStyle defaultStyleText = TextStyle(
  fontSize: 12,
  color: Colors.grey.shade600,
  fontWeight: FontWeight.w500,
);

Widget infoText({
  String text = "",
  TextStyle? styles,
}) {
  return Text(
    text,
    style: styles ?? defaultStyleText,
  );
}
