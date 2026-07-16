import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final void Function(bool) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập email và mật khẩu')));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiService().login(email, password);
      await ApiService.saveAuth(res['token'], res['user']['id']);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onLogin(res['isNewUser'] ?? false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập: $e')));
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() { _isLoading = true; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; });
        return; // user canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw Exception('Không lấy được Google ID Token');

      final res = await ApiService().googleLogin(googleAuth.idToken!);
      await ApiService.saveAuth(res['token'], res['user']['id']);
      if (mounted) {
        setState(() { _isLoading = false; });
        widget.onLogin(res['isNewUser'] ?? false);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập Google: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Top hero
            Padding(
              padding: EdgeInsets.only(top: 80.0, bottom: 40.0, left: 24.0, right: 24.0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    child: Icon(Icons.trending_up, color: Theme.of(context).textTheme.bodyLarge?.color, size: 30),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'FinanceAI',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quản lý tài chính thông minh\nvới trợ lý AI cá nhân hóa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureItem(Icons.bar_chart, 'Theo dõi\nthu chi'),
                      SizedBox(width: 16),
                      _buildFeatureItem(Icons.flag_outlined, 'Mục tiêu\ntài chính'),
                      SizedBox(width: 16),
                      _buildFeatureItem(Icons.smart_toy_outlined, 'Tư vấn\nAI'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào mừng!',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Đăng nhập để bắt đầu quản lý tài chính',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Google button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          minimumSize: Size(double.infinity, 56),
                        ),
                        child: _isLoading 
                          ? SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(),
                                SizedBox(width: 12),
                                Text(
                                  'Tiếp tục với Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                      ),
                      
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Theme.of(context).dividerColor)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'hoặc',
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 13),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: Theme.of(context).dividerColor)),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Inputs
                      _buildTextField(hint: 'Email', controller: _emailController, obscureText: false),
                      SizedBox(height: 12),
                      _buildTextField(hint: 'Mật khẩu', controller: _passwordController, obscureText: true),
                      SizedBox(height: 20),
                      
                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          minimumSize: Size(double.infinity, 56),
                        ),
                        child: Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Đăng ký miễn phí',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterPage(onRegister: widget.onLogin)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required TextEditingController controller, required bool obscureText}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
