import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../services/transaction_service.dart' as transaction_service;

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final transaction_service.TransactionService _transactionService =
      transaction_service.TransactionService();

  bool _isLoading = true;
  String? _errorMessage;
  transaction_service.Transaction? _transaction;

  // Form controllers for editing
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  String _selectedCategory = '';
  String _selectedType = 'expense';
  bool _isEditing = false;
  bool _isSaving = false;

  // Temporary categories list (should ideally come from a service or constants)
  final List<String> _categories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Gaji',
    'Bonus',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _transactionService.getTransactionDetail(widget.transactionId);
      
      setState(() {
        _transaction = transaction;
        _isLoading = false;
        // Initialize form with data
        _amountController.text = transaction.amount.toInt().toString();
        _descriptionController.text = transaction.description;
        _dateController.text = transaction.date;
        _selectedCategory = transaction.category;
        _selectedType = transaction.type;
      });
    } catch (e) {
      developer.log('❌ Failed to load transaction detail: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_dateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _transactionService.updateTransaction(
        id: widget.transactionId,
        type: _selectedType,
        amount: double.parse(_amountController.text.replaceAll('.', '')),
        category: _selectedCategory,
        description: _descriptionController.text,
        date: _dateController.text,
      );

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      
      // Refresh data
      _loadTransactionDetail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil diperbarui')),
        );
      }
    } catch (e) {
      developer.log('❌ Failed to update transaction: $e');
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui transaksi: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _transactionService.deleteTransaction(widget.transactionId);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dihapus')),
          );
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus transaksi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.grey[800],
        actions: [
          if (!_isLoading && _transaction != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isLoading && _transaction != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransactionDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing ? _buildEditForm() : _buildDetailView(),
                ),
    );
  }

  Widget _buildDetailView() {
    if (_transaction == null) return const SizedBox.shrink();

    final color = _transaction!.type == 'income' ? Colors.green : Colors.red;
    final icon = _transaction!.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(_transaction!.amount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _transaction!.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        _buildDetailRow('Kategori', _transaction!.category, Icons.category),
        const SizedBox(height: 24),
        _buildDetailRow('Deskripsi', _transaction!.description, Icons.description),
        const SizedBox(height: 24),
        _buildDetailRow(
          'Tanggal',
          _formatDate(_transaction!.date),
          Icons.calendar_today,
        ),
        const SizedBox(height: 24),
        _buildDetailRow(
          'Dibuat Pada',
          DateFormat('dd MMM yyyy, HH:mm').format(_transaction!.createdAt),
          Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah (Rp)',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jumlah tidak boleh kosong';
              }
              if (double.tryParse(value.replaceAll('.', '')) == null) {
                return 'Format jumlah tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipe Transaksi',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
              DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _categories.contains(_selectedCategory) ? _selectedCategory : null,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih kategori';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Date Field
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _selectDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih tanggal';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                            // Reset form values
                            if (_transaction != null) {
                              _amountController.text =
                                  _transaction!.amount.toInt().toString();
                              _descriptionController.text =
                                  _transaction!.description;
                              _dateController.text = _transaction!.date;
                              _selectedCategory = _transaction!.category;
                              _selectedType = _transaction!.type;
                            }
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }
}
