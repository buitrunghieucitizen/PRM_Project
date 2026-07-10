import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import '../services/api_service.dart';

class MonthlyPlan extends StatefulWidget {
  const MonthlyPlan({super.key});

  @override
  State<MonthlyPlan> createState() => _MonthlyPlanState();
}

class _MonthlyPlanState extends State<MonthlyPlan> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSuggesting = false;
  bool _isGridView = false;

  double _totalBudget = 0;
  List<Map<String, dynamic>> _budgets = [];
  Set<String> _lockedCategories = {}; // Tracks categories manually edited

  final List<Map<String, dynamic>> _defaultCategories = [
    {'cat': 'Ăn uống', 'color': const Color(0xFF0D9488), 'emoji': '🍜'},
    {'cat': 'Di chuyển', 'color': const Color(0xFF3B82F6), 'emoji': '🚗'},
    {'cat': 'Giải trí', 'color': const Color(0xFFF59E0B), 'emoji': '🎬'},
    {'cat': 'Mua sắm', 'color': const Color(0xFFF43F5E), 'emoji': '🛍️'},
    {'cat': 'Hóa đơn', 'color': const Color(0xFF8B5CF6), 'emoji': '💡'},
    {'cat': 'Sức khỏe', 'color': const Color(0xFF10B981), 'emoji': '🏥'},
    {'cat': 'Tiết kiệm', 'color': const Color(0xFF06B6D4), 'emoji': '🏦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final budgetData = await ApiService.getCurrentBudget();
      _totalBudget = (budgetData['totalBudget'] ?? 0).toDouble();
      
      List<dynamic> allocations = [];
      if (budgetData['categoryAllocations'] != null) {
        allocations = jsonDecode(budgetData['categoryAllocations']);
      }

      final txs = await ApiService.getTransactions();
      
      _budgets = _defaultCategories.map((def) {
        var alloc = allocations.firstWhere((a) => a['cat'] == def['cat'], orElse: () => null);
        double budget = alloc != null ? (alloc['budget'] as num).toDouble() : 0;
        
        // Calculate spent
        double spent = 0;
        for (var t in txs) {
          if (t['category'] == def['cat'] && t['type'] == 'Expense') {
            spent += (t['amount'] as num).toDouble();
          }
        }
        
        return {
          'cat': def['cat'],
          'color': def['color'],
          'emoji': def['emoji'],
          'budget': budget,
          'spent': spent,
        };
      }).toList();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'Month': DateTime.now().month,
        'Year': DateTime.now().year,
        'TotalBudget': _totalBudget,
        'CategoryAllocations': jsonEncode(_budgets.map((b) => {
          'cat': b['cat'],
          'budget': b['budget']
        }).toList()),
      };
      await ApiService.setBudget(data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu kế hoạch thành công!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _suggestBudget() async {
    setState(() => _isSuggesting = true);
    try {
      List<Map<String, dynamic>> locked = _budgets
          .where((b) => _lockedCategories.contains(b['cat']))
          .map((b) => {'name': b['cat'], 'amount': b['budget']})
          .toList();
          
      List<String> targets = _budgets
          .where((b) => !_lockedCategories.contains(b['cat']))
          .map((b) => b['cat'] as String)
          .toList();

      if (targets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tất cả danh mục đã bị khóa.')));
        return;
      }

      String? resultStr = await ApiService.suggestBudget(_totalBudget, locked, targets);
      if (resultStr != null) {
        Map<String, dynamic> suggestion = jsonDecode(resultStr);
        setState(() {
          for (var i = 0; i < _budgets.length; i++) {
            String catName = _budgets[i]['cat'];
            if (suggestion.containsKey(catName) && !_lockedCategories.contains(catName)) {
              _budgets[i]['budget'] = (suggestion[catName] as num).toDouble();
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã áp dụng gợi ý từ AI!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gợi ý AI: $e')));
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  void _editTotalBudget() {
    TextEditingController ctrl = TextEditingController(text: _totalBudget.toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tổng ngân sách'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(suffixText: 'VNĐ'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _totalBudget = double.tryParse(ctrl.text) ?? _totalBudget;
            });
            Navigator.pop(ctx);
          },
          child: const Text('Lưu'),
        )
      ],
    ));
  }

  void _editCategoryBudget(int index) {
    String cat = _budgets[index]['cat'];
    double current = _budgets[index]['budget'];
    TextEditingController ctrl = TextEditingController(text: current.toStringAsFixed(0));
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Ngân sách cho $cat'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(suffixText: 'VNĐ'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _budgets[index]['budget'] = double.tryParse(ctrl.text) ?? current;
              _lockedCategories.add(cat);
            });
            Navigator.pop(ctx);
          },
          child: const Text('Lưu & Khóa'),
        )
      ],
    ));
  }

  void _toggleLock(String cat) {
    setState(() {
      if (_lockedCategories.contains(cat)) {
        _lockedCategories.remove(cat);
      } else {
        _lockedCategories.add(cat);
      }
    });
  }

  String _fmt(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    double allocated = _budgets.fold(0, (s, b) => s + (b['budget'] as double));
    double totalSpent = _budgets.fold(0, (s, b) => s + (b['spent'] as double));
    int pctOverall = _totalBudget == 0 ? 0 : ((totalSpent / _totalBudget) * 100).round();

    return Container(
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
                      children: [
                        Text('Tháng ${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Ngân sách chi tiêu', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _savePlan,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 16),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // Overview card
                GestureDetector(
                  onTap: _editTotalBudget,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: Colors.white.withOpacity(0.1))),
                              SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: min(pctOverall / 100.0, 1.0), strokeWidth: 8, color: pctOverall > 100 ? const Color(0xFFF43F5E) : const Color(0xFF0D9488))),
                              Text('$pctOverall%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tổng ngân sách', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${_fmt(_totalBudget)} ₫', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DM Mono')),
                              const SizedBox(height: 2),
                              Text('Đã phân bổ: ${_fmt(allocated)} ₫', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              Text('Đã tiêu: ${_fmt(totalSpent)} ₫', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white54, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // AI Tip Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isSuggesting ? null : _suggestBudget,
                    icon: _isSuggesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                    label: const Text('AI Gợi ý phân bổ (Bỏ qua mục đã khóa)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDFA),
                      foregroundColor: const Color(0xFF0D9488),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Budget items
                ..._budgets.asMap().entries.map((entry) {
                  int i = entry.key;
                  var b = entry.value;
                  double budget = b['budget'];
                  double spent = b['spent'];
                  double pct = budget == 0 ? 0 : (spent / budget) * 100;
                  if (pct > 100) pct = 100;
                  bool over = budget > 0 && spent > budget;
                  bool isLocked = _lockedCategories.contains(b['cat']);
                  Color catColor = b['color'];

                  return GestureDetector(
                    onTap: () => _editCategoryBudget(i),
                    child: Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: isLocked ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.center,
                                child: Text(b['emoji'], style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(b['cat'], style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () => _toggleLock(b['cat']),
                                          child: Icon(isLocked ? Icons.lock : Icons.lock_open, size: 16, color: isLocked ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${_fmt(spent)} / ${_fmt(budget)} ₫', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'DM Mono')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct / 100,
                              child: Container(
                                decoration: BoxDecoration(color: over ? const Color(0xFFF43F5E) : catColor, borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
