import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/login_page.dart';
import 'screens/dashboard.dart';
import 'screens/journal.dart';
import 'screens/monthly_plan.dart';
import 'screens/reports.dart';
import 'screens/goals.dart';
import 'widgets/bottom_nav.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const AppContainer(),
    );
  }
}

class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  bool _loggedIn = false;
  String _screen = 'dashboard';

  void _setLoggedIn(bool value) {
    setState(() {
      _loggedIn = value;
    });
  }

  void _setScreen(String screen) {
    setState(() {
      _screen = screen;
    });
  }

  Widget _buildScreen() {
    switch (_screen) {
      case 'dashboard':
        return Dashboard(onNavigate: _setScreen);
      case 'journal':
        return const Journal();
      case 'plan':
        return const MonthlyPlanScreen();
      case 'reports':
        return const Reports();
      case 'goals':
        return const GoalsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Scaffold(
        body: LoginPage(
          onLogin: () => _setLoggedIn(true),
        ),
      );
    }

    // In a real device, the status bar is handled by the system.
    // We don't need to manually draw the iOS status bar (time, battery) unless we want to simulate a phone frame.
    // Since this is a real Flutter app, we will use a Scaffold with BottomNavigationBar.
    // However, since we built a custom BottomNav to match the UI precisely, we'll use a Column or Stack.

    Color statusBarBg = (_screen == 'dashboard' || _screen == 'journal' || _screen == 'plan' || _screen == 'reports' || _screen == 'goals')
        ? const Color(0xFF0F172A)
        : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: statusBarBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: _buildScreen(),
              ),
            ),
            BottomNav(
              active: _screen,
              onNavigate: _setScreen,
            ),
          ],
        ),
      ),
    );
  }
}
