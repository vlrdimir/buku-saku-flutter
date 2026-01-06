import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthServiceNew {
  static final AuthServiceNew _instance = AuthServiceNew._internal();
  factory AuthServiceNew() => _instance;
  AuthServiceNew._internal();

  // 🔧 Configuration - Now using centralized ApiConfig
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _tokenKey = ApiConfig.tokenKey;
  static const String _userKey = ApiConfig.userKey;

  // Check if user has valid stored authentication
  Future<bool> hasStoredAuth() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  // Get stored JWT token
  Future<String?> getStoredToken() async {
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

  // User Registration
  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      developer.log('🔄 Starting registration process for email: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      developer.log('📊 Registration response status: ${response.statusCode}');
      developer.log('📊 Registration response body: ${response.body}');

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        developer.log('❌ JSON parsing error: ${e.toString()}');
        return AuthResult.failure(error: 'Invalid response from server');
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['status'] == 'success') {
        final String jwtToken = responseData['data']['token'];
        final Map<String, dynamic> userData = responseData['data']['user'];

        // Store JWT token and user data locally
        await _saveToken(jwtToken);
        await _saveUser(userData);

        developer.log(
          '✅ Registration successful for user: ${userData['email']}',
        );
        return AuthResult.success(jwtToken: jwtToken, user: userData);
      } else {
        final errorMessage = responseData['message'] ?? 'Registration failed';
        developer.log('❌ Registration failed: $errorMessage');
        return AuthResult.failure(error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Registration error: ${e.toString()}');
      return AuthResult.failure(error: 'Network error: ${e.toString()}');
    }
  }

  // User Login
  Future<AuthResult> login(String email, String password) async {
    try {
      developer.log('🔄 Starting login process for email: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      developer.log('📊 Login response status: ${response.statusCode}');
      developer.log('📊 Login response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final String jwtToken = responseData['data']['token'];
        final Map<String, dynamic> userData = responseData['data']['user'];

        // Store JWT token and user data locally
        await _saveToken(jwtToken);
        await _saveUser(userData);

        developer.log('✅ Login successful for user: ${userData['email']}');
        return AuthResult.success(jwtToken: jwtToken, user: userData);
      } else {
        final errorMessage = responseData['message'] ?? 'Login failed';
        developer.log('❌ Login failed: $errorMessage');
        return AuthResult.failure(error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Login error: ${e.toString()}');
      return AuthResult.failure(error: 'Network error: ${e.toString()}');
    }
  }

  // Change Password
  Future<AuthResult> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      developer.log('🔄 Starting password change process');

      if (newPassword != confirmPassword) {
        return AuthResult.failure(
          error: 'New password and confirmation do not match',
        );
      }

      final response = await makeAuthenticatedRequest(
        '/auth/change-password',
        'POST',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        developer.log('✅ Password change successful');
        return AuthResult.success(
          jwtToken: await getStoredToken(),
          user: await getStoredUser(),
        );
      } else {
        final errorMessage =
            responseData['message'] ?? 'Password change failed';
        developer.log('❌ Password change failed: $errorMessage');
        return AuthResult.failure(error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Password change error: ${e.toString()}');
      return AuthResult.failure(error: 'Network error: ${e.toString()}');
    }
  }

  // Get Current User Profile
  Future<AuthResult> getProfile() async {
    try {
      developer.log('🔄 Getting user profile');

      final response = await makeAuthenticatedRequest('/auth/profile', 'GET');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final Map<String, dynamic> userData = responseData['data']['user'];

        // Update stored user data
        await _saveUser(userData);

        developer.log('✅ Profile retrieved successfully');
        return AuthResult.success(
          jwtToken: await getStoredToken(),
          user: userData,
        );
      } else {
        final errorMessage = responseData['message'] ?? 'Failed to get profile';
        developer.log('❌ Profile retrieval failed: $errorMessage');
        return AuthResult.failure(error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Profile retrieval error: ${e.toString()}');
      return AuthResult.failure(error: 'Network error: ${e.toString()}');
    }
  }

  // Sign out and clear local storage
  Future<void> signOut() async {
    try {
      developer.log('🔄 Signing out user');

      // Clear local storage
      await clearStoredAuth();

      developer.log('✅ Sign out completed');
    } catch (e) {
      developer.log('❌ Sign out error: ${e.toString()}');
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  // Stream to notify app about auth state changes (e.g., logout)
  final _authStreamController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStreamController.stream;

  // Make authenticated API request with JWT token
  Future<http.Response> makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final String? token = await getStoredToken();
      if (token == null) {
        _authStreamController.add(false); // Notify unauthenticated
        throw AuthException('No authentication token found');
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      late http.Response response;
      final Uri uri = Uri.parse('$_baseUrl$endpoint');

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
          throw AuthException('Unsupported HTTP method: $method');
      }

      // Check for 401 Unauthorized
      if (response.statusCode == 401) {
        developer.log('⚠️ Unauthorized access detected (401). Logging out.');
        await clearStoredAuth();
        _authStreamController.add(false); // Notify app to logout
        throw AuthException('Session expired. Please login again.');
      }

      return response;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('API request failed: ${e.toString()}');
    }
  }

  // Save JWT token to local storage
  Future<void> _saveToken(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      throw Exception('Failed to save token: ${e.toString()}');
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

  // Clear all stored authentication data
  Future<void> clearStoredAuth() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      // Continue even if cleanup fails
      developer.log('⚠️ Failed to clear stored auth: ${e.toString()}');
    }
  }
}

// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

// Result class for authentication operations
class AuthResult {
  final bool success;
  final String? jwtToken;
  final Map<String, dynamic>? user;
  final String? error;

  AuthResult.success({required this.jwtToken, required this.user})
    : success = true,
      error = null;

  AuthResult.failure({required this.error})
    : success = false,
      jwtToken = null,
      user = null;

  bool get isSuccess => success;
  bool get isFailure => !success;
}
