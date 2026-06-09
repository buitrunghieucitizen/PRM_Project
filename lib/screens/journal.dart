import 'package:flutter/material.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  String _tab = 'all';
  String _search = '';
  bool _showAI = false;
  bool _showAdd = false;
  String _addType = 'expense';
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final List<Map<String, dynamic>> _transactions = [
    {'id': 1, 'desc': 'Lương tháng 6', 'amount': 38000000.0, 'type': 'income', 'cat': 'Thu nhập', 'date': '01/06', 'emoji': '💼'},
    {'id': 2, 'desc': 'Siêu thị Vinmart', 'amount': 420000.0, 'type': 'expense', 'cat': 'Ăn uống', 'date': '02/06', 'emoji': '🛒'},
    {'id': 3, 'desc': 'Grab xe', 'amount': 85000.0, 'type': 'expense', 'cat': 'Di chuyển', 'date': '03/06', 'emoji': '🚗'},
    {'id': 4, 'desc': 'Netflix Premium', 'amount': 260000.0, 'type': 'expense', 'cat': 'Giải trí', 'date': '03/06', 'emoji': '🎬'},
    {'id': 5, 'desc': 'Thưởng dự án Q2', 'amount': 5000000.0, 'type': 'income', 'cat': 'Thưởng', 'date': '05/06', 'emoji': '🎁'},
    {'id': 6, 'desc': 'Tiền điện EVN', 'amount': 680000.0, 'type': 'expense', 'cat': 'Hóa đơn', 'date': '06/06', 'emoji': '💡'},
    {'id': 7, 'desc': 'Bách hóa xanh', 'amount': 320000.0, 'type': 'expense', 'cat': 'Ăn uống', 'date': '07/06', 'emoji': '🛒'},
    {'id': 8, 'desc': 'Shopee mua sắm', 'amount': 850000.0, 'type': 'expense', 'cat': 'Mua sắm', 'date': '08/06', 'emoji': '🛍️'},
  ];

  List<Map<String, dynamic>> _aiMessages = [
    {'role': 'assistant', 'text': 'Xin chào! 👋 Tôi có thể phân tích chi tiêu và tư vấn kế hoạch tài chính cho bạn.'},
    {'role': 'assistant', 'text': '📊 Tháng này bạn chi 28.8% cho ăn uống. Gợi ý: nấu ăn tại nhà 3 ngày/tuần → tiết kiệm ~1.9M ₫/tháng.'},
  ];

  bool _thinking = false;

  String _fmt(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  void _handleSend() {
    String text = _chatController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _aiMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _thinking = true;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final List<String> r = [
        "Phân tích: Chi tiêu ăn uống chiếm 29%, cao hơn mức lý tưởng 20%. Thử meal-prep cuối tuần để tiết kiệm 800K/tháng.",
        "Với tỷ lệ tiết kiệm hiện tại 50%, bạn đang làm rất tốt! Duy trì và đặt auto-transfer vào đầu tháng.",
        "Danh mục mua sắm vượt 28%. Áp dụng quy tắc 24h chờ đợi trước mỗi lần mua để tránh chi tiêu bốc đồng.",
      ];
      setState(() {
        _aiMessages.add({'role': 'assistant', 'text': r[DateTime.now().millisecond % r.length]});
        _thinking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _transactions.where((t) {
      if (_tab == 'income' && t['type'] != 'income') return false;
      if (_tab == 'expense' && t['type'] != 'expense') return false;
      if (_search.isNotEmpty && !(t['desc'] as String).toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();

    return Stack(
      children: [
        Container(
          color: const Color(0xFFF0F4F8),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                color: const Color(0xFF0F172A),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Nhật ký Thu / Chi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Tháng 6, 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showAI = true),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.auto_awesome, color: Color(0xFF2DD4BF), size: 17),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _showAdd = true),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryPill('Thu', '43.0M', const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.15)),
                        const SizedBox(width: 8),
                        _buildSummaryPill('Chi', '21.5M', const Color(0xFFF43F5E), const Color(0xFFF43F5E).withOpacity(0.15)),
                        const SizedBox(width: 8),
                        _buildSummaryPill('Còn', '21.4M', const Color(0xFF2DD4BF), const Color(0xFF0D9488).withOpacity(0.15)),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs + Search
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton('all', 'Tất cả'),
                          _buildTabButton('income', 'Thu nhập'),
                          _buildTabButton('expense', 'Chi tiêu'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _search = v),
                              decoration: const InputDecoration(
                                hintText: 'Tìm giao dịch...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
                      itemBuilder: (context, index) {
                        final t = filtered[index];
                        bool isIncome = t['type'] == 'income';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(t['emoji'] as String, style: const TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['desc'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('${t['cat']} · ${t['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? "+" : "-"}${_fmt(t['amount'] as double)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                  fontFamily: 'DM Mono',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // AI Drawer
        if (_showAI) _buildAIDrawer(),
        
        // Add Modal
        if (_showAdd) _buildAddModal(),
      ],
    );
  }

  Widget _buildSummaryPill(String label, String val, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
            Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'DM Mono')),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label) {
    bool active = _tab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIDrawer() {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Trợ lý AI Tài chính', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                        Text('● Đang hoạt động', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showAI = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _aiMessages.length + (_thinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _aiMessages.length && _thinking) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 36),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('...', style: TextStyle(color: Color(0xFF374151), fontSize: 14, letterSpacing: 2)),
                          ),
                        ],
                      ),
                    );
                  }
                  final m = _aiMessages[index];
                  bool isUser = m['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.smart_toy, color: Colors.white, size: 13),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              m['text'] as String,
                              style: TextStyle(color: isUser ? Colors.white : const Color(0xFF374151), fontSize: 14, height: 1.4),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 36),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Phân tích tháng này', 'Tiết kiệm hơn', 'Chi nhiều nhất'].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _chatController.text = s;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              border: Border.all(color: const Color(0xFFCCFBF1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(s, style: const TextStyle(color: Color(0xFF0D9488), fontSize: 12)),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Nhập câu hỏi...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.send, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm giao dịch', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16)),
                  GestureDetector(
                    onTap: () => setState(() => _showAdd = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildAddTypeButton('expense', 'Chi tiêu', const Color(0xFFF43F5E)),
                    _buildAddTypeButton('income', 'Thu nhập', const Color(0xFF10B981)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildAddTextField('Mô tả giao dịch'),
              const SizedBox(height: 12),
              _buildAddTextField('Số tiền (VND)', isNumber: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: 'Ăn uống',
                    items: ['Ăn uống', 'Di chuyển', 'Giải trí', 'Mua sắm', 'Hóa đơn', 'Sức khỏe', 'Thu nhập', 'Thưởng']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) {},
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _showAdd = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _addType == 'income' ? const Color(0xFF10B981) : const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Lưu giao dịch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTypeButton(String type, String label, Color activeColor) {
    bool active = _addType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _addType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTextField(String hint, {bool isNumber = false}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
        ),
      ),
      style: TextStyle(
        fontFamily: isNumber ? 'DM Mono' : null,
      ),
    );
  }
}
