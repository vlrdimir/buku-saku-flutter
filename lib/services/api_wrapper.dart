import 'dart:developer' as developer;
import '../services/auth_service.dart' as auth;
import '../services/dashboard_service.dart' as dashboard;
import '../services/transaction_service.dart' as transaction;
import '../services/reports_service.dart' as reports;
import '../services/user_service.dart' as user;

class ApiWrapper {
  static final ApiWrapper _instance = ApiWrapper._internal();
  factory ApiWrapper() => _instance;
  ApiWrapper._internal();

  // Service instances
  final auth.AuthServiceNew _authService = auth.AuthServiceNew();
  final dashboard.DashboardService _dashboardService =
      dashboard.DashboardService();
  final transaction.TransactionService _transactionService =
      transaction.TransactionService();
  final reports.ReportsService _reportsService = reports.ReportsService();
  final user.UserService _userService = user.UserService();

  // Authentication
  Future<auth.AuthResult> login(String email, String password) async {
    developer.log('🔐 API Wrapper: Login attempt');
    return await _authService.login(email, password);
  }

  Future<auth.AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    developer.log('🔐 API Wrapper: Register attempt');
    return await _authService.register(name, email, password);
  }

  Future<bool> logout() async {
    developer.log('🔐 API Wrapper: Logout attempt');
    try {
      await _authService.signOut();
      return true;
    } catch (e) {
      developer.log('❌ API Wrapper: Logout error: $e');
      return false;
    }
  }

  Future<bool> hasStoredAuth() async {
    try {
      return await _authService.hasStoredAuth();
    } catch (e) {
      developer.log('❌ API Wrapper: Check auth error: $e');
      return false;
    }
  }

  // Dashboard
  Future<dashboard.DashboardSummary?> getDashboardSummary() async {
    developer.log('🔐 API Wrapper: Getting dashboard summary');
    try {
      return await _dashboardService.getDashboardSummary();
    } catch (e) {
      developer.log('❌ API Wrapper: Dashboard summary error: $e');
      return null;
    }
  }

  Future<List<dashboard.ChartDataPoint>> getChartData({
    String period = '7days',
  }) async {
    developer.log('🔐 API Wrapper: Getting chart data for period: $period');
    try {
      return await _dashboardService.getChartData(period: period);
    } catch (e) {
      developer.log('❌ API Wrapper: Chart data error: $e');
      return [];
    }
  }

  Future<List<dashboard.Transaction>> getRecentTransactions() async {
    developer.log('🔐 API Wrapper: Getting recent transactions');
    try {
      return _dashboardService.getRecentTransactions();
    } catch (e) {
      developer.log('❌ API Wrapper: Recent transactions error: $e');
      return [];
    }
  }

  // Transactions
  Future<transaction.TransactionListResponse> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    developer.log('🔐 API Wrapper: Getting transactions');
    try {
      return await _transactionService.getTransactions(
        page: page,
        limit: limit,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      developer.log('❌ API Wrapper: Transactions error: $e');
      return transaction.TransactionListResponse(
        transactions: [],
        pagination: transaction.Pagination(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          itemsPerPage: limit,
        ),
      );
    }
  }

  Future<transaction.Transaction> createTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    developer.log('🔐 API Wrapper: Creating transaction');
    return await _transactionService.createTransaction(
      type: type,
      amount: amount,
      category: category,
      description: description,
      date: date,
    );
  }

  Future<bool> deleteTransaction(String id) async {
    developer.log('🔐 API Wrapper: Deleting transaction: $id');
    try {
      await _transactionService.deleteTransaction(id);
      return true;
    } catch (e) {
      developer.log('❌ API Wrapper: Delete transaction error: $e');
      return false;
    }
  }

  // Reports
  Future<reports.ReportsSummary?> getReportsSummary({
    required String period,
  }) async {
    developer.log(
      '🔐 API Wrapper: Getting reports summary for period: $period',
    );
    try {
      return await _reportsService.getReportsSummary(period: period);
    } catch (e) {
      developer.log('❌ API Wrapper: Reports summary error: $e');
      return null;
    }
  }

  Future<reports.CategoryBreakdown?> getCategoryBreakdown({
    required String period,
    String type = 'expense',
  }) async {
    developer.log(
      '🔐 API Wrapper: Getting category breakdown for period: $period, type: $type',
    );
    try {
      return await _reportsService.getCategoryBreakdown(
        period: period,
        type: type,
      );
    } catch (e) {
      developer.log('❌ API Wrapper: Category breakdown error: $e');
      return null;
    }
  }

  Future<List<reports.ChartItem>> getChartItems({
    required String period,
    required String chartType,
  }) async {
    developer.log(
      '🔐 API Wrapper: Getting chart items for period: $period, type: $chartType',
    );
    try {
      return await _reportsService.getReportsChartData(
        period: period,
        chartType: chartType,
      );
    } catch (e) {
      developer.log('❌ API Wrapper: Chart items error: $e');
      return [];
    }
  }

  // User
  Future<user.User?> getUserProfile() async {
    developer.log('🔐 API Wrapper: Getting user profile');
    try {
      return await _userService.getUserProfile();
    } catch (e) {
      developer.log('❌ API Wrapper: User profile error: $e');
      return null;
    }
  }

  Future<user.UserSettings?> getUserSettings() async {
    developer.log('🔐 API Wrapper: Getting user settings');
    try {
      return await _userService.getUserSettings();
    } catch (e) {
      developer.log('❌ API Wrapper: User settings error: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({String? name}) async {
    developer.log('🔐 API Wrapper: Updating user profile');
    try {
      if (name != null) {
        await _userService.updateUserProfile(name: name);
        return true;
      }
      return false;
    } catch (e) {
      developer.log('❌ API Wrapper: Update profile error: $e');
      return false;
    }
  }

  Future<bool> updateUserSettings({
    String? currency,
    String? language,
    bool? notifications,
    String? theme,
  }) async {
    developer.log('🔐 API Wrapper: Updating user settings');
    try {
      await _userService.getUserSettings();

      await _userService.updateUserSettings(
        currency: currency,
        language: language,
        notifications: notifications,
        theme: theme,
      );
      return true;
    } catch (e) {
      developer.log('❌ API Wrapper: Update settings error: $e');
      return false;
    }
  }
}

// Extension methods for easier access
extension ApiWrapperExtensions on ApiWrapper {
  String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.')}';
  }

  bool isProfitable(reports.ReportsSummary summary) {
    return summary.totalIncome > summary.totalExpense;
  }

  double getProfitMargin(reports.ReportsSummary summary) {
    if (summary.totalIncome == 0) return 0.0;
    return ((summary.totalIncome - summary.totalExpense) /
            summary.totalIncome) *
        100;
  }
}
