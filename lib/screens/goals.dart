import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _apiService.getGoals(1);
      final txs = await _apiService.getTransactions(1);
      
      Map<int, double> curMap = {};
      Map<int, double> monthMap = {};
      final now = DateTime.now();

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
            _selected = _goalsList[0];
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
    if (short) {
      if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
      if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(0)}M';
      return '${(n / 1e3).toStringAsFixed(0)}K';
    }
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + ' ₫';
  }

  void _openAIAdvisor() async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIAdvisor(userId: 1)),
    );
    if (shouldRefresh == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            Text('Mục tiêu tài chính', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Theo dõi & dự đoán', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
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
                    
                    // Summary row
                    if (!_isLoading && _goalsList.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _goalsList.map((g) {
                            double cur = _currentAmountMap[g.id] ?? g.currentAmount;
                            int pct = g.targetAmount > 0 ? ((cur / g.targetAmount) * 100).round() : 0;
                            bool isSelected = _selected?.id == g.id;
                            Color gColor = const Color(0xFF0D9488);
                            return GestureDetector(
                              onTap: () => setState(() => _selected = g),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? gColor : Colors.white.withOpacity(0.07),
                                  border: Border.all(color: isSelected ? gColor : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Text('🎯', style: TextStyle(fontSize: 20)),
                                    Text('$pct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'DM Mono')),
                                    Text(g.title, style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B), fontSize: 10), overflow: TextOverflow.ellipsis),
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
                    ? const Center(child: CircularProgressIndicator())
                    : _goalsList.isEmpty || _selected == null
                        ? const Center(child: Text('Chưa có mục tiêu nào. Hãy ấn nút + để tạo mới!'))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Selected goal detail
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('🎯', style: TextStyle(fontSize: 24)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_selected!.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16)),
                                              const SizedBox(height: 2),
                                              const Text('Mục tiêu', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${_selected!.targetAmount > 0 ? (((_currentAmountMap[_selected!.id] ?? _selected!.currentAmount) / _selected!.targetAmount) * 100).round() : 0}%',
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0D9488), fontSize: 18, fontFamily: 'DM Mono'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 12,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _selected!.targetAmount > 0 ? ((_currentAmountMap[_selected!.id] ?? _selected!.currentAmount) / _selected!.targetAmount).clamp(0.0, 1.0) as double : 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_fmt(_currentAmountMap[_selected!.id] ?? _selected!.currentAmount, true), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'DM Mono')),
                                        Text(_fmt(_selected!.targetAmount, true), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontFamily: 'DM Mono')),
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
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text('Còn thiếu', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                                const SizedBox(height: 4),
                                                Text('${_fmt(_selected!.targetAmount - (_currentAmountMap[_selected!.id] ?? _selected!.currentAmount), true)} ₫', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF43F5E), fontSize: 14, fontFamily: 'DM Mono')),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDFA),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text('Tháng này', style: TextStyle(fontSize: 10, color: Color(0xFF0D9488))),
                                                const SizedBox(height: 4),
                                                Text('+ ${_fmt(_thisMonthAmountMap[_selected!.id] ?? 0, true)} ₫', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D9488), fontSize: 14, fontFamily: 'DM Mono')),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // All goals list
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                                      child: Text('Tất cả mục tiêu', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                                    ),
                                    ..._goalsList.asMap().entries.map((e) {
                                      int i = e.key;
                                      var g = e.value;
                                      double cur = _currentAmountMap[g.id] ?? g.currentAmount;
                                      int pct = g.targetAmount > 0 ? ((cur / g.targetAmount) * 100).round() : 0;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selected = g),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: i > 0 ? const Border(top: BorderSide(color: Color(0xFFF8FAFC))) : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0D9488).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text('🎯', style: const TextStyle(fontSize: 20)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(g.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14)),
                                                        Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D9488), fontSize: 13, fontFamily: 'DM Mono')),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      height: 6,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: FractionallySizedBox(
                                                        alignment: Alignment.centerLeft,
                                                        widthFactor: g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) as double : 0.0,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF0D9488),
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
                                    }).toList(),
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
        if (_showAdd) _buildAddModal(),
      ],
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
                  const Text('Thêm mục tiêu', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16)),
                  GestureDetector(
                    onTap: () => setState(() => _showAdd = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...[
                'Tên mục tiêu (VD: Mua xe)',
                'Số tiền mục tiêu (VND)',
                'Đã tiết kiệm được (VND)',
                'Tiết kiệm mỗi tháng (VND)'
              ].map((ph) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: ph,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
                  ),
                ),
              )).toList(),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showAdd = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ghi nhận (Demo)')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Tạo mục tiêu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
