import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  String _period = '6m';

  final List<Map<String, dynamic>> _monthly = [
    {'m': 'T1', 'inc': 28.0, 'exp': 16.5},
    {'m': 'T2', 'inc': 30.0, 'exp': 18.2},
    {'m': 'T3', 'inc': 32.0, 'exp': 19.8},
    {'m': 'T4', 'inc': 28.5, 'exp': 17.6},
    {'m': 'T5', 'inc': 35.0, 'exp': 22.0},
    {'m': 'T6', 'inc': 43.0, 'exp': 21.5},
  ];

  final List<Map<String, dynamic>> _catData = [
    {'name': 'Ăn uống', 'val': 4200000.0, 'color': const Color(0xFF0D9488)},
    {'name': 'Mua sắm', 'val': 3850000.0, 'color': const Color(0xFFF43F5E)},
    {'name': 'Di chuyển', 'val': 1850000.0, 'color': const Color(0xFF3B82F6)},
    {'name': 'Hóa đơn', 'val': 1680000.0, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Sức khỏe', 'val': 750000.0, 'color': const Color(0xFF10B981)},
    {'name': 'Giải trí', 'val': 620000.0, 'color': const Color(0xFFF59E0B)},
  ];

  String _fmt(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
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
                      children: const [
                        Text('Báo cáo tài chính', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Phân tích dòng tiền', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.download, color: Color(0xFF94A3B8), size: 13),
                          SizedBox(width: 4),
                          Text('PDF', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // KPI row
                Row(
                  children: [
                    _buildKPICard('Tổng thu', '196M', '+18%', true, Icons.trending_up),
                    const SizedBox(width: 8),
                    _buildKPICard('Tổng chi', '115.7M', '+9%', false, Icons.trending_down),
                    const SizedBox(width: 8),
                    _buildKPICard('Tiết kiệm', '47%', '+6%', true, Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Period selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('3m', '3 tháng'),
                      _buildPeriodButton('6m', '6 tháng'),
                      _buildPeriodButton('1y', '1 năm'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Area chart
                Container(
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
                          const Text('Dòng tiền', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
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
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1, dashArray: [3, 3]);
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
                                spots: _monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['inc'] as double)).toList(),
                                isCurved: true,
                                color: const Color(0xFF0D9488),
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF0D9488).withOpacity(0.2), const Color(0xFF0D9488).withOpacity(0.0)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: _monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['exp'] as double)).toList(),
                                isCurved: true,
                                color: const Color(0xFFF43F5E),
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFFF43F5E).withOpacity(0.15), const Color(0xFFF43F5E).withOpacity(0.0)],
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
                ),
                const SizedBox(height: 16),

                // Pie + breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiêu theo danh mục (T6)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 36,
                                sections: _catData.map((d) {
                                  return PieChartSectionData(
                                    color: d['color'],
                                    value: d['val'],
                                    radius: 19,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: _catData.map((c) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c['color'], shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Text(c['name'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                      Text(
                                        _fmt(c['val'] as double),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontFamily: 'DM Mono'),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bảng tổng hợp', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(3),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                            children: ['Tháng', 'Thu', 'Chi', 'Tiết kiệm'].map((h) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(h, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                          ..._monthly.asMap().entries.map((e) {
                            int i = e.key;
                            var m = e.value;
                            return TableRow(
                              decoration: BoxDecoration(border: i < _monthly.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF8FAFC))) : const Border()),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(m['m'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${m['inc']}M', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${m['exp']}M', style: const TextStyle(fontSize: 11, color: Color(0xFFF43F5E), fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${((m['inc'] as double) - (m['exp'] as double)).toStringAsFixed(1)}M', style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String val, String trend, bool up, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'DM Mono')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: up ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 10),
                const SizedBox(width: 2),
                Text(trend, style: TextStyle(color: up ? const Color(0xFF10B981) : const Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String p, String label) {
    bool active = _period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
