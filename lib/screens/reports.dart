import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  String _period = '6m';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Transaction> _transactions = [];

  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _catData = [];

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _maxY = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _apiService.getTransactions(ApiService.currentUserId);
      
      // Calculate _monthly for the last 6 months
      Map<String, Map<String, double>> monthlyMap = {};
      double inc = 0;
      double exp = 0;
      Map<String, double> catMap = {};

      for (var t in txs) {
        if (t.type.toLowerCase() == 'income') {
          inc += t.amount;
        } else {
          exp += t.amount;
          catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
        }
        
        String mKey = '${t.transactionDate.year}-${t.transactionDate.month}';
        if (!monthlyMap.containsKey(mKey)) {
          monthlyMap[mKey] = {'inc': 0, 'exp': 0};
        }
        if (t.type.toLowerCase() == 'income') {
          monthlyMap[mKey]!['inc'] = monthlyMap[mKey]!['inc']! + t.amount;
        } else {
          monthlyMap[mKey]!['exp'] = monthlyMap[mKey]!['exp']! + t.amount;
        }
      }

      List<Map<String, dynamic>> tempMonthly = [];
      int currentYear = DateTime.now().year;
      int currentMonth = DateTime.now().month;
      
      int monthsCount = 6;
      if (_period == '3m') monthsCount = 3;
      if (_period == '1y') monthsCount = 12;

      double calculatedMaxY = 10; // minimum 10
      for (int i = monthsCount - 1; i >= 0; i--) {
        int m = currentMonth - i;
        int y = currentYear;
        while (m <= 0) {
          m += 12;
          y -= 1;
        }
        String mKey = '$y-$m';
        double minc = monthlyMap[mKey]?['inc'] ?? 0;
        double mexp = monthlyMap[mKey]?['exp'] ?? 0;
        
        double mincM = minc / 1000000;
        double mexpM = mexp / 1000000;
        if (mincM > calculatedMaxY) calculatedMaxY = mincM;
        if (mexpM > calculatedMaxY) calculatedMaxY = mexpM;

        tempMonthly.add({'m': 'T$m', 'inc': mincM, 'exp': mexpM});
      }
      
      // Add a 20% margin to maxY
      calculatedMaxY = calculatedMaxY * 1.2;

      List<Map<String, dynamic>> tempCat = [];
      List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red, Colors.green];
      int colorIdx = 0;
      catMap.forEach((key, value) {
        tempCat.add({'name': key, 'val': value, 'color': colors[colorIdx % colors.length]});
        colorIdx++;
      });
      tempCat.sort((a, b) => (b['val'] as double).compareTo(a['val'] as double));

      if (mounted) {
        setState(() {
          _transactions = txs;
          _monthly = tempMonthly;
          _catData = tempCat;
          _totalIncome = inc;
          _totalExpense = exp;
          _maxY = calculatedMaxY;
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
      if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
      if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    }
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
            color: Theme.of(context).textTheme.bodyLarge?.color,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Báo cáo tài chính', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Phân tích dòng tiền', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // KPI row
                Row(
                  children: [
                    _buildKPICard('Tổng thu', _fmt(_totalIncome), '', true, Icons.trending_up),
                    SizedBox(width: 8),
                    _buildKPICard('Tổng chi', _fmt(_totalExpense), '', false, Icons.trending_down),
                    SizedBox(width: 8),
                    _buildKPICard('Tiết kiệm', _totalIncome > 0 ? '${((_totalIncome - _totalExpense) / _totalIncome * 100).toStringAsFixed(0)}%' : '0%', '', true, Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Period selector
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('3m', '3 tháng'),
                      _buildPeriodButton('6m', '6 tháng'),
                      _buildPeriodButton('1y', '1 năm'),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Area chart
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dòng tiền', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  SizedBox(width: 4),
                                  Text('Thu', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                                ],
                              ),
                              SizedBox(width: 12),
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                  SizedBox(width: 4),
                                  Text('Chi', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(color: Color(0xFFF0F0F0), strokeWidth: 1, dashArray: [3, 3]);
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    var style = TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 10);
                                    Widget text;
                                    int idx = value.toInt();
                                    if (idx >= 0 && idx < _monthly.length) {
                                      text = Text(_monthly[idx]['m'], style: style);
                                    } else {
                                      text = Text('', style: style);
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
                                    if (value == 0) return SizedBox.shrink();
                                    return Text('${value.toInt()}M', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: _monthly.length - 1.0,
                            minY: 0,
                            maxY: _maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['inc'] as double)).toList(),
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.0)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: _monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['exp'] as double)).toList(),
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [Colors.red.withValues(alpha: 0.15), Colors.red.withValues(alpha: 0.0)],
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
                SizedBox(height: 16),

                // Pie + breakdown
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chi tiêu theo danh mục (T${DateTime.now().month})', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
                      SizedBox(height: 12),
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
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: _catData.map((c) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c['color'], shape: BoxShape.circle)),
                                          SizedBox(width: 6),
                                          Text(c['name'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                        ],
                                      ),
                                      Text(
                                        _fmt(c['val'] as double),
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontFamily: 'DM Mono'),
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
                SizedBox(height: 16),

                // Monthly table
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bảng tổng hợp', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
                      SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(3),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                            children: ['Tháng', 'Thu', 'Chi', 'Tiết kiệm'].map((h) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(h, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                          ..._monthly.asMap().entries.map((e) {
                            int i = e.key;
                            var m = e.value;
                            return TableRow(
                              decoration: BoxDecoration(border: i < _monthly.length - 1 ? Border(bottom: BorderSide(color: Color(0xFFF0F0F0))) : Border()),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(m['m'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${m['inc']}M', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${m['exp']}M', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${((m['inc'] as double) - (m['exp'] as double)).toStringAsFixed(1)}M', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontFamily: 'DM Mono')),
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 10)),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(val, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'DM Mono')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: trend.contains('+') ? Colors.green : (trend.contains('-') ? Colors.red : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5)), size: 10),
                SizedBox(width: 2),
                Text(trend, style: TextStyle(color: trend.contains('+') ? Colors.green : (trend.contains('-') ? Colors.red : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5)), fontSize: 10, fontWeight: FontWeight.w600)),
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
        onTap: () {
          setState(() => _period = p);
          _loadData();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
