import 'package:flutter/material.dart';

class DescriptionInputField extends StatelessWidget {
  const DescriptionInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.maxLines = 3,
    this.hintText = 'Deskripsi transaksi',
  });

  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
