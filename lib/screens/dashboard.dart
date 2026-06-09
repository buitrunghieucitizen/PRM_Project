import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatelessWidget {
  final Function(String) onNavigate;

  const Dashboard({super.key, required this.onNavigate});

  String _fmt(double n) {
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    return '${(n / 1e3).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
              color: const Color(0xFF0F172A),
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
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'TN',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Xin chào 👋', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              Text('Trần Nam', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.notifications_none, color: Color(0xFF94A3B8), size: 18),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF43F5E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Số dư hiện tại', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text(
                          '21.440.000 ₫',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'DM Mono'),
                        ),
                        const SizedBox(height: 4),
                        Text('Tháng 6, 2026', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_outward, color: Colors.white.withOpacity(0.8), size: 14),
                                        const SizedBox(width: 6),
                                        Text('Thu nhập', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('43.0M ₫', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.south_east, color: Colors.white.withOpacity(0.8), size: 14),
                                        const SizedBox(width: 6),
                                        Text('Chi tiêu', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('21.5M ₫', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                  ],
                                ),
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
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction('Thêm\nthu', '💰', const Color(0xFFD1FAE5), null),
                      _buildQuickAction('Thêm\nchi', '💸', const Color(0xFFFFE4E6), null),
                      _buildQuickAction('Kế\nhoạch', '📋', const Color(0xFFDBEAFE), 'plan'),
                      _buildQuickAction('Báo\ncáo', '📊', const Color(0xFFFEF3C7), 'reports'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart
                  _buildChart(),
                  const SizedBox(height: 16),
                  
                  // Budget Progress
                  _buildBudgetProgress(),
                  const SizedBox(height: 16),
                  
                  // Recent Transactions
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, String emoji, Color bgColor, String? screenTarget) {
    return GestureDetector(
      onTap: screenTarget != null ? () => onNavigate(screenTarget) : null,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 10, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thu chi 6 tháng', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              Row(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Thu', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Chi', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Color(0xFF94A3B8), fontSize: 10);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('T1', style: style); break;
                          case 1: text = const Text('T2', style: style); break;
                          case 2: text = const Text('T3', style: style); break;
                          case 3: text = const Text('T4', style: style); break;
                          case 4: text = const Text('T5', style: style); break;
                          case 5: text = const Text('T6', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text('${value.toInt()}M', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 50,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 28), FlSpot(1, 30), FlSpot(2, 32), FlSpot(3, 28.5), FlSpot(4, 35), FlSpot(5, 43),
                    ],
                    isCurved: true,
                    color: const Color(0xFF0D9488),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0D9488).withOpacity(0.2),
                          const Color(0xFF0D9488).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 16.5), FlSpot(1, 18.2), FlSpot(2, 19.8), FlSpot(3, 17.6), FlSpot(4, 22), FlSpot(5, 21.5),
                    ],
                    isCurved: true,
                    color: const Color(0xFFF43F5E),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF43F5E).withOpacity(0.15),
                          const Color(0xFFF43F5E).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ngân sách tháng', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              GestureDetector(
                onTap: () => onNavigate('plan'),
                child: const Text('Xem thêm →', style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBudgetItem('Ăn uống', '🍜', 4200000, 5000000, const Color(0xFF0D9488)),
          _buildBudgetItem('Mua sắm', '🛍️', 3850000, 3000000, const Color(0xFFF43F5E)),
          _buildBudgetItem('Di chuyển', '🚗', 1850000, 2000000, const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(String cat, String emoji, double spent, double budget, Color color) {
    double pct = (spent / budget) * 100;
    if (pct > 100) pct = 100;
    bool over = spent > budget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji),
                  const SizedBox(width: 8),
                  Text(cat, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                  if (over) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Vượt!', style: TextStyle(fontSize: 10, color: Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              Text(
                '${_fmt(spent)}/${_fmt(budget)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'DM Mono'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
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
                  color: over ? const Color(0xFFF43F5E) : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = [
      {'desc': 'Lương tháng 6', 'amount': 38000000, 'type': 'income', 'cat': 'Thu nhập', 'date': '01/06'},
      {'desc': 'Siêu thị Vinmart', 'amount': 420000, 'type': 'expense', 'cat': 'Ăn uống', 'date': '02/06'},
      {'desc': 'Grab xe', 'amount': 85000, 'type': 'expense', 'cat': 'Di chuyển', 'date': '03/06'},
      {'desc': 'Thưởng dự án', 'amount': 5000000, 'type': 'income', 'cat': 'Thưởng', 'date': '05/06'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giao dịch gần đây', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
              GestureDetector(
                onTap: () => onNavigate('journal'),
                child: const Text('Tất cả →', style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recent.map((t) {
            bool isIncome = t['type'] == 'income';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isIncome ? Icons.arrow_outward : Icons.south_east,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['desc'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                        Text('${t['cat']} · ${t['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? "+" : "-"}${_fmt(double.parse(t['amount'].toString()))}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      fontFamily: 'DM Mono',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
