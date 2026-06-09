import 'package:flutter/material.dart';
import 'dart:math';

class MonthlyPlan extends StatefulWidget {
  const MonthlyPlan({super.key});

  @override
  State<MonthlyPlan> createState() => _MonthlyPlanState();
}

class _MonthlyPlanState extends State<MonthlyPlan> {
  bool _showAdd = false;

  final List<Map<String, dynamic>> _budgets = [
    {'id': 1, 'cat': 'Ăn uống', 'budget': 5000000.0, 'spent': 4200000.0, 'color': const Color(0xFF0D9488), 'emoji': '🍜'},
    {'id': 2, 'cat': 'Di chuyển', 'budget': 2000000.0, 'spent': 1850000.0, 'color': const Color(0xFF3B82F6), 'emoji': '🚗'},
    {'id': 3, 'cat': 'Giải trí', 'budget': 1500000.0, 'spent': 620000.0, 'color': const Color(0xFFF59E0B), 'emoji': '🎬'},
    {'id': 4, 'cat': 'Mua sắm', 'budget': 3000000.0, 'spent': 3850000.0, 'color': const Color(0xFFF43F5E), 'emoji': '🛍️'},
    {'id': 5, 'cat': 'Hóa đơn', 'budget': 2500000.0, 'spent': 1680000.0, 'color': const Color(0xFF8B5CF6), 'emoji': '💡'},
    {'id': 6, 'cat': 'Sức khỏe', 'budget': 1000000.0, 'spent': 750000.0, 'color': const Color(0xFF10B981), 'emoji': '🏥'},
    {'id': 7, 'cat': 'Tiết kiệm', 'budget': 8000000.0, 'spent': 5000000.0, 'color': const Color(0xFF06B6D4), 'emoji': '🏦'},
  ];

  String _fmt(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    double totalBudget = _budgets.fold(0, (s, b) => s + (b['budget'] as double));
    double totalSpent = _budgets.fold(0, (s, b) => s + (b['spent'] as double));
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
                            Text('Kế hoạch tháng 6', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Ngân sách chi tiêu', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
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
                                const Text('Tổng chi tiêu', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_fmt(totalSpent)} ₫',
                                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DM Mono'),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '/ ${_fmt(totalBudget)} ₫ ngân sách',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                                if (totalSpent > totalBudget * 0.9) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: const [
                                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 12),
                                      SizedBox(width: 4),
                                      Text('Gần đến hạn mức!', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // AI tip
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 15),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5),
                                children: [
                                  TextSpan(text: 'AI gợi ý: ', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                                  TextSpan(text: 'Mua sắm vượt 850K. Áp dụng quy tắc 24h chờ đợi → tiết kiệm ~2.3M/tháng.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Budget items
                    ..._budgets.map((b) {
                      double budget = b['budget'];
                      double spent = b['spent'];
                      double pct = (spent / budget) * 100;
                      if (pct > 100) pct = 100;
                      bool over = spent > budget;
                      bool warn = pct >= 80 && !over;
                      Color catColor = b['color'];

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
                                    color: catColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                          if (over) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('Vượt!', style: TextStyle(fontSize: 10, color: Color(0xFFF43F5E), fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                          if (warn) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('Gần hết', style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_fmt(spent)} / ${_fmt(budget)} ₫',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'DM Mono'),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${pct.round()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: over ? const Color(0xFFF43F5E) : catColor,
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
                                widthFactor: pct / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: over ? const Color(0xFFF43F5E) : warn ? const Color(0xFFF59E0B) : catColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            if (over)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Vượt ${_fmt(spent - budget)} ₫',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E), fontFamily: 'DM Mono'),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
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
                  const Text('Thêm ngân sách', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16)),
                  GestureDetector(
                    onTap: () => setState(() => _showAdd = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAddTextField('Tên danh mục'),
              const SizedBox(height: 12),
              _buildAddTextField('Ngân sách (VND)', isNumber: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _showAdd = false),
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
