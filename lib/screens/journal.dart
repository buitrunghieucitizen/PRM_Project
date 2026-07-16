import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  String _tab = 'all';
  String _search = '';
  bool _showAdd = false;
  String _addType = 'expense';
  Transaction? _editingTx;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addNoteController = TextEditingController();
  final TextEditingController _addAmountController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  String _addCategory = 'Ăn uống';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  List<MonthlyPlan> _plans = [];
  List<Goal> _goals = [];
  int? _addGoalId;

  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getTransactions(ApiService.currentUserId),
        _apiService.getPlans(ApiService.currentUserId),
        _apiService.getGoals(ApiService.currentUserId),
      ]);
      
      final txs = results[0] as List<Transaction>;
      final plans = results[1] as List<MonthlyPlan>;
      final goals = results[2] as List<Goal>;
      
      double inc = 0;
      double exp = 0;
      final now = DateTime.now();
      
      for (var t in txs) {
        if (t.transactionDate.month == now.month && t.transactionDate.year == now.year) {
          if (t.type.toLowerCase() == 'income') {
            inc += t.amount;
          } else {
            exp += t.amount;
          }
        }
      }
      
      // Sort by date descending
      txs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      if (mounted) {
        setState(() {
          _transactions = txs;
          _plans = plans;
          _goals = goals;
          _totalIncome = inc;
          _totalExpense = exp;
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
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  void _openAddModal([Transaction? t]) {
    setState(() {
      _editingTx = t;
      if (t != null) {
        _addType = t.type.toLowerCase() == 'income' ? 'income' : 'expense';
        _addNoteController.text = t.note ?? '';
        _addAmountController.text = t.amount.toStringAsFixed(0);
        _addCategory = t.category;
        _addGoalId = t.goalId;
      } else {
        _addType = 'expense';
        _addNoteController.clear();
        _addAmountController.clear();
        _addCategory = 'Ăn uống';
        _addGoalId = null;
      }
      _showAdd = true;
      if (_addCategory == 'Khác') {
        _customCategoryController.text = '';
      }
    });
  }

  Future<void> _deleteTx(Transaction t) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Xác nhận xóa', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Bạn có chắc chắn muốn xóa giao dịch này?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm == true) {
      try {
        await _apiService.deleteTransaction(t.id);
        if (mounted) setState(() => _showAdd = false);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  Future<void> _saveTransaction() async {
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
      final now = DateTime.now();
      
      if (_editingTx != null) {
        // Edit existing
        final updatedTx = Transaction(
          id: _editingTx!.id,
          userId: ApiService.currentUserId,
          amount: amt,
          type: _addType == 'income' ? 'Income' : 'Expense',
          category: finalCategory,
          note: _addNoteController.text,
          transactionDate: _editingTx!.transactionDate,
          goalId: _addGoalId,
        );
        await _apiService.updateTransaction(updatedTx);
      } else {
        // Check for aggregation
        Transaction? existingTx;
        for (var t in _transactions) {
          if (t.type.toLowerCase() == _addType && 
              t.category == finalCategory && 
              t.transactionDate.year == now.year &&
              t.transactionDate.month == now.month &&
              t.transactionDate.day == now.day) {
            existingTx = t;
            break;
          }
        }

        if (existingTx != null) {
          // Aggregate
          final updatedTx = Transaction(
            id: existingTx.id,
            userId: ApiService.currentUserId,
            amount: existingTx.amount + amt,
            type: existingTx.type,
            category: existingTx.category,
            note: existingTx.note,
            transactionDate: existingTx.transactionDate,
            goalId: _addGoalId ?? existingTx.goalId,
          );
          await _apiService.updateTransaction(updatedTx);
        } else {
          // Add new
          final newTx = Transaction(
            id: 0,
            userId: ApiService.currentUserId,
            amount: amt,
            type: _addType == 'income' ? 'Income' : 'Expense',
            category: finalCategory,
            note: _addNoteController.text,
            transactionDate: now,
            goalId: _addGoalId,
          );
          await _apiService.addTransaction(newTx);
        }
      }

      // Budget checking if expense
      if (_addType == 'expense' && mounted) {
        final plan = _plans.where((p) => p.category == _addCategory && p.month == now.month && p.year == now.year).firstOrNull;
        if (plan != null && plan.plannedAmount > 0) {
          double spentSoFar = 0;
          for (var t in _transactions) {
            if (t.type.toLowerCase() == 'expense' && t.category == _addCategory && 
                t.transactionDate.month == now.month && t.transactionDate.year == now.year &&
                (_editingTx == null || t.id != _editingTx!.id)) {
              spentSoFar += t.amount;
            }
          }
          spentSoFar += amt; // Add current operation's amount
          
          if (spentSoFar >= plan.plannedAmount) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('🚨 Bạn đã vượt quá ngân sách kế hoạch cho danh mục này!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ));
          } else if (spentSoFar >= plan.plannedAmount * 0.9) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('⚠️ Cảnh báo: Bạn sắp tiêu hết ngân sách danh mục này!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filter
    List<Transaction> filtered = _transactions.where((t) {
      if (_tab == 'income' && t.type.toLowerCase() != 'income') return false;
      if (_tab == 'expense' && t.type.toLowerCase() != 'expense') return false;
      if (_search.isNotEmpty) {
        if (!t.note!.toLowerCase().contains(_search.toLowerCase()) &&
            !t.category.toLowerCase().contains(_search.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Group by Date
    Map<String, List<Transaction>> grouped = {};
    for (var t in filtered) {
      String d = '${t.transactionDate.day.toString().padLeft(2, '0')}/${t.transactionDate.month.toString().padLeft(2, '0')}/${t.transactionDate.year}';
      if (!grouped.containsKey(d)) grouped[d] = [];
      grouped[d]!.add(t);
    }

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
                            Text('Nhật ký giao dịch', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Quản lý dòng tiền', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 12)),
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
                    
                    // Search & Tabs
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm giao dịch...',
                          hintStyle: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTab('Tất cả', 'all', theme),
                        const SizedBox(width: 8),
                        _buildTab('Tiền vào', 'income', theme),
                        const SizedBox(width: 8),
                        _buildTab('Tiền ra', 'expense', theme),
                      ],
                    ),
                  ],
                ),
              ),

              // Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: theme.cardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng thu tháng này', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(height: 2),
                        Text('+${_fmt(_totalIncome)} ₫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.primaryColor)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tổng chi tháng này', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(height: 2),
                        Text('-${_fmt(_totalExpense)} ₫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),

              // List
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : grouped.isEmpty
                        ? Center(child: Text('Không có giao dịch nào', style: TextStyle(color: theme.textTheme.bodySmall?.color)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              String date = grouped.keys.elementAt(index);
                              List<Transaction> dayTxs = grouped[date]!;
                              return _buildDayGroup(date, dayTxs, theme);
                            },
                          ),
              ),
            ],
          ),
        ),

        // Add Modal
        if (_showAdd) _buildAddModal(theme),
      ],
    );
  }

  Widget _buildTab(String label, String val, ThemeData theme) {
    bool active = _tab == val;
    return GestureDetector(
      onTap: () => setState(() => _tab = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.transparent : theme.scaffoldBackgroundColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? theme.primaryColor : theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDayGroup(String date, List<Transaction> txs, ThemeData theme) {
    double totalDayInc = 0;
    double totalDayExp = 0;
    for (var t in txs) {
      if (t.type.toLowerCase() == 'income') totalDayInc += t.amount;
      else totalDayExp += t.amount;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodySmall?.color, fontSize: 13)),
              Text(
                (totalDayInc > 0 ? '+${_fmt(totalDayInc)}  ' : '') + (totalDayExp > 0 ? '-${_fmt(totalDayExp)}' : ''),
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: txs.asMap().entries.map((e) {
                int i = e.key;
                Transaction t = e.value;
                bool isIncome = t.type.toLowerCase() == 'income';
                return InkWell(
                  onTap: () => _openAddModal(t),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: i > 0 ? Border(top: BorderSide(color: theme.colorScheme.surface)) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.category, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                              if (t.note?.isNotEmpty == true) ...[
                                const SizedBox(height: 2),
                                Text(t.note!, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? "+" : "-"}${_fmt(t.amount)} ₫',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddModal(ThemeData theme) {
    bool isEditing = _editingTx != null;
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
                  Text(isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch mới', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 16)),
                  Row(
                    children: [
                      if (isEditing)
                        GestureDetector(
                          onTap: () => _deleteTx(_editingTx!),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _addType = 'expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _addType == 'expense' ? theme.primaryColor : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _addType == 'expense' ? Colors.transparent : theme.dividerColor),
                        ),
                        alignment: Alignment.center,
                        child: Text('Tiền ra', style: TextStyle(color: _addType == 'expense' ? theme.scaffoldBackgroundColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _addType = 'income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _addType == 'income' ? theme.primaryColor : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _addType == 'income' ? Colors.transparent : theme.dividerColor),
                        ),
                        alignment: Alignment.center,
                        child: Text('Tiền vào', style: TextStyle(color: _addType == 'income' ? theme.scaffoldBackgroundColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 16),
              
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
                  List<String> list = _addType == 'expense' 
                    ? ['Ăn uống', 'Di chuyển', 'Mua sắm', 'Hóa đơn', 'Giải trí', 'Sức khỏe']
                    : ['Lương', 'Thưởng', 'Đầu tư', 'Quà tặng'];
                  Set<String> customCats = {};
                  for (var t in _transactions) {
                    if (t.type.toLowerCase() == _addType) {
                      customCats.add(t.category);
                    }
                  }
                  if (_addType == 'expense') {
                    for (var p in _plans) {
                      customCats.add(p.category);
                    }
                  }
                  for (var cat in customCats) {
                    if (!list.contains(cat) && cat != 'Khác') {
                      list.add(cat);
                    }
                  }
                  list.add('Khác');
                  if (!list.contains(_addCategory)) list = [...list, _addCategory];
                  return list;
                }()).map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  );
                }).toList(),
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
              
              if (_goals.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  value: _addGoalId,
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Gắn với mục tiêu (tùy chọn)',
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không gắn mục tiêu', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    ),
                    ..._goals.map((Goal g) {
                      return DropdownMenuItem<int?>(
                        value: g.id,
                        child: Text(g.title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() => _addGoalId = val);
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _addNoteController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm giao dịch', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
