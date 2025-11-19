import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'components/transaction_type_selector.dart';
import 'components/amount_input_field.dart';
import 'components/description_input_field.dart';
import 'components/date_input_field.dart';
import 'components/category_dropdown.dart';
import 'components/transaction_submit_button.dart';

typedef TransactionSubmitCallback = void Function({
  required String type,
  required double amount,
  required String category,
  required String description,
  required String date,
  bool? submitting,
});

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.onSubmit,
  });

  final TransactionSubmitCallback onSubmit;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  
  String _transactionType = 'income';
  String _selectedCategory = 'Gaji';
  bool _isSubmitting = false;

  void _updateSelectedCategory() {
    switch (_transactionType) {
      case 'income':
        _selectedCategory = 'Gaji';
        break;
      case 'expense':
        _selectedCategory = 'Makanan';
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    
    if (amountText.isEmpty || description.isEmpty || date.isEmpty) {
      return false;
    }
    
    final amount = double.tryParse(amountText);
    return amount != null && amount > 0;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    final amount = double.parse(amountText);
    
    // Convert date format from dd/MM/yyyy to yyyy-MM-dd
    final dateDateTime = DateFormat('dd/MM/yyyy').parse(date);
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateDateTime);

    setState(() {
      _isSubmitting = true;
    });

    try {
      widget.onSubmit(
        type: _transactionType,
        amount: amount,
        category: _selectedCategory,
        description: description,
        date: formattedDate,
        submitting: _isSubmitting,
      );
      _clearForm();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    setState(() {
      _transactionType = 'income';
    });
    _updateSelectedCategory();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Type selector
        TransactionTypeSelector(
          selectedType: _transactionType,
          onTypeChanged: (type) {
            setState(() {
              _transactionType = type;
              _updateSelectedCategory();
            });
          },
        ),

        const SizedBox(height: 24),

        // Amount field
        const Text(
          'Jumlah',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AmountInputField(
          controller: _amountController,
          enabled: !_isSubmitting,
        ),

        const SizedBox(height: 16),

        // Description field
        const Text(
          'Deskripsi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DescriptionInputField(
          controller: _descriptionController,
          enabled: !_isSubmitting,
          hintText: 'Deskripsi transaksi',
        ),

        const SizedBox(height: 16),

        // Date field
        const Text(
          'Tanggal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DateInputField(
          controller: _dateController,
          enabled: !_isSubmitting,
        ),

        const SizedBox(height: 16),

        // Category field
        const Text(
          'Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CategoryDropdown(
          transactionType: _transactionType,
          selectedCategory: _selectedCategory,
          onChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
          enabled: !_isSubmitting,
        ),

        const SizedBox(height: 32),

        // Submit button
        TransactionSubmitButton(
          isLoading: _isSubmitting,
          transactionType: _transactionType,
          onPressed: _isSubmitting ? null : () => _handleSubmit(),
        ),
      ],
    );
  }

  
}
