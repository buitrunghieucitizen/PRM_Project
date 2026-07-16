import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const WelcomeScreen({super.key, required this.onFinish});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(Duration(seconds: 2));
    if (ApiService.isLoggedIn) {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              ),
              child: Icon(Icons.trending_up, color: Theme.of(context).textTheme.bodyLarge?.color, size: 40),
            ),
            SizedBox(height: 32),
            Text(
              'FinanceAI',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Quản lý tài chính thông minh\nvới trợ lý AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 48),
            if (!ApiService.isLoggedIn) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: widget.onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Bắt đầu ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
