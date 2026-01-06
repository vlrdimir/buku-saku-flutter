import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Base URL configuration
  static const String _baseUrl = 'http://localhost:8082/v1';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Get stored JWT token
  Future<String?> _getStoredToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Get stored user data
  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return jsonDecode(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user data to local storage
  Future<void> _saveUser(Map<String, dynamic> userData) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userData));
    } catch (e) {
      throw Exception('Failed to save user data: ${e.toString()}');
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

  // Get user profile using /users/profile endpoint
  Future<User> getUserProfile() async {
    try {
      developer.log('🔄 Fetching user profile');

      final response = await _makeAuthenticatedRequest('/users/profile', 'GET');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch user profile',
          );
        }

        final user = User.fromJson(responseData['data']);

        // Update stored user data
        await _saveUser(user.toJson());

        developer.log('✅ User profile fetched successfully');
        return user;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e) {
      developer.log('❌ Get user profile error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<User> updateUserProfile({required String name}) async {
    try {
      developer.log('🔄 Updating user profile');

      final response = await _makeAuthenticatedRequest(
        '/users/profile',
        'PUT',
        body: {'name': name},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to update user profile',
          );
        }

        final user = User.fromJson(responseData['data']);

        // Update stored user data
        await _saveUser(user.toJson());

        developer.log('✅ User profile updated successfully');
        return user;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to update user profile',
        );
      }
    } catch (e) {
      developer.log('❌ Update user profile error: $e');
      rethrow;
    }
  }

  // Change password using /auth/change-password endpoint
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      developer.log('🔄 Changing password');

      if (newPassword != confirmPassword) {
        throw Exception('New password and confirmation do not match');
      }

      final response = await _makeAuthenticatedRequest(
        '/auth/change-password',
        'POST',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] != 'success') {
          throw Exception(
            responseData['message'] ?? 'Failed to change password',
          );
        }

        developer.log('✅ Password changed successfully');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      developer.log('❌ Change password error: $e');
      rethrow;
    }
  }
}

// Data Models
class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSettings? settings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );

    // Parse settings if available
    if (json['settings'] != null) {
      return user.copyWith(settings: UserSettings.fromJson(json['settings']));
    }

    return user;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (settings != null) {
      json['settings'] = settings!.toJson();
    }

    return json;
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSettings? settings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }
}

class UserSettings {
  final String currency;
  final String language;
  final bool notifications;
  final String theme;
  final String dateFormat;
  final int numberDecimal;

  UserSettings({
    required this.currency,
    required this.language,
    required this.notifications,
    required this.theme,
    required this.dateFormat,
    required this.numberDecimal,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: json['currency'] ?? 'IDR',
      language: json['language'] ?? 'id',
      notifications: json['notifications'] ?? true,
      theme: json['theme'] ?? 'light',
      dateFormat: json['date_format'] ?? 'dd/MM/yyyy',
      numberDecimal: json['number_decimal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
      'notifications': notifications,
      'theme': theme,
      'date_format': dateFormat,
      'number_decimal': numberDecimal,
    };
  }

  UserSettings copyWith({
    String? currency,
    String? language,
    bool? notifications,
    String? theme,
    String? dateFormat,
    int? numberDecimal,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      theme: theme ?? this.theme,
      dateFormat: dateFormat ?? this.dateFormat,
      numberDecimal: numberDecimal ?? this.numberDecimal,
    );
  }

  bool get isDarkTheme => theme == 'dark';
  bool get isLightTheme => theme == 'light';
}
