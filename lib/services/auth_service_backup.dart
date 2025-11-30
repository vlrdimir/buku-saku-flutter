// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:http/http.dart' as http;
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   static final AuthService _instance = AuthService._internal();
//   factory AuthService() => _instance;
//   AuthService._internal() {
//     _initializeGoogleSignIn();
//   }

//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   bool _isGoogleSignInInitialized = false;

//   Future<void> _initializeGoogleSignIn() async {
//     try {
//       // Initialize Google Sign-In. No need to differentiate between web/mobile here
//       // if the client ID is the same and we are not using serverClientId on mobile.
//       await _googleSignIn.initialize(clientId: _googleWebClientId);
//       _isGoogleSignInInitialized = true;
//     } catch (e) {
//       throw AuthException(
//         'Failed to initialize Google Sign-In: ${e.toString()}',
//       );
//     }
//   }

//   /// Always check Google Sign-In initialization before use
//   Future<void> _ensureGoogleSignInInitialized() async {
//     if (!_isGoogleSignInInitialized) {
//       await _initializeGoogleSignIn();
//     }
//   }

//   // 🔧 Configuration - Update based on your environment
//   static const String _baseUrl = 'http://localhost:8082/v1';
//   static const String _tokenKey = 'jwt_token';
//   static const String _userKey = 'user_data';

//   // Google OAuth2 Client IDs
//   // For Web (Chrome) - Web Application Client ID
//   static const String _googleWebClientId = '.apps.googleusercontent.com';

//   GoogleSignInAccount? _currentUser;
//   GoogleSignInAccount? get currentUser => _currentUser;

//   Stream<GoogleSignInAuthenticationEvent> get onCurrentUserChanged =>
//       _googleSignIn.authenticationEvents;

//   // Check if user is already signed in
//   bool get isSignedIn => _currentUser != null;

//   // Sign in with Google and return only id_token
//   Future<String?> signInWithGoogle() async {
//     await _ensureGoogleSignInInitialized();
//     try {
//       // On mobile, this will open the native Google Sign-In prompt.
//       final GoogleSignInAccount account = await _googleSignIn.authenticate();
//       _currentUser = account;

//       final GoogleSignInAuthentication auth = account.authentication;
//       final idToken = auth.idToken;

//       if (idToken == null) {
//         throw AuthException('Failed to obtain Google ID token');
//       }

//       // debug print the id token
//       developer.log('Google ID token length: ${idToken.length}');
//       // Return the id token for backend authentication
//       return idToken;
//     } catch (e) {
//       if (e is AuthException) {
//         rethrow;
//       }
//       throw AuthException('Google sign-in failed: ${e.toString()}');
//     }
//   }

//   // Authenticate with backend using Google id_token
//   Future<AuthResult> authenticateWithBackend(String googleIdToken) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/auth/google'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'id_token': googleIdToken}),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = jsonDecode(response.body);

//         if (responseData['status'] == 'success') {
//           final String jwtToken = responseData['data']['token'];
//           final Map<String, dynamic> userData = responseData['data']['user'];

//           // Store JWT token and user data locally
//           await _saveToken(jwtToken);
//           await _saveUser(userData);

//           return AuthResult.success(jwtToken: jwtToken, user: userData);
//         } else {
//           throw AuthException(
//             responseData['message'] ?? 'Authentication failed',
//           );
//         }
//       } else {
//         final errorData = jsonDecode(response.body);
//         throw AuthException(
//           errorData['message'] ??
//               'Backend authentication failed with status: ${response.statusCode}',
//         );
//       }
//     } catch (e) {
//       if (e is AuthException) {
//         rethrow;
//       }
//       throw AuthException('Network error: ${e.toString()}');
//     }
//   }

//   // Combined sign-in method: Google sign-in + backend authentication
//   Future<AuthResult> signInAndAuthenticate() async {
//     try {
//       // Get Google ID token
//       final String? googleIdToken = await signInWithGoogle();

//       if (googleIdToken == null) {
//         throw AuthException('Failed to get Google ID token');
//       }

//       // Authenticate with backend
//       final authResult = await authenticateWithBackend(googleIdToken);
//       return authResult;
//     } catch (e) {
//       if (e is AuthException) {
//         rethrow;
//       }
//       throw AuthException('Authentication process failed: ${e.toString()}');
//     }
//   }

//   // Sign out from Google and clear local storage
//   Future<void> signOut() async {
//     try {
//       // Sign out from Google
//       await _googleSignIn.signOut();

//       // Clear local storage
//       await clearStoredAuth();
//     } catch (e) {
//       throw AuthException('Sign out failed: ${e.toString()}');
//     }
//   }

//   // Get stored JWT token
//   Future<String?> getStoredToken() async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       return prefs.getString(_tokenKey);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Get stored user data
//   Future<Map<String, dynamic>?> getStoredUser() async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       final String? userJson = prefs.getString(_userKey);
//       if (userJson != null) {
//         return jsonDecode(userJson);
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   // Check if user has valid stored authentication
//   Future<bool> hasStoredAuth() async {
//     final token = await getStoredToken();
//     return token != null && token.isNotEmpty;
//   }

//   // Save JWT token to local storage
//   Future<void> _saveToken(String token) async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_tokenKey, token);
//     } catch (e) {
//       throw Exception('Failed to save token: ${e.toString()}');
//     }
//   }

//   // Save user data to local storage
//   Future<void> _saveUser(Map<String, dynamic> userData) async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_userKey, jsonEncode(userData));
//     } catch (e) {
//       throw Exception('Failed to save user data: ${e.toString()}');
//     }
//   }

//   // Clear all stored authentication data
//   Future<void> clearStoredAuth() async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.remove(_tokenKey);
//       await prefs.remove(_userKey);
//     } catch (e) {
//       // Continue even if cleanup fails
//     }
//   }

//   // Make authenticated API request with JWT token
//   Future<http.Response> makeAuthenticatedRequest(
//     String endpoint,
//     String method, {
//     Map<String, dynamic>? body,
//   }) async {
//     try {
//       final String? token = await getStoredToken();
//       if (token == null) {
//         throw AuthException('No authentication token found');
//       }

//       final Map<String, String> headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       };

//       late http.Response response;
//       final Uri uri = Uri.parse('$_baseUrl$endpoint');

//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PUT':
//           response = await http.put(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw AuthException('Unsupported HTTP method: $method');
//       }

//       return response;
//     } catch (e) {
//       if (e is AuthException) {
//         rethrow;
//       }
//       throw AuthException('API request failed: ${e.toString()}');
//     }
//   }
// }

// // Custom exception class for authentication errors
// class AuthException implements Exception {
//   final String message;

//   const AuthException(this.message);

//   @override
//   String toString() => message;
// }

// // Result class for authentication operations
// class AuthResult {
//   final bool success;
//   final String? jwtToken;
//   final Map<String, dynamic>? user;
//   final String? error;

//   AuthResult.success({required this.jwtToken, required this.user})
//     : success = true,
//       error = null;

//   AuthResult.failure({required this.error})
//     : success = false,
//       jwtToken = null,
//       user = null;

//   bool get isSuccess => success;
//   bool get isFailure => !success;
// }
