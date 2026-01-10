import 'dart:developer' as developer;
import '../services/auth_service.dart' as auth;
import '../services/dashboard_service.dart' as dashboard;
import '../services/transaction_service.dart' as transaction;
import '../services/reports_service.dart' as reports;
import '../services/user_service.dart' as user;
import '../services/budget_service.dart' as budget;
import '../services/goal_service.dart' as goal;
import '../services/analytics_service.dart' as analytics;

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
  final budget.BudgetService _budgetService = budget.BudgetService();
  final goal.GoalService _goalService = goal.GoalService();
  final analytics.AnalyticsService _analyticsService =
      analytics.AnalyticsService();

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

  // ==================== BUDGET METHODS ====================

  Future<budget.Budget> createBudget({
    required String category,
    required double amount,
    required String period,
    required String startDate,
  }) async {
    developer.log('🔐 API Wrapper: Creating budget');
    return await _budgetService.createBudget(
      category: category,
      amount: amount,
      period: period,
      startDate: startDate,
    );
  }

  Future<List<budget.Budget>> getBudgets() async {
    developer.log('🔐 API Wrapper: Getting budgets');
    try {
      return await _budgetService.getBudgets();
    } catch (e) {
      developer.log('❌ API Wrapper: Get budgets error: $e');
      return [];
    }
  }

  Future<budget.Budget> updateBudget({
    required String id,
    double? amount,
    String? category,
    String? period,
    String? startDate,
  }) async {
    developer.log('🔐 API Wrapper: Updating budget: $id');
    return await _budgetService.updateBudget(
      id: id,
      amount: amount,
      category: category,
      period: period,
      startDate: startDate,
    );
  }

  Future<bool> deleteBudget(String id) async {
    developer.log('🔐 API Wrapper: Deleting budget: $id');
    try {
      await _budgetService.deleteBudget(id);
      return true;
    } catch (e) {
      developer.log('❌ API Wrapper: Delete budget error: $e');
      return false;
    }
  }

  Future<List<budget.BudgetAlert>> getBudgetAlerts() async {
    developer.log('🔐 API Wrapper: Getting budget alerts');
    try {
      return await _budgetService.getBudgetAlerts();
    } catch (e) {
      developer.log('❌ API Wrapper: Get budget alerts error: $e');
      return [];
    }
  }

  // ==================== GOAL METHODS ====================

  Future<goal.Goal> createGoal({
    required String name,
    required double targetAmount,
    required String targetDate,
    double? initialSaving,
  }) async {
    developer.log('🔐 API Wrapper: Creating goal');
    return await _goalService.createGoal(
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      initialSaving: initialSaving,
    );
  }

  Future<List<goal.Goal>> getGoals() async {
    developer.log('🔐 API Wrapper: Getting goals');
    try {
      return await _goalService.getGoals();
    } catch (e) {
      developer.log('❌ API Wrapper: Get goals error: $e');
      return [];
    }
  }

  Future<goal.Goal> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? targetDate,
  }) async {
    developer.log('🔐 API Wrapper: Updating goal: $id');
    return await _goalService.updateGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
    );
  }

  Future<bool> deleteGoal(String id) async {
    developer.log('🔐 API Wrapper: Deleting goal: $id');
    try {
      await _goalService.deleteGoal(id);
      return true;
    } catch (e) {
      developer.log('❌ API Wrapper: Delete goal error: $e');
      return false;
    }
  }

  Future<goal.GoalProgress?> getGoalProgress(String id) async {
    developer.log('🔐 API Wrapper: Getting goal progress: $id');
    try {
      return await _goalService.getGoalProgress(id);
    } catch (e) {
      developer.log('❌ API Wrapper: Get goal progress error: $e');
      return null;
    }
  }

  // ==================== ANALYTICS METHODS ====================

  Future<List<analytics.SpendingTrend>> getSpendingTrends({
    int months = 6,
  }) async {
    developer.log('🔐 API Wrapper: Getting spending trends');
    try {
      return await _analyticsService.getSpendingTrends(months: months);
    } catch (e) {
      developer.log('❌ API Wrapper: Get spending trends error: $e');
      return [];
    }
  }

  Future<analytics.Forecast?> getForecast() async {
    developer.log('🔐 API Wrapper: Getting forecast');
    try {
      return await _analyticsService.getForecast();
    } catch (e) {
      developer.log('❌ API Wrapper: Get forecast error: $e');
      return null;
    }
  }

  Future<List<analytics.TopCategory>> getTopCategories() async {
    developer.log('🔐 API Wrapper: Getting top categories');
    try {
      return await _analyticsService.getTopCategories();
    } catch (e) {
      developer.log('❌ API Wrapper: Get top categories error: $e');
      return [];
    }
  }

  Future<analytics.HealthScore?> getHealthScore() async {
    developer.log('🔐 API Wrapper: Getting health score');
    try {
      return await _analyticsService.getHealthScore();
    } catch (e) {
      developer.log('❌ API Wrapper: Get health score error: $e');
      return null;
    }
  }

  // ==================== SEARCH METHODS ====================

  Future<List<transaction.Transaction>> searchTransactions({
    required String query,
    double? minAmount,
    double? maxAmount,
    String? category,
    String? type,
  }) async {
    developer.log('🔐 API Wrapper: Searching transactions');
    try {
      return await _transactionService.searchTransactions(
        query: query,
        minAmount: minAmount,
        maxAmount: maxAmount,
        category: category,
        type: type,
      );
    } catch (e) {
      developer.log('❌ API Wrapper: Search transactions error: $e');
      return [];
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
