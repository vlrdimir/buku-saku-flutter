import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

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

  // Get dashboard summary (total balance, income, expense)
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      developer.log('🔄 Fetching dashboard summary');

      final response = await _makeAuthenticatedRequest(
        '/dashboard/summary',
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch dashboard summary',
          );
        }

        final summary = DashboardSummary.fromJson(
          responseData['data']['summary'],
        );
        developer.log('✅ Dashboard summary fetched successfully');
        return summary;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch dashboard summary',
        );
      }
    } catch (e) {
      developer.log('❌ Get dashboard summary error: $e');
      rethrow;
    }
  }

  // Get chart data for dashboard (7-day, 30-day, 90-day views)
  Future<List<ChartDataPoint>> getChartData({String period = '7days'}) async {
    try {
      developer.log('🔄 Fetching chart data for period: $period');

      final response = await _makeAuthenticatedRequest(
        '/dashboard/chart',
        'GET',
        queryParams: {'period': period},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch chart data',
          );
        }

        final List<ChartDataPoint> chartData =
            (responseData['data']['chart_data'] as List)
                .map((item) => ChartDataPoint.fromJson(item))
                .toList();

        developer.log(
          '✅ Chart data fetched successfully: ${chartData.length} points',
        );
        return chartData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch chart data');
      }
    } catch (e) {
      developer.log('❌ Get chart data error: $e');
      rethrow;
    }
  }

  // Get recent transactions for dashboard widget
  Future<List<Transaction>> getRecentTransactions() async {
    try {
      developer.log('🔄 Fetching recent transactions for dashboard');

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

        developer.log(
          '✅ Recent transactions fetched: ${transactions.length} items',
        );
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
}

// Data Models
class DashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final SummaryPeriod period;

  DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.period,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalBalance: (json['total_balance'] as num).toDouble(),
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      period: SummaryPeriod.fromJson(json['period']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_balance': totalBalance,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'period': period.toJson(),
    };
  }

  double get savingsRate =>
      totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome * 100 : 0;
  double get expenseRate =>
      totalIncome > 0 ? totalExpense / totalIncome * 100 : 0;
}

class SummaryPeriod {
  final String startDate;
  final String endDate;

  SummaryPeriod({required this.startDate, required this.endDate});

  factory SummaryPeriod.fromJson(Map<String, dynamic> json) {
    return SummaryPeriod(
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'start_date': startDate, 'end_date': endDate};
  }
}

class ChartDataPoint {
  final String date;
  final String dayName;
  final double income;
  final double expense;

  ChartDataPoint({
    required this.date,
    required this.dayName,
    required this.income,
    required this.expense,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'],
      dayName: json['day_name'],
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'income': income,
      'expense': expense,
    };
  }

  double get net => income - expense;
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String description;
  final String date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
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
    };
  }
}
