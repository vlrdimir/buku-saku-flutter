import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.transactionType,
    required this.selectedCategory,
    required this.onChanged,
    this.enabled = true,
  });

  final String transactionType;
  final String selectedCategory;
  final Function(String) onChanged;
  final bool enabled;

  static const List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
    'Hadiah',
    'Lainnya',
  ];

  static const List<String> _expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
  ];

  List<String> get _categories {
    switch (transactionType) {
      case 'income':
        return _incomeCategories.toList();
      case 'expense':
        return _expenseCategories.toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _categories.contains(selectedCategory) ? selectedCategory : null,
      hint: const Text('Pilih kategori'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: enabled ? (value) {
        if (value != null) {
          onChanged(value);
        }
      } : null,
    );
  }
}
