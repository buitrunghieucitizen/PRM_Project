import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _salaryCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();
  final TextEditingController _expensesCtrl = TextEditingController();
  
  final ApiService _api = ApiService();

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _jobCtrl.text.isEmpty || _salaryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng điền Họ tên, Nghề nghiệp và Lương')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      double salary = double.tryParse(_salaryCtrl.text) ?? 0;
      double? goal = _goalCtrl.text.isNotEmpty ? double.tryParse(_goalCtrl.text) : null;
      
      await _api.onboardUser(
        fullName: _nameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        jobTitle: _jobCtrl.text,
        monthlySalary: salary,
        incomeGoal: goal,
        expensesDescription: _expensesCtrl.text,
      );

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoàn tất hồ sơ', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vài bước nhỏ để AI hỗ trợ bạn tốt nhất!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            SizedBox(height: 24),
            
            _buildField('Họ và tên', _nameCtrl, TextInputType.name),
            SizedBox(height: 16),
            _buildField('Số điện thoại', _phoneCtrl, TextInputType.phone),
            SizedBox(height: 16),
            _buildField('Nghề nghiệp', _jobCtrl, TextInputType.text),
            SizedBox(height: 16),
            _buildField('Lương hàng tháng (VNĐ)', _salaryCtrl, TextInputType.number),
            SizedBox(height: 16),
            _buildField('Mục tiêu thu nhập (VNĐ) - Tùy chọn', _goalCtrl, TextInputType.number),
            SizedBox(height: 16),
            
            Text('Chi tiêu hàng tháng của bạn như thế nào?', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
            SizedBox(height: 8),
            TextField(
              controller: _expensesCtrl,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Tôi thường tiêu 3 triệu tiền ăn, 2 triệu tiền nhà, và tiết kiệm 1 triệu...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading 
                ? CircularProgressIndicator(color: Theme.of(context).scaffoldBackgroundColor)
                : Text('Bắt đầu sử dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
