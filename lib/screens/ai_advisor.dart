import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AIAdvisor extends StatefulWidget {
  final int userId;
  const AIAdvisor({super.key, required this.userId});

  @override
  State<AIAdvisor> createState() => _AIAdvisorState();
}

class _AIAdvisorState extends State<AIAdvisor> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _hasApplied = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    String query = _controller.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _isLoading = true;
      _controller.clear();
    });

    try {
      AIAdvice advice = await _apiService.consultAI(widget.userId, query);
      setState(() {
        _messages.add({'sender': 'ai', 'advice': advice});
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'error': 'Lỗi kết nối AI: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyAdvice(AIAdvice advice) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Xác nhận áp dụng', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Bạn có chắc chắn muốn áp dụng các đề xuất từ AI? Thao tác này có thể sửa đổi hoặc thêm mới dữ liệu của bạn.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor),
            child: Text('Áp dụng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      bool success = await _apiService.applyAIAdvice(advice.id);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã áp dụng thành công!')));
        setState(() {
          _hasApplied = true;
          advice.isApplied = true; // prevent re-apply
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasApplied);
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text('AI Tư vấn Tài chính', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Theme.of(context).scaffoldBackgroundColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';
                
                if (isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12).copyWith(bottomRight: Radius.circular(4)),
                      ),
                      child: Text(msg['text'], style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor)),
                    ),
                  );
                } else {
                  if (msg.containsKey('error')) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12).copyWith(bottomLeft: Radius.circular(4)),
                        ),
                        child: Text(msg['error'], style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                    );
                  }

                  AIAdvice advice = msg['advice'];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12).copyWith(bottomLeft: Radius.circular(4)),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(advice.aiResponse, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.5)),
                            if (!advice.isApplied) ...[
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _applyAdvice(advice),
                                icon: Icon(Icons.check_circle_outline, size: 18),
                                label: Text('Áp dụng Đề xuất'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              )
                            ] else ...[
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Theme.of(context).textTheme.bodyLarge?.color, size: 18),
                                  SizedBox(width: 8),
                                  Text('Đã áp dụng', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ]
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          if (_isLoading)
            Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Theme.of(context).scaffoldBackgroundColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
