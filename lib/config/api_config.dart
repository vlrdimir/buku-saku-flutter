/// Centralized API Configuration
///
/// This class provides a single source of truth for API configuration.
/// The base URL can be configured at build time using --dart-define:
///
/// ```bash
/// flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com/v1
/// ```
///
/// For Docker builds, this is automatically handled in the Dockerfile.
class ApiConfig {
  ApiConfig._();

  /// Base URL for all API calls.
  ///
  /// Default: http://localhost:8082/v1 (for local development)
  /// Override at build time with --dart-define=API_BASE_URL=<your-url>
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8082/v1',
  );

  /// Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  /// API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authProfile = '/auth/profile';
  static const String authChangePassword = '/auth/change-password';

  static const String usersProfile = '/users/profile';

  static const String transactions = '/transactions';
  static const String transactionsRecent = '/transactions/recent';

  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardChart = '/dashboard/chart';

  static const String reportsSummary = '/reports/summary';
  static const String reportsCategories = '/reports/categories';
  static const String reportsCharts = '/reports/charts';
  static const String reportsCategoryDetails = '/reports/category-details';
}
