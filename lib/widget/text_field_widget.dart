import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Widget textFieldOnlyRead({
//   required String label,
//   required IconData icon,
//   String? value = null,
//   bool readOnly = false,
//   VoidCallback? onTap,
// }) {
//   return InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(4), // Matches default border radius
//     child: InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: const OutlineInputBorder(),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjust vertical padding to match TextField height
//         isDense: true,
//       ),
//       child: value == null? const SizedBox():
//       Text(
//         value.isEmpty ? ' ' : value, // Empty space ensures height is maintained if value is empty
//         style: TextStyle(
//           fontSize: 16, // Standard TextField font size
//           color: Colors.black87,
//         ),
//       ),
//     ),
//   );
// }

Widget textFieldOnlyRead({
  required String label,
  required IconData icon,
  String? value,
  VoidCallback? onTap,
  Widget? child = null,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              /// Icon
              Icon(
                icon,
                size: 20,
                color: Colors.blueGrey,
              ),

              const SizedBox(width: 10),

              /// Label
              Text(
                "$label:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),


          const SizedBox(width: 8),

          /// Value
          value == null || value.isEmpty ? const SizedBox(width: 8)
          : Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          (child ?? const SizedBox()),

        ]
      ),
    ),
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
  TextAlign textAlign = TextAlign.center,
}) {
  return Text(
    text,
    textAlign: textAlign,
    style: styles ?? defaultStyleText,
  );
}
