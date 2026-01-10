import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

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
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } catch (e) {
      developer.log('❌ API request failed: $e');
      throw Exception('API request failed: ${e.toString()}');
    }
  }

  // Get spending trends
  Future<List<SpendingTrend>> getSpendingTrends({int months = 6}) async {
    try {
      developer.log('🔄 Fetching spending trends for $months months');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.analyticsTrends,
        'GET',
        queryParams: {'months': months.toString()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch spending trends',
          );
        }

        final List<SpendingTrend> trends =
            (responseData['data']['trends'] as List)
                .map((item) => SpendingTrend.fromJson(item))
                .toList();

        developer.log('✅ Retrieved ${trends.length} spending trends');
        return trends;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch spending trends',
        );
      }
    } catch (e) {
      developer.log('❌ Get spending trends error: $e');
      rethrow;
    }
  }

  // Get forecast
  Future<Forecast> getForecast() async {
    try {
      developer.log('🔄 Fetching forecast');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.analyticsForecast,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch forecast',
          );
        }

        final forecast = Forecast.fromJson(responseData['data']['forecast']);
        developer.log('✅ Forecast fetched successfully');
        return forecast;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch forecast');
      }
    } catch (e) {
      developer.log('❌ Get forecast error: $e');
      rethrow;
    }
  }

  // Get top spending categories
  Future<List<TopCategory>> getTopCategories() async {
    try {
      developer.log('🔄 Fetching top categories');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.analyticsTopCategories,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch top categories',
          );
        }

        final List<TopCategory> categories =
            (responseData['data']['top_categories'] as List)
                .map((item) => TopCategory.fromJson(item))
                .toList();

        developer.log('✅ Retrieved ${categories.length} top categories');
        return categories;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch top categories',
        );
      }
    } catch (e) {
      developer.log('❌ Get top categories error: $e');
      rethrow;
    }
  }

  // Get financial health score
  Future<HealthScore> getHealthScore() async {
    try {
      developer.log('🔄 Fetching health score');

      final response = await _makeAuthenticatedRequest(
        ApiConfig.analyticsHealthScore,
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch health score',
          );
        }

        final healthScore = HealthScore.fromJson(responseData['data']);
        developer.log('✅ Health score fetched: ${healthScore.score}');
        return healthScore;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch health score');
      }
    } catch (e) {
      developer.log('❌ Get health score error: $e');
      rethrow;
    }
  }
}

// Data Models
class SpendingTrend {
  final String month;
  final List<CategoryAmount> categories;
  final double totalExpense;

  SpendingTrend({
    required this.month,
    required this.categories,
    required this.totalExpense,
  });

  factory SpendingTrend.fromJson(Map<String, dynamic> json) {
    return SpendingTrend(
      month: json['month'],
      categories: (json['categories'] as List)
          .map((item) => CategoryAmount.fromJson(item))
          .toList(),
      totalExpense: (json['total_expense'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'categories': categories.map((c) => c.toJson()).toList(),
      'total_expense': totalExpense,
    };
  }
}

class CategoryAmount {
  final String name;
  final double amount;

  CategoryAmount({required this.name, required this.amount});

  factory CategoryAmount.fromJson(Map<String, dynamic> json) {
    return CategoryAmount(
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount};
  }
}

class Forecast {
  final double predictedIncome;
  final double predictedExpense;
  final String confidenceLevel; // 'high', 'medium', 'low'
  final String insight;

  Forecast({
    required this.predictedIncome,
    required this.predictedExpense,
    required this.confidenceLevel,
    required this.insight,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      predictedIncome: (json['predicted_income'] as num).toDouble(),
      predictedExpense: (json['predicted_expense'] as num).toDouble(),
      confidenceLevel: json['confidence_level'] ?? 'medium',
      insight: json['insight'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_income': predictedIncome,
      'predicted_expense': predictedExpense,
      'confidence_level': confidenceLevel,
      'insight': insight,
    };
  }

  double get predictedSavings => predictedIncome - predictedExpense;
}

class TopCategory {
  final String category;
  final double total;
  final double percentage;

  TopCategory({
    required this.category,
    required this.total,
    required this.percentage,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) {
    return TopCategory(
      category: json['category'],
      total: (json['total'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'total': total, 'percentage': percentage};
  }
}

class HealthScore {
  final int score;
  final HealthIndicators indicators;
  final List<String> recommendations;

  HealthScore({
    required this.score,
    required this.indicators,
    required this.recommendations,
  });

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    return HealthScore(
      score: json['health_score'] as int,
      indicators: HealthIndicators.fromJson(json['indicators']),
      recommendations: (json['recommendations'] as List)
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health_score': score,
      'indicators': indicators.toJson(),
      'recommendations': recommendations,
    };
  }

  // Helper methods
  String get scoreLabel {
    if (score >= 86) return 'Excellent';
    if (score >= 71) return 'Sangat Baik';
    if (score >= 51) return 'Baik';
    if (score >= 31) return 'Cukup';
    return 'Perlu Perhatian';
  }

  String get scoreEmoji {
    if (score >= 86) return '🌟';
    if (score >= 71) return '😊';
    if (score >= 51) return '🙂';
    if (score >= 31) return '😐';
    return '😟';
  }
}

class HealthIndicators {
  final String savingsRate; // 'excellent', 'good', 'fair', 'poor'
  final String expenseControl;
  final String budgetAdherence;

  HealthIndicators({
    required this.savingsRate,
    required this.expenseControl,
    required this.budgetAdherence,
  });

  factory HealthIndicators.fromJson(Map<String, dynamic> json) {
    return HealthIndicators(
      savingsRate: json['savings_rate'] ?? 'fair',
      expenseControl: json['expense_control'] ?? 'fair',
      budgetAdherence: json['budget_adherence'] ?? 'fair',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savings_rate': savingsRate,
      'expense_control': expenseControl,
      'budget_adherence': budgetAdherence,
    };
  }
}
