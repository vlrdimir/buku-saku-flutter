import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/transaction_page.dart';
import 'pages/budget_page.dart';
import 'pages/goals_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const FinancialApp());
}

class FinancialApp extends StatelessWidget {
  const FinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatatan Keuangan Harian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Define routes for navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const MainNavigation(),
      },
      // Use AuthWrapper to determine initial screen
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthServiceNew _authService = AuthServiceNew();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check if user has a valid token
    final hasAuth = await _authService.hasStoredAuth();
    if (mounted) {
      setState(() {
        _isAuthenticated = hasAuth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirect to MainNavigation if authenticated, otherwise LoginPage
    return _isAuthenticated ? const MainNavigation() : const LoginPage();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const TransactionPage(),
    const BudgetPage(),
    const GoalsPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: hide labels on very small screens
          final isCompact = constraints.maxWidth < 380;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blue[700],
                unselectedItemColor: Colors.grey[500],
                backgroundColor: Colors.white,
                elevation: 0,
                selectedFontSize: isCompact ? 0 : 10,
                unselectedFontSize: isCompact ? 0 : 10,
                showSelectedLabels: !isCompact,
                showUnselectedLabels: !isCompact,
                iconSize: isCompact ? 26 : 24,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    activeIcon: const Icon(Icons.dashboard),
                    label: 'Home',
                    tooltip: isCompact ? 'Dashboard' : null,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.swap_horiz_outlined),
                    activeIcon: const Icon(Icons.swap_horiz),
                    label: 'Transaksi',
                    tooltip: isCompact ? 'Transaksi' : null,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    activeIcon: const Icon(Icons.account_balance_wallet),
                    label: 'Anggaran',
                    tooltip: isCompact ? 'Anggaran' : null,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.flag_outlined),
                    activeIcon: const Icon(Icons.flag),
                    label: 'Target',
                    tooltip: isCompact ? 'Target' : null,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart_outlined),
                    activeIcon: const Icon(Icons.bar_chart),
                    label: 'Laporan',
                    tooltip: isCompact ? 'Laporan' : null,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined),
                    activeIcon: const Icon(Icons.settings),
                    label: 'Setting',
                    tooltip: isCompact ? 'Pengaturan' : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // FAB removed - each page handles its own FAB
    );
  }
}
