import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'ai_advisor.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Goal> _goalsList = [];
  Map<int, double> _currentAmountMap = {};
  Map<int, double> _thisMonthAmountMap = {};

  Goal? _selected;
  bool _showAdd = false;
  Goal? _editingGoal;
  bool _isCompleted = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _apiService.getGoals(ApiService.currentUserId);
      final txs = await _apiService.getTransactions(ApiService.currentUserId);
      
      Map<int, double> curMap = {};
      Map<int, double> monthMap = {};
      final now = DateTime.now();

      for (var g in goals) {
        curMap[g.id] = g.currentAmount;
      }

      for (var t in txs) {
        if (t.goalId != null) {
          curMap[t.goalId!] = (curMap[t.goalId!] ?? 0) + t.amount;
          if (t.transactionDate.month == now.month && t.transactionDate.year == now.year) {
            monthMap[t.goalId!] = (monthMap[t.goalId!] ?? 0) + t.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _goalsList = goals;
          _currentAmountMap = curMap;
          _thisMonthAmountMap = monthMap;
          if (_goalsList.isNotEmpty) {
            if (_selected == null || !_goalsList.any((g) => g.id == _selected!.id)) {
              _selected = _goalsList[0];
            } else {
              _selected = _goalsList.firstWhere((g) => g.id == _selected!.id);
            }
          } else {
            _selected = null;
          }
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

  String _fmt(double n, [bool short = false]) {
    bool showDetailed = Provider.of<ThemeProvider>(context).showDetailedAmount;
    if (short && !showDetailed) {
      if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
      if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(0)}M';
      if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    }
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  void _openAIAdvisor() async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AIAdvisor(userId: ApiService.currentUserId)),
    );
    if (shouldRefresh == true) {
      _loadData();
    }
  }

  void _openAddModal([Goal? g]) {
    setState(() {
      _editingGoal = g;
      if (g != null) {
        _titleController.text = g.title;
        _targetController.text = g.targetAmount.toStringAsFixed(0);
        _currentController.text = g.currentAmount.toStringAsFixed(0);
        _isCompleted = g.isCompleted;
      } else {
        _titleController.clear();
        _targetController.clear();
        _currentController.clear();
        _isCompleted = false;
      }
      _showAdd = true;
    });
  }

  Future<void> _deleteGoal(Goal g) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Xác nhận xóa', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Bạn có chắc chắn muốn xóa mục tiêu này?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm == true) {
      try {
        await _apiService.deleteGoal(g.id);
        if (mounted) setState(() => _showAdd = false);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                            Text('Mục tiêu tài chính', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Theo dõi & dự đoán', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _openAIAdvisor,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.auto_awesome, color: theme.scaffoldBackgroundColor, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary row
                    if (!_isLoading && _goalsList.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _goalsList.map((g) {
                            double cur = _currentAmountMap[g.id] ?? g.currentAmount;
                            int pct = g.targetAmount > 0 ? ((cur / g.targetAmount) * 100).round() : 0;
                            bool isSelected = _selected?.id == g.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = g),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.scaffoldBackgroundColor : theme.scaffoldBackgroundColor.withValues(alpha: 0.07),
                                  border: Border.all(color: isSelected ? theme.scaffoldBackgroundColor : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.flag_outlined, size: 20, color: isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor),
                                    Text('$pct%', style: TextStyle(color: isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor, fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(g.title, style: TextStyle(color: isSelected ? theme.primaryColor.withValues(alpha: 0.6) : theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 10), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : _goalsList.isEmpty || _selected == null
                        ? Center(child: Text('Chưa có mục tiêu nào. Hãy ấn nút + để tạo mới!', style: TextStyle(color: theme.textTheme.bodySmall?.color)))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Selected goal detail
                              InkWell(
                                onTap: () => _openAddModal(_selected!),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.flag_outlined, size: 24, color: theme.primaryColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(_selected!.title, style: TextStyle(fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, fontSize: 16)),
                                                const SizedBox(height: 2),
                                                Text(_selected!.isCompleted ? 'Đã hoàn thành' : 'Mục tiêu (Bấm để sửa)', style: TextStyle(color: _selected!.isCompleted ? Colors.green : theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: _selected!.isCompleted ? FontWeight.bold : FontWeight.normal)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.edit, size: 20, color: theme.primaryColor),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Tiến độ', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                                          Text(
                                            '${_selected!.targetAmount > 0 ? (((_currentAmountMap[_selected!.id] ?? _selected!.currentAmount) / _selected!.targetAmount) * 100).round() : 0}%',
                                            style: TextStyle(fontWeight: FontWeight.w800, color: theme.primaryColor, fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 12,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: theme.dividerColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _selected!.targetAmount > 0 ? ((_currentAmountMap[_selected!.id] ?? _selected!.currentAmount) / _selected!.targetAmount).clamp(0.0, 1.0) : 0.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fmt(_currentAmountMap[_selected!.id] ?? _selected!.currentAmount, true), style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                                          Text(_fmt(_selected!.targetAmount, true), style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      
                                      // Stats
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text('Còn thiếu', style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
                                                  const SizedBox(height: 4),
                                                  Text('${_fmt(_selected!.targetAmount - (_currentAmountMap[_selected!.id] ?? _selected!.currentAmount), true)} ₫', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text('Tháng này', style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
                                                  const SizedBox(height: 4),
                                                  Text('+ ${_fmt(_thisMonthAmountMap[_selected!.id] ?? 0, true)} ₫', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // All goals list
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                                      child: Text('Tất cả mục tiêu', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
                                    ),
                                    ..._goalsList.asMap().entries.map((e) {
                                      int i = e.key;
                                      var g = e.value;
                                      double cur = _currentAmountMap[g.id] ?? g.currentAmount;
                                      int pct = g.targetAmount > 0 ? ((cur / g.targetAmount) * 100).round() : 0;
                                      return InkWell(
                                        onTap: () => setState(() => _selected = g),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.flag_outlined, size: 20, color: theme.primaryColor),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(g.title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                                                        if (g.isCompleted)
                                                          const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                                        else
                                                          Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 13)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      height: 6,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: theme.dividerColor,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: FractionallySizedBox(
                                                        alignment: Alignment.centerLeft,
                                                        widthFactor: g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: theme.primaryColor,
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
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),

        // Add modal
        if (_showAdd) _buildAddModal(theme),
      ],
    );
  }

  Widget _buildAddModal(ThemeData theme) {
    bool isEditing = _editingGoal != null;

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
                  Text(isEditing ? 'Sửa mục tiêu' : 'Thêm mục tiêu', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 16)),
                  Row(
                    children: [
                      if (isEditing)
                        GestureDetector(
                          onTap: () => _deleteGoal(_editingGoal!),
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
              _buildTextField('Tên mục tiêu (VD: Mua xe)', _titleController, theme),
              _buildTextField('Số tiền mục tiêu (VND)', _targetController, theme, isNumber: true),
              _buildTextField('Đã tiết kiệm được (VND)', _currentController, theme, isNumber: true),
              if (isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Đã hoàn thành', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _isCompleted,
                  activeColor: theme.primaryColor,
                  onChanged: (val) => setState(() => _isCompleted = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  final target = double.tryParse(_targetController.text) ?? 0;
                  final current = double.tryParse(_currentController.text) ?? 0;
                  if (title.isEmpty || target <= 0) return;

                  setState(() => _showAdd = false);
                  try {
                    if (isEditing) {
                      final updatedGoal = Goal(
                        id: _editingGoal!.id,
                        userId: ApiService.currentUserId,
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        deadline: _editingGoal!.deadline,
                        isCompleted: _isCompleted,
                      );
                      await _apiService.updateGoal(updatedGoal);
                    } else {
                      final newGoal = Goal(
                        id: 0,
                        userId: ApiService.currentUserId,
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        deadline: null,
                        isCompleted: _isCompleted,
                      );
                      await _apiService.addGoal(newGoal);
                    }
                    
                    _titleController.clear();
                    _targetController.clear();
                    _currentController.clear();
                    _loadData();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo mục tiêu', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, ThemeData theme, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
        ),
      ),
    );
  }
}
