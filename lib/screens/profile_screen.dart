import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _salaryCtrl = TextEditingController();

  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _jobCtrl.dispose();
    _salaryCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _apiService.getUser(ApiService.currentUserId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _initials {
    if (_user == null) return 'U';
    final name = _user!.fullName?.isNotEmpty == true ? _user!.fullName! : _user!.username;
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  String get _displayName {
    if (_isLoading) return 'Đang tải...';
    if (_user == null) return 'Người dùng';
    return _user!.fullName?.isNotEmpty == true ? _user!.fullName! : _user!.username;
  }

  void _showEditProfile() {
    if (_user == null) return;
    _nameCtrl.text = _user!.fullName ?? '';
    _phoneCtrl.text = _user!.phoneNumber ?? '';
    _jobCtrl.text = _user!.jobTitle ?? '';
    _salaryCtrl.text = _user!.monthlySalary?.toStringAsFixed(0) ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Thông tin cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                TextField(
                  controller: _phoneCtrl,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                TextField(
                  controller: _jobCtrl,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Nghề nghiệp',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                TextField(
                  controller: _salaryCtrl,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Thu nhập hàng tháng (VND)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _nameCtrl.text.trim();
                final phone = _phoneCtrl.text.trim();
                final job = _jobCtrl.text.trim();
                final salary = double.tryParse(_salaryCtrl.text.trim());
                if (newName.isNotEmpty) {
                  bool success = await _apiService.updateUser(ApiService.currentUserId, newName, phone, job, salary);
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                    _loadUser(); // refresh
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật!')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePassword() {
    _oldPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu cũ',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPass = _oldPassCtrl.text;
                final newPass = _newPassCtrl.text;
                final confirmPass = _confirmPassCtrl.text;

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới không khớp!')));
                  return;
                }
                if (oldPass.isEmpty || newPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
                  return;
                }

                try {
                  bool success = await _apiService.changePassword(ApiService.currentUserId, oldPass, newPass);
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu cũ không đúng hoặc có lỗi!')));
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor),
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24),
            color: Theme.of(context).primaryColor,
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_initials, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 16),
                Text(_displayName, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: _showEditProfile,
                          leading: Icon(Icons.person_outline, color: Theme.of(context).textTheme.bodyLarge?.color),
                          title: Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          onTap: _showChangePassword,
                          leading: Icon(Icons.lock_outline, color: Theme.of(context).textTheme.bodyLarge?.color),
                          title: Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: Icon(Icons.dark_mode_outlined, color: Theme.of(context).textTheme.bodyLarge?.color),
                          title: Text('Giao diện Tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            activeThumbColor: Theme.of(context).primaryColor,
                            onChanged: (val) {
                              themeProvider.toggleTheme(val);
                            },
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: Icon(Icons.numbers, color: Theme.of(context).textTheme.bodyLarge?.color),
                          title: Text('Hiển thị số tiền cụ thể', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          subtitle: Text('Tắt M, K (ví dụ: hiển thị 1.000.000 thay vì 1M)', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 12)),
                          trailing: Switch(
                            value: themeProvider.showDetailedAmount,
                            activeThumbColor: Theme.of(context).primaryColor,
                            onChanged: (val) {
                              themeProvider.toggleDetailedAmount(val);
                            },
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          onTap: () async {
                            await ApiService.logout();
                            widget.onLogout();
                          },
                          leading: Icon(Icons.logout, color: Theme.of(context).textTheme.bodyLarge?.color),
                          title: Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
