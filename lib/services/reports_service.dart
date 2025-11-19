import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  // Base URL configuration
  static const String _baseUrl = 'http://localhost:8082/v1';
  static const String _tokenKey = 'jwt_token';

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

  // Get reports summary by period (today, week, month, year)
  Future<ReportsSummary> getReportsSummary({required String period}) async {
    try {
      developer.log('🔄 Fetching reports summary for period: $period');

      final response = await _makeAuthenticatedRequest(
        '/reports/summary',
        'GET',
        queryParams: {'period': period},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch reports summary');
        }

        final summary = ReportsSummary.fromJson(responseData['data']['summary']);
        developer.log('✅ Reports summary fetched successfully');
        return summary;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch reports summary');
      }
    } catch (e) {
      developer.log('❌ Get reports summary error: $e');
      rethrow;
    }
  }

  // Get category breakdown by period
  Future<CategoryBreakdown> getCategoryBreakdown({
    required String period,
    String type = 'expense',
  }) async {
    try {
      developer.log('🔄 Fetching category breakdown: period=$period, type=$type');

      final response = await _makeAuthenticatedRequest(
        '/reports/categories',
        'GET',
        queryParams: {
          'period': period,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch category breakdown');
        }

        final breakdown = CategoryBreakdown.fromJson(responseData['data']);
        developer.log('✅ Category breakdown fetched successfully');
        return breakdown;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch category breakdown');
      }
    } catch (e) {
      developer.log('❌ Get category breakdown error: $e');
      rethrow;
    }
  }

  // Get chart data for reports (pie, line, bar charts)
  Future<List<ChartItem>> getReportsChartData({
    required String period,
    required String chartType,
  }) async {
    try {
      developer.log('🔄 Fetching reports chart data: period=$period, chart_type=$chartType');

      final response = await _makeAuthenticatedRequest(
        '/reports/charts',
        'GET',
        queryParams: {
          'period': period,
          'chart_type': chartType,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch chart data');
        }

        // Handle null chart_data safely
        if (responseData['data']['chart_data'] == null) {
          developer.log('⚠️ Reports chart data is null');
          return [];
        }

        final List<ChartItem> chartData = (responseData['data']['chart_data'] as List)
            .map((item) => ChartItem.fromJson(item))
            .toList();

        developer.log('✅ Reports chart data fetched successfully: ${chartData.length} items');
        return chartData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch chart data');
      }
    } catch (e) {
      developer.log('❌ Get reports chart data error: $e');
      rethrow;
    }
  }
  // Get details for a specific category
  Future<CategoryDetailsResponse> getCategoryDetails({
    required String category,
    required String type,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      developer.log('🔄 Fetching category details: category=$category, type=$type, page=$page');

      final response = await _makeAuthenticatedRequest(
        '/reports/category-details',
        'GET',
        queryParams: {
          'category': category,
          'type': type,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch category details');
        }

        final details = CategoryDetailsResponse.fromJson(responseData['data']);
        developer.log('✅ Category details fetched successfully: ${details.transactions.length} transactions');
        return details;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch category details');
      }
    } catch (e) {
      developer.log('❌ Get category details error: $e');
      rethrow;
    }
  }
}

// Data Models
class CategoryDetailsResponse {
  final List<Transaction> transactions;
  final Pagination pagination;

  CategoryDetailsResponse({
    required this.transactions,
    required this.pagination,
  });

  factory CategoryDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CategoryDetailsResponse(
      transactions: (json['transactions'] as List)
          .map((item) => Transaction.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String description;
  final String date;
  final String createdAt;
  final String updatedAt;

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
      description: json['description'],
      date: json['date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
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
}

class ReportsSummary {
  final String period;
  final double totalIncome;
  final double totalExpense;
  final double difference;
  final TransactionCount transactionCount;

  ReportsSummary({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.difference,
    required this.transactionCount,
  });

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    return ReportsSummary(
      period: json['period'],
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      transactionCount: TransactionCount.fromJson(json['transaction_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'difference': difference,
      'transaction_count': transactionCount.toJson(),
    };
  }

  double get savingsRate => totalIncome > 0 ? (difference / totalIncome) * 100 : 0;
  bool get isProfitable => totalIncome > totalExpense;
}

class TransactionCount {
  final int income;
  final int expense;

  TransactionCount({
    required this.income,
    required this.expense,
  });

  factory TransactionCount.fromJson(Map<String, dynamic> json) {
    return TransactionCount(
      income: json['income'],
      expense: json['expense'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': income,
      'expense': expense,
    };
  }

  int get total => income + expense;
}

class CategoryBreakdown {
  final List<CategoryItem> categories;
  final double totalAmount;

  CategoryBreakdown({
    required this.categories,
    required this.totalAmount,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categories: (json['categories'] as List)
          .map((item) => CategoryItem.fromJson(item))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
    };
  }
}

class CategoryItem {
  final String type;
  final String name;
  final double amount;
  final double percentage;
  final int count;
  final String color;

  CategoryItem({
    required this.type,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.count,
    required this.color,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      type: json['type'] ?? 'expense',
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      count: json['count'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'amount': amount,
      'percentage': percentage,
      'count': count,
      'color': color,
    };
  }
}

class ChartItem {
  final double value;
  final String title;
  final String category;
  final double amount;
  final String color;

  ChartItem({
    required this.value,
    required this.title,
    required this.category,
    required this.amount,
    required this.color,
  });

  factory ChartItem.fromJson(Map<String, dynamic> json) {
    return ChartItem(
      value: (json['value'] as num).toDouble(),
      title: json['title'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'title': title,
      'category': category,
      'amount': amount,
      'color': color,
    };
  }
}
