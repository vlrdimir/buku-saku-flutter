import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/reports_service.dart' as reports;
import '../widgets/cards/transaction_card.dart';
import 'transaction_detail_page.dart';

class CategoryDetailsPage extends StatefulWidget {
  final String categoryName;
  final String type;

  const CategoryDetailsPage({
    super.key,
    required this.categoryName,
    required this.type,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  final reports.ReportsService _reportsService = reports.ReportsService();
  final ScrollController _scrollController = ScrollController();
  
  final List<reports.Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _transactions.clear();
    });

    try {
      final result = await _reportsService.getCategoryDetails(
        category: widget.categoryName,
        type: widget.type,
        page: 1,
      );

      setState(() {
        _transactions.addAll(result.transactions);
        _totalPages = result.pagination.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ Failed to load category details: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _reportsService.getCategoryDetails(
        category: widget.categoryName,
        type: widget.type,
        page: nextPage,
      );

      setState(() {
        _transactions.addAll(result.transactions);
        _currentPage = nextPage;
        _totalPages = result.pagination.totalPages;
        _isLoadingMore = false;
      });
    } catch (e) {
      developer.log('❌ Failed to load more category details: $e');
      setState(() {
        _isLoadingMore = false;
      });
      // Show snackbar for pagination error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.type == 'income' 
        ? 'Pemasukan ${widget.categoryName}'
        : 'Pengeluaran ${widget.categoryName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.grey[800],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Terjadi kesalahan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadInitialData(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final transaction = _transactions[index];
          return TransactionCard(
            id: transaction.id,
            description: transaction.description,
            category: transaction.category,
            amount: transaction.amount,
            type: transaction.type,
            date: transaction.date,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailPage(
                    transactionId: transaction.id,
                  ),
                ),
              );
              // Reload data if transaction was updated or deleted (result is true)
              if (result == true) {
                _loadInitialData();
              }
            },
          );
        },
      ),
    );
  }
}
