import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  // Base URL configuration - Using centralized ApiConfig
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

  // Create a new budget
  Future<Budget> createBudget({
    required String category,
    required double amount,
    required String period,
    required String startDate,
  }) async {
    try {
      developer.log('🔄 Creating budget: $category, $amount, $period');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.budgets,
        'POST',
        body: {
          'category': category,
          'amount': amount,
          'period': period,
          'start_date': startDate,
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to create budget');
        }

        final budget = Budget.fromJson(responseData['data']['budget']);
        developer.log('✅ Budget created successfully: ${budget.id}');
        return budget;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create budget');
      }
    } catch (e) {
      developer.log('❌ Create budget error: $e');
      rethrow;
    }
  }

  // Get all budgets
  Future<List<Budget>> getBudgets() async {
    try {
      developer.log('🔄 Fetching all budgets');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.budgets,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch budgets');
        }

        final List<Budget> budgets = (responseData['data']['budgets'] as List)
            .map((item) => Budget.fromJson(item))
            .toList();

        developer.log('✅ Retrieved ${budgets.length} budgets');
        return budgets;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch budgets');
      }
    } catch (e) {
      developer.log('❌ Get budgets error: $e');
      rethrow;
    }
  }

  // Update a budget
  Future<Budget> updateBudget({
    required String id,
    double? amount,
    String? category,
    String? period,
    String? startDate,
  }) async {
    try {
      developer.log('🔄 Updating budget: $id');

      final Map<String, dynamic> body = {};
      if (amount != null) body['amount'] = amount;
      if (category != null) body['category'] = category;
      if (period != null) body['period'] = period;
      if (startDate != null) body['start_date'] = startDate;

      final response = await _makeAuthenticatedRequest(
        '${ApiConfig.budgets}/$id',
        'PUT',
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to update budget');
        }

        final budget = Budget.fromJson(responseData['data']['budget']);
        developer.log('✅ Budget updated successfully: ${budget.id}');
        return budget;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update budget');
      }
    } catch (e) {
      developer.log('❌ Update budget error: $e');
      rethrow;
    }
  }

  // Delete a budget
  Future<bool> deleteBudget(String id) async {
    try {
      developer.log('🔄 Deleting budget: $id');

      final response = await _makeAuthenticatedRequest(
        '${ApiConfig.budgets}/$id',
        'DELETE',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to delete budget');
        }

        developer.log('✅ Budget deleted successfully: $id');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete budget');
      }
    } catch (e) {
      developer.log('❌ Delete budget error: $e');
      rethrow;
    }
  }

  // Get budget alerts
  Future<List<BudgetAlert>> getBudgetAlerts() async {
    try {
      developer.log('🔄 Fetching budget alerts');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.budgetAlerts,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch budget alerts',
          );
        }

        final List<BudgetAlert> alerts =
            (responseData['data']['alerts'] as List)
                .map((item) => BudgetAlert.fromJson(item))
                .toList();

        developer.log('✅ Retrieved ${alerts.length} budget alerts');
        return alerts;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch budget alerts',
        );
      }
    } catch (e) {
      developer.log('❌ Get budget alerts error: $e');
      rethrow;
    }
  }
}

// Data Models
class Budget {
  final String id;
  final String category;
  final double amount;
  final double spent;
  final double remaining;
  final String period; // 'monthly' | 'yearly'
  final double progressPercentage;
  final String startDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.spent,
    required this.remaining,
    required this.period,
    required this.progressPercentage,
    required this.startDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining:
          (json['remaining'] as num?)?.toDouble() ??
          (json['amount'] as num).toDouble() -
              ((json['spent'] as num?)?.toDouble() ?? 0.0),
      period: json['period'] ?? 'monthly',
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'spent': spent,
      'remaining': remaining,
      'period': period,
      'progress_percentage': progressPercentage,
      'start_date': startDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    double? spent,
    double? remaining,
    String? period,
    double? progressPercentage,
    String? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      period: period ?? this.period,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetAlert {
  final String budgetId;
  final String category;
  final String threshold; // '80%', '100%', '120%'
  final String message;
  final double currentSpent;
  final double limit;

  BudgetAlert({
    required this.budgetId,
    required this.category,
    required this.threshold,
    required this.message,
    required this.currentSpent,
    required this.limit,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    return BudgetAlert(
      budgetId: json['budget_id'],
      category: json['category'],
      threshold: json['threshold'],
      message: json['message'],
      currentSpent: (json['current_spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget_id': budgetId,
      'category': category,
      'threshold': threshold,
      'message': message,
      'current_spent': currentSpent,
      'limit': limit,
    };
  }

  // Get threshold percentage as int
  int get thresholdPercentage {
    return int.tryParse(threshold.replaceAll('%', '')) ?? 0;
  }
}
