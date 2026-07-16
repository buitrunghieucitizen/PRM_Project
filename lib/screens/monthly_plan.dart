import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MonthlyPlanScreen extends StatefulWidget {
  const MonthlyPlanScreen({super.key});

  @override
  State<MonthlyPlanScreen> createState() => _MonthlyPlanScreenState();
}

class _MonthlyPlanScreenState extends State<MonthlyPlanScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<MonthlyPlan> _plans = [];
  Map<String, double> _categorySpent = {};
  
  // Lưu lịch sử chat AI để không mất khi đóng popup
  final List<Map<String, dynamic>> _aiMessages = [];
  bool _showAIChat = false;

  bool _showAdd = false;
  MonthlyPlan? _editingPlan;
  
  String _addCategory = 'Ăn uống';
  final TextEditingController _addAmountController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

  @override
  void dispose() {
    _addAmountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  Set<String> _customCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _apiService.getPlans(ApiService.currentUserId, month: _selectedMonth, year: _selectedYear);
      final txs = await _apiService.getTransactions(ApiService.currentUserId);
      
      Map<String, double> spent = {};
      Set<String> customCats = {};
      for (var t in txs) {
        if (t.type.toLowerCase() == 'expense') {
          customCats.add(t.category);
          if (t.transactionDate.month == _selectedMonth && t.transactionDate.year == _selectedYear) {
            String catLower = t.category.toLowerCase();
            spent[catLower] = (spent[catLower] ?? 0) + t.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _plans = plans;
          _categorySpent = spent;
          _customCategories = customCats;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _fmt(double n) {
    bool showDetailed = Provider.of<ThemeProvider>(context).showDetailedAmount;
    if (!showDetailed) {
      if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
      if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
      if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    }
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _openAddModal([MonthlyPlan? p]) {
    setState(() {
      _editingPlan = p;
      if (p != null) {
        _addCategory = p.category;
        _addAmountController.text = p.plannedAmount.toStringAsFixed(0);
      } else {
        _addCategory = 'Ăn uống';
        _addAmountController.clear();
      }
      _showAdd = true;
      if (_addCategory == 'Khác') {
        _customCategoryController.text = '';
      }
    });
  }

  Future<void> _deletePlan(MonthlyPlan p) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Xác nhận xóa', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Bạn có chắc chắn muốn xóa kế hoạch này?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm == true) {
      try {
        await _apiService.deletePlan(p.id);
        if (mounted) setState(() => _showAdd = false);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  Future<void> _savePlan() async {
    final amt = double.tryParse(_addAmountController.text) ?? 0;
    if (amt <= 0) return;

    setState(() => _showAdd = false);
    
    String finalCategory = _addCategory;
    if (_addCategory == 'Khác') {
      if (_customCategoryController.text.trim().isNotEmpty) {
        finalCategory = _customCategoryController.text.trim();
      }
    }

    try {
      if (_editingPlan != null) {
        final updated = MonthlyPlan(
          id: _editingPlan!.id,
          userId: ApiService.currentUserId,
          month: _selectedMonth,
          year: _selectedYear,
          category: finalCategory,
          plannedAmount: amt,
        );
        await _apiService.updatePlan(updated);
      } else {
        final newPlan = MonthlyPlan(
          id: 0,
          userId: ApiService.currentUserId,
          month: _selectedMonth,
          year: _selectedYear,
          category: finalCategory,
          plannedAmount: amt,
        );
        await _apiService.addPlan(newPlan);
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth--;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth++;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    double totalBudget = 0;
    double totalSpent = 0;
    for (var p in _plans) {
      totalBudget += p.plannedAmount;
      totalSpent += _categorySpent[p.category.toLowerCase()] ?? 0;
    }
    double totalPct = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0;

    return Stack(
      children: [
        Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                color: theme.primaryColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kế hoạch chi tiêu', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Quản lý ngân sách', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _openAddModal(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.add, color: theme.primaryColor, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Month selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _prevMonth,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.chevron_left, color: theme.scaffoldBackgroundColor, size: 20),
                          ),
                        ),
                        Text('Tháng $_selectedMonth, $_selectedYear', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 15, fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: _nextMonth,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.chevron_right, color: theme.scaffoldBackgroundColor, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Overall progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Đã tiêu', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 12)),
                              Text('Ngân sách', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_fmt(totalSpent)} ₫', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('${_fmt(totalBudget)} ₫', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: totalPct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : _plans.isEmpty
                        ? Center(child: Text('Chưa có ngân sách nào cho tháng này', style: TextStyle(color: theme.textTheme.bodySmall?.color)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) {
                              var p = _plans[index];
                              double spent = _categorySpent[p.category.toLowerCase()] ?? 0;
                              double pct = p.plannedAmount > 0 ? (spent / p.plannedAmount) : 0;
                              bool isOver = spent > p.plannedAmount;
                              return InkWell(
                                onTap: () => _openAddModal(p),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isOver ? Colors.red.withValues(alpha: 0.3) : theme.dividerColor, width: isOver ? 1.5 : 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10)),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.category_outlined, color: theme.primaryColor, size: 16),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(p.category, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                                            ],
                                          ),
                                          if (isOver)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                              child: const Text('Vượt ngân sách', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${_fmt(spent)} ₫', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 15)),
                                          Text('${_fmt(p.plannedAmount)} ₫', style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(3)),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: pct.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(color: isOver ? Colors.red : theme.primaryColor, borderRadius: BorderRadius.circular(3)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),

        // AI Chat Panel (nửa dưới màn hình)
        if (_showAIChat)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.33,
            child: _AIPanel(
              userId: ApiService.currentUserId,
              onApplied: () => _loadData(),
              messages: _aiMessages,
              onClose: () => setState(() => _showAIChat = false),
            ),
          ),

        // AI Advisor Toggle Button
        Positioned(
          bottom: _showAIChat ? MediaQuery.of(context).size.height * 0.33 + 8 : 24,
          right: 20,
          child: GestureDetector(
            onTap: () => setState(() => _showAIChat = !_showAIChat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _showAIChat
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_showAIChat ? Colors.red : theme.primaryColor).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _showAIChat ? Icons.close : Icons.auto_awesome,
                  key: ValueKey(_showAIChat),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),

        // Add Modal
        if (_showAdd) _buildAddModal(theme),
      ],
    );
  }

  Widget _buildAddModal(ThemeData theme) {
    bool isEditing = _editingPlan != null;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Sửa ngân sách' : 'Thêm ngân sách', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 16)),
                  Row(
                    children: [
                      if (isEditing)
                        GestureDetector(
                          onTap: () => _deletePlan(_editingPlan!),
                          child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                        ),
                      if (isEditing) const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _showAdd = false),
                        child: Icon(Icons.close, color: theme.textTheme.bodySmall?.color, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _addCategory,
                dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                ),
                items: (() {
                  List<String> list = ['Ăn uống', 'Di chuyển', 'Mua sắm', 'Hóa đơn', 'Giải trí', 'Sức khỏe'];
                  for (var p in _plans) {
                    _customCategories.add(p.category);
                  }
                  for (var cat in _customCategories) {
                    if (!list.contains(cat) && cat != 'Khác') {
                      list.add(cat);
                    }
                  }
                  list.add('Khác');
                  if (!list.contains(_addCategory)) list = [...list, _addCategory];
                  return list;
                }()).map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _addCategory = val);
                },
              ),
              if (_addCategory == 'Khác') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customCategoryController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên danh mục...',
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _addAmountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0 ₫',
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 24, fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_editingPlan != null) {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Xác nhận thay đổi'),
                        content: const Text('Bạn có chắc chắn muốn lưu các thay đổi này?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(c);
                              _savePlan();
                            },
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _savePlan();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm ngân sách', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Bottom Panel ─────────────────────────────────────────────────────────

class _AIPanel extends StatefulWidget {
  final int userId;
  final VoidCallback onApplied;
  final VoidCallback onClose;
  final List<Map<String, dynamic>> messages;
  const _AIPanel({required this.userId, required this.onApplied, required this.onClose, required this.messages});

  @override
  State<_AIPanel> createState() => _AIPanelState();
}

class _AIPanelState extends State<_AIPanel> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> get _messages => widget.messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_messages.isNotEmpty) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String query = _controller.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      AIAdvice advice = await _apiService.consultAI(widget.userId, query);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'advice': advice});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'error': 'Lỗi kết nối AI: $e'});
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyAdvice(AIAdvice advice) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Xác nhận áp dụng', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          'Bạn có chắc chắn muốn áp dụng các đề xuất từ AI?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      bool success = await _apiService.applyAIAdvice(advice.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã áp dụng thành công!')));
        setState(() {
          advice.isApplied = true;
        });
        widget.onApplied();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Tư vấn', style: TextStyle(color: theme.scaffoldBackgroundColor, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Hỏi về tài chính của bạn', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 10)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Messages ──
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: theme.primaryColor.withValues(alpha: 0.3), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Hãy hỏi AI về kế hoạch\nchi tiêu của bạn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      bool isUser = msg['sender'] == 'user';

                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, left: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(14).copyWith(bottomRight: const Radius.circular(4)),
                            ),
                            child: Text(msg['text'], style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 13)),
                          ),
                        );
                      } else {
                        if (msg.containsKey('error')) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8, right: 40),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14).copyWith(bottomLeft: const Radius.circular(4)),
                              ),
                              child: Text(msg['error'], style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                            ),
                          );
                        }

                        AIAdvice advice = msg['advice'];
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, right: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14).copyWith(bottomLeft: const Radius.circular(4)),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(advice.aiResponse, style: TextStyle(color: theme.textTheme.bodyLarge?.color, height: 1.5, fontSize: 13)),
                                if (!advice.isApplied) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _applyAdvice(advice),
                                      icon: const Icon(Icons.check_circle_outline, size: 14),
                                      label: const Text('Áp dụng', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: theme.scaffoldBackgroundColor,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: theme.primaryColor, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Đã áp dụng', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),

          // ── Loading indicator ──
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 2),
              ),
            ),

          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: theme.scaffoldBackgroundColor, size: 16),
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
