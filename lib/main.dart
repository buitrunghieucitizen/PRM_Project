import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_page.dart';
import 'screens/dashboard.dart';
import 'screens/journal.dart';
import 'screens/monthly_plan.dart';
import 'screens/reports.dart';
import 'screens/goals.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav.dart';
import 'services/api_service.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FinanceAI',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AppContainer(),
          );
        },
      ),
    );
  }
}

class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  late bool _loggedIn;
  String _screen = 'dashboard';
  bool _isOnboarding = false;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _loggedIn = ApiService.isLoggedIn;
  }

  void _setLoggedIn(bool isNewUser) {
    setState(() {
      _loggedIn = true;
      if (isNewUser) {
        _isOnboarding = true;
      } else {
        _isOnboarding = false;
        _screen = 'dashboard';
      }
    });
  }
  
  void _setLoggedOut() {
    setState(() {
      _loggedIn = false;
      _isOnboarding = false;
      _screen = 'dashboard';
    });
  }

  void _setScreen(String screen) {
    setState(() {
      _screen = screen;
    });
  }

  Widget _buildScreen() {
    if (_isOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _isOnboarding = false;
            _screen = 'dashboard';
          });
        }
      );
    }

    switch (_screen) {
      case 'dashboard':
        return Dashboard(onNavigate: _setScreen);
      case 'journal':
        return const Journal();
      case 'plan':
        return MonthlyPlanScreen();
      case 'reports':
        return Reports();
      case 'goals':
        return const GoalsScreen();
      case 'profile':
        return ProfileScreen(onLogout: _setLoggedOut);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return Scaffold(
        body: WelcomeScreen(
          onFinish: () {
            setState(() {
              _showWelcome = false;
              _loggedIn = ApiService.isLoggedIn;
            });
          },
        ),
      );
    }

    if (!_loggedIn) {
      return Scaffold(
        body: LoginPage(
          onLogin: _setLoggedIn,
        ),
      );
    }

    if (_isOnboarding) {
      return Scaffold(
        body: _buildScreen(),
      );
    }

    Color statusBarBg = Theme.of(context).scaffoldBackgroundColor;

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

