import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'ai_advisor.dart';

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
  
  bool _showAdd = false;
  MonthlyPlan? _editingPlan;
  
  String _addCategory = 'Ăn uống';
  final TextEditingController _addAmountController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

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
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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

        // AI Advisor Button
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AIAdvisor(userId: ApiService.currentUserId))).then((_) {
                _loadData(); // Refresh if AI applied something
              });
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
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
                value: _addCategory,
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
                onPressed: _savePlan,
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
