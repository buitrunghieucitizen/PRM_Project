import 'package:flutter/material.dart';
import 'dart:math';
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
  bool _showAdd = false;
  bool _isLoading = true;
  List<MonthlyPlan> _plans = [];
  Map<String, double> _spentMap = {};

  final TextEditingController _catController = TextEditingController();
  final TextEditingController _amtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _apiService.getPlans(1);
      final txs = await _apiService.getTransactions(1);
      
      Map<String, double> sm = {};
      final now = DateTime.now();
      for (var t in txs) {
        if (t.type.toLowerCase() == 'expense' && t.transactionDate.month == now.month && t.transactionDate.year == now.year) {
          sm[t.category] = (sm[t.category] ?? 0) + t.amount;
        }
      }

      if (mounted) {
        setState(() {
          _plans = plans;
          _spentMap = sm;
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
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
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

  Widget build(BuildContext context) {
    double totalBudget = _plans.fold(0, (s, p) => s + p.plannedAmount);
    double totalSpent = 0;
    for (var v in _spentMap.values) {
      totalSpent += v;
    }
    int pctOverall = totalBudget == 0 ? 0 : ((totalSpent / totalBudget) * 100).round();

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
                            Text('Kế hoạch tháng', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Ngân sách chi tiêu', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                            const SizedBox(width: 10),
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
                    
                    // Overview ring card
                    Container(
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
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 8,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CircularProgressIndicator(
                                    value: min(pctOverall / 100.0, 1.0),
                                    strokeWidth: 8,
                                    color: pctOverall > 100 ? const Color(0xFFF43F5E) : const Color(0xFF0D9488),
                                    backgroundColor: Colors.transparent,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '$pctOverall%',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
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
                                Text(
                                  '${_fmt(totalBudget)} ₫',
                                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DM Mono'),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Đã chi khoảng ${_fmt(totalSpent)} ₫',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
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
                    ? const Center(child: CircularProgressIndicator())
                    : _plans.isEmpty
                        ? const Center(child: Text('Chưa có kế hoạch nào. Hãy ấn nút + hoặc nhờ AI tư vấn!'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) {
                              final p = _plans[index];
                              double spent = _spentMap[p.category] ?? 0.0;
                              double pct = p.plannedAmount == 0 ? 0 : (spent / p.plannedAmount) * 100;
                              
                              return Container(
                                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('📋', style: TextStyle(fontSize: 20)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.category, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${_fmt(spent)} / ${_fmt(p.plannedAmount)} ₫',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'DM Mono'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${pct.round()}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Color(0xFF0D9488),
                                            fontFamily: 'DM Mono',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height: 8,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: min(pct / 100, 1.0),
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
                              );
                            },
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
                  const Text('Thêm ngân sách', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16)),
                  GestureDetector(
                    onTap: () => setState(() => _showAdd = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _catController,
                decoration: InputDecoration(
                  hintText: 'Tên danh mục',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amtController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ngân sách (VND)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontFamily: 'DM Mono'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Currently read-only for demo, or we can implement real add
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
                child: const Text('Thêm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

