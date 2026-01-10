import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Base URL configuration - Now using centralized ApiConfig
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _tokenKey = ApiConfig.tokenKey;

  // Get stored JWT token
  Future<String?> _getStoredToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Make authenticated API request with JWT token
  Future<http.Response> _makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final String? token = await _getStoredToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } catch (e) {
      developer.log('❌ API request failed: $e');
      throw Exception('API request failed: ${e.toString()}');
    }
  }

  // Get all transactions with pagination and filtering
  Future<TransactionListResponse> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      developer.log('🔄 Fetching transactions: page=$page, limit=$limit');

      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _makeAuthenticatedRequest(
        '/transactions',
        'GET',
        queryParams: queryParams,
      );

      developer.log('📊 Transactions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch transactions',
          );
        }

        final List<Transaction> transactions =
            (responseData['data']['transactions'] as List)
                .map((item) => Transaction.fromJson(item))
                .toList();

        final pagination = Pagination.fromJson(
          responseData['data']['pagination'],
        );

        developer.log('✅ Retrieved ${transactions.length} transactions');
        return TransactionListResponse(
          transactions: transactions,
          pagination: pagination,
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      developer.log('❌ Get transactions error: $e');
      rethrow;
    }
  }

  // Get recent transactions for dashboard (limit 10)
  Future<List<Transaction>> getRecentTransactions() async {
    try {
      developer.log('🔄 Fetching recent transactions');

      final response = await _makeAuthenticatedRequest(
        '/transactions/recent',
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch recent transactions',
          );
        }

        final List<Transaction> transactions =
            (responseData['data']['transactions'] as List)
                .map((item) => Transaction.fromJson(item))
                .toList();

        developer.log('✅ Retrieved ${transactions.length} recent transactions');
        return transactions;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch recent transactions',
        );
      }
    } catch (e) {
      developer.log('❌ Get recent transactions error: $e');
      rethrow;
    }
  }

  // Create a new transaction
  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    try {
      developer.log('🔄 Creating transaction: $type, $amount, $category');

      final response = await _makeAuthenticatedRequest(
        '/transactions',
        'POST',
        body: {
          'type': type,
          'amount': amount,
          'category': category,
          'description': description,
          'date': date,
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to create transaction',
          );
        }

        final transaction = Transaction.fromJson(
          responseData['data']['transaction'],
        );
        developer.log('✅ Transaction created successfully: ${transaction.id}');
        return transaction;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create transaction');
      }
    } catch (e) {
      developer.log('❌ Create transaction error: $e');
      rethrow;
    }
  }

  // Update an existing transaction
  Future<Transaction> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    try {
      developer.log('🔄 Updating transaction: $id');

      final response = await _makeAuthenticatedRequest(
        '/transactions/$id',
        'PUT',
        body: {
          'type': type,
          'amount': amount,
          'category': category,
          'description': description,
          'date': date,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to update transaction',
          );
        }

        final transaction = Transaction.fromJson(
          responseData['data']['transaction'],
        );
        developer.log('✅ Transaction updated successfully: ${transaction.id}');
        return transaction;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update transaction');
      }
    } catch (e) {
      developer.log('❌ Update transaction error: $e');
      rethrow;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      developer.log('🔄 Deleting transaction: $id');

      final response = await _makeAuthenticatedRequest(
        '/transactions/$id',
        'DELETE',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to delete transaction',
          );
        }

        developer.log('✅ Transaction deleted successfully: $id');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete transaction');
      }
    } catch (e) {
      developer.log('❌ Delete transaction error: $e');
      rethrow;
    }
  }

  // Get transaction detail
  Future<Transaction> getTransactionDetail(String id) async {
    try {
      developer.log('🔄 Fetching transaction detail: $id');

      final response = await _makeAuthenticatedRequest(
        '/transactions/$id',
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch transaction detail',
          );
        }

        final transaction = Transaction.fromJson(responseData['data']);
        developer.log(
          '✅ Transaction detail fetched successfully: ${transaction.id}',
        );
        return transaction;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch transaction detail',
        );
      }
    } catch (e) {
      developer.log('❌ Get transaction detail error: $e');
      rethrow;
    }
  }

  // Search transactions with filters
  Future<List<Transaction>> searchTransactions({
    required String query,
    double? minAmount,
    double? maxAmount,
    String? category,
    String? type,
  }) async {
    try {
      developer.log('🔄 Searching transactions: q=$query');

      final Map<String, String> queryParams = {'q': query};
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();
      if (category != null) queryParams['category'] = category;
      if (type != null) queryParams['type'] = type;

      final response = await _makeAuthenticatedRequest(
        '/transactions/search',
        'GET',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to search transactions',
          );
        }

        final List<Transaction> results =
            (responseData['data']['results'] as List)
                .map((item) => Transaction.fromJson(item))
                .toList();

        developer.log('✅ Search returned ${results.length} results');
        return results;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to search transactions',
        );
      }
    } catch (e) {
      developer.log('❌ Search transactions error: $e');
      rethrow;
    }
  }
}

// Data Models
class Transaction {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String description;
  final String date; // YYYY-MM-DD
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      description: json['description'] ?? '',
      date: json['date'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TransactionListResponse {
  final List<Transaction> transactions;
  final Pagination pagination;

  TransactionListResponse({
    required this.transactions,
    required this.pagination,
  });
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      totalItems: json['total_items'],
      itemsPerPage: json['items_per_page'],
    );
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
