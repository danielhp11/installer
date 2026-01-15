import 'package:flutter/material.dart';

class SelectorField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

  const SelectorField({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: !isEnabled,
          fillColor: isEnabled ? null : Colors.black.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Seleccionar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: value == null
                      ? Theme.of(context).textTheme.bodySmall?.color
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ],
        ),
      ),
    );
  }
}
