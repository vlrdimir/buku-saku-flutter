import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

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

  // Create a new goal
  Future<Goal> createGoal({
    required String name,
    required double targetAmount,
    required String targetDate,
    double? initialSaving,
  }) async {
    try {
      developer.log('🔄 Creating goal: $name, $targetAmount');

      final Map<String, dynamic> body = {
        'name': name,
        'target_amount': targetAmount,
        'target_date': targetDate,
      };
      if (initialSaving != null) {
        body['initial_saving'] = initialSaving;
      }

      final response = await _makeAuthenticatedRequest(
        ApiConfig.goals,
        'POST',
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to create goal');
        }

        final goal = Goal.fromJson(responseData['data']['goal']);
        developer.log('✅ Goal created successfully: ${goal.id}');
        return goal;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create goal');
      }
    } catch (e) {
      developer.log('❌ Create goal error: $e');
      rethrow;
    }
  }

  // Get all goals
  Future<List<Goal>> getGoals() async {
    try {
      developer.log('🔄 Fetching all goals');

      final response = await _makeAuthenticatedRequest(ApiConfig.goals, 'GET');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to fetch goals');
        }

        final List<Goal> goals = (responseData['data']['goals'] as List)
            .map((item) => Goal.fromJson(item))
            .toList();

        developer.log('✅ Retrieved ${goals.length} goals');
        return goals;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch goals');
      }
    } catch (e) {
      developer.log('❌ Get goals error: $e');
      rethrow;
    }
  }

  // Update a goal
  Future<Goal> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? targetDate,
  }) async {
    try {
      developer.log('🔄 Updating goal: $id');

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (targetAmount != null) body['target_amount'] = targetAmount;
      if (currentAmount != null) body['current_amount'] = currentAmount;
      if (targetDate != null) body['target_date'] = targetDate;

      final response = await _makeAuthenticatedRequest(
        '${ApiConfig.goals}/$id',
        'PUT',
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to update goal');
        }

        final goal = Goal.fromJson(responseData['data']['goal']);
        developer.log('✅ Goal updated successfully: ${goal.id}');
        return goal;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update goal');
      }
    } catch (e) {
      developer.log('❌ Update goal error: $e');
      rethrow;
    }
  }

  // Delete a goal
  Future<bool> deleteGoal(String id) async {
    try {
      developer.log('🔄 Deleting goal: $id');

      final response = await _makeAuthenticatedRequest(
        '${ApiConfig.goals}/$id',
        'DELETE',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(responseData['message'] ?? 'Failed to delete goal');
        }

        developer.log('✅ Goal deleted successfully: $id');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete goal');
      }
    } catch (e) {
      developer.log('❌ Delete goal error: $e');
      rethrow;
    }
  }

  // Get goal progress details
  Future<GoalProgress> getGoalProgress(String id) async {
    try {
      developer.log('🔄 Fetching goal progress: $id');

      final response = await _makeAuthenticatedRequest(
        '${ApiConfig.goals}/$id/progress',
        'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch goal progress',
          );
        }

        final progress = GoalProgress.fromJson(responseData['data']);
        developer.log('✅ Goal progress fetched successfully: $id');
        return progress;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch goal progress',
        );
      }
    } catch (e) {
      developer.log('❌ Get goal progress error: $e');
      rethrow;
    }
  }
}

// Data Models
class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double progressPercentage;
  final String targetDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.targetDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final targetAmount = (json['target_amount'] as num).toDouble();
    final currentAmount = (json['current_amount'] as num?)?.toDouble() ?? 0.0;

    return Goal(
      id: json['id'],
      name: json['name'],
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ??
          (targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0),
      targetDate: json['target_date'],
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
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'progress_percentage': progressPercentage,
      'target_date': targetDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    double? progressPercentage,
    String? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  double get remainingAmount => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;
}

class GoalProgress {
  final String goalId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final int monthsLeft;
  final double recommendedMonthlySaving;
  final String status; // 'on_track', 'behind', 'ahead', 'completed'

  GoalProgress({
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.monthsLeft,
    required this.recommendedMonthlySaving,
    required this.status,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      goalId: json['goal_id'],
      name: json['name'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      monthsLeft: json['months_left'] as int,
      recommendedMonthlySaving: (json['recommended_monthly_saving'] as num)
          .toDouble(),
      status: json['status'] ?? 'on_track',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'remaining_amount': remainingAmount,
      'months_left': monthsLeft,
      'recommended_monthly_saving': recommendedMonthlySaving,
      'status': status,
    };
  }

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;
}
