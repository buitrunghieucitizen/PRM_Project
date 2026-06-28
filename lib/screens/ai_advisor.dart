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
        title: const Text('Xác nhận áp dụng'),
        content: const Text('Bạn có chắc chắn muốn áp dụng các đề xuất từ AI? Thao tác này có thể sửa đổi hoặc thêm mới dữ liệu của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      bool success = await _apiService.applyAIAdvice(advice.id);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã áp dụng thành công!')));
        Navigator.pop(context, true); // Return true to signal a refresh is needed
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tư vấn Tài chính', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';
                
                if (isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
                      ),
                      child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                    ),
                  );
                } else {
                  if (msg.containsKey('error')) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
                        ),
                        child: Text(msg['error'], style: const TextStyle(color: Color(0xFFF43F5E))),
                      ),
                    );
                  }

                  AIAdvice advice = msg['advice'];
                  bool hasActions = advice.proposedActionsJson != null && advice.proposedActionsJson!.isNotEmpty;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(advice.aiResponse, style: const TextStyle(color: Color(0xFF334155), height: 1.5)),
                          if (hasActions) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _applyAdvice(advice),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Áp dụng Đề xuất'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
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
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
