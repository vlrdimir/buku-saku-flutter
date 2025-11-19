import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatelessWidget {
  const DateInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.initialDate,
  });

  final TextEditingController controller;
  final bool enabled;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? () => _selectDate(context) : null,
      decoration: InputDecoration(
        hintText: 'Pilih tanggal',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        suffixIcon: Icon(
          Icons.calendar_today,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 0)),
    );

    if (selected != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(selected);
    }
  }
}
