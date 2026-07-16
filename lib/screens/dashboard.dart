import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class Dashboard extends StatefulWidget {
  final Function(String) onNavigate;

  const Dashboard({super.key, required this.onNavigate});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  List<Transaction> _recentTransactions = [];
  List<MonthlyPlan> _plans = [];
  Map<String, double> _categorySpentThisMonth = {};
  
  User? _user;
  List<FlSpot> _incomeSpots = [const FlSpot(0, 0), const FlSpot(1, 0), const FlSpot(2, 0), const FlSpot(3, 0), const FlSpot(4, 0), const FlSpot(5, 0)];
  List<FlSpot> _expenseSpots = [const FlSpot(0, 0), const FlSpot(1, 0), const FlSpot(2, 0), const FlSpot(3, 0), const FlSpot(4, 0), const FlSpot(5, 0)];
  double _chartMaxY = 50;
  List<String> _chartLabels = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6'];

  String get _displayName => _user?.fullName ?? _user?.username ?? 'User';
  String get _initials {
    if (_displayName.isEmpty) return 'U';
    final parts = _displayName.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    }
    return _displayName.substring(0, 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getUser(ApiService.currentUserId),
        _apiService.getTransactions(ApiService.currentUserId),
        _apiService.getPlans(ApiService.currentUserId),
      ]);
      
      final user = results[0] as User;
      final transactions = results[1] as List<Transaction>;
      final plans = results[2] as List<MonthlyPlan>;
      
      double inc = 0;
      double exp = 0;
      Map<String, double> catSpent = {};
      Map<String, Map<String, double>> monthlyMap = {};
      final now = DateTime.now();

      for (var t in transactions) {
        if (t.transactionDate.month == now.month && t.transactionDate.year == now.year) {
          if (t.type.toLowerCase() == 'income') {
            inc += t.amount;
          } else {
            exp += t.amount;
            catSpent[t.category] = (catSpent[t.category] ?? 0) + t.amount;
          }
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

      List<FlSpot> incSpots = [];
      List<FlSpot> expSpots = [];
      List<String> labels = [];
      double maxAmt = 0;
      
      for (int i = 5; i >= 0; i--) {
        int m = now.month - i;
        int y = now.year;
        if (m <= 0) {
          m += 12;
          y -= 1;
        }
        String mKey = '$y-$m';
        double minc = (monthlyMap[mKey]?['inc'] ?? 0) / 1000000;
        double mexp = (monthlyMap[mKey]?['exp'] ?? 0) / 1000000;
        if (minc > maxAmt) maxAmt = minc;
        if (mexp > maxAmt) maxAmt = mexp;
        
        incSpots.add(FlSpot((5 - i).toDouble(), minc));
        expSpots.add(FlSpot((5 - i).toDouble(), mexp));
        labels.add('T$m');
      }

      double chartMax = maxAmt > 0 ? (maxAmt * 1.2).ceilToDouble() : 50;

      if (mounted) {
        setState(() {
          _user = user;
          _incomeSpots = incSpots.isNotEmpty ? incSpots : _incomeSpots;
          _expenseSpots = expSpots.isNotEmpty ? expSpots : _expenseSpots;
          _chartMaxY = chartMax;
          _chartLabels = labels.isNotEmpty ? labels : _chartLabels;
          _totalIncome = inc;
          _totalExpense = exp;
          _balance = inc - exp;
          _categorySpentThisMonth = catSpent;
          _recentTransactions = transactions.take(5).toList();
          _plans = plans;
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

  String _fmt(double n, bool isDetailed) {
    if (isDetailed) return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  String _fmtCompact(double n, bool isDetailed) {
    if (isDetailed) return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDetailed = themeProvider.showDetailedAmount;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
              color: theme.primaryColor, // Black in Light, White in Dark
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
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor, // Opposite of header
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials,
                              style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xin chào', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), fontSize: 12)),
                              Text(_displayName, style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.notifications_none, color: theme.scaffoldBackgroundColor, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Số dư hiện tại', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                themeProvider.toggleDetailedAmount(!themeProvider.showDetailedAmount);
                              },
                              child: Icon(
                                isDetailed ? Icons.visibility : Icons.visibility_off, 
                                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), 
                                size: 18
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(_balance, isDetailed),
                          style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text('Tháng ${DateTime.now().month}, ${DateTime.now().year}', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.4), fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                                        const SizedBox(width: 6),
                                        Text('Thu nhập', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(_fmt(_totalIncome, isDetailed), style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_downward, color: Colors.redAccent, size: 14),
                                        const SizedBox(width: 6),
                                        Text('Chi tiêu', style: TextStyle(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(_fmt(_totalExpense, isDetailed), style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w700)),
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
                      _buildQuickAction('Thêm\nthu', Icons.add_circle_outline, 'journal', theme),
                      _buildQuickAction('Thêm\nchi', Icons.remove_circle_outline, 'journal', theme),
                      _buildQuickAction('Kế\nhoạch', Icons.description_outlined, 'plan', theme),
                      _buildQuickAction('Báo\ncáo', Icons.bar_chart, 'reports', theme),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart
                  _buildChart(theme),
                  const SizedBox(height: 16),
                  
                  // Budget Progress
                  if (_plans.isNotEmpty) _buildBudgetProgress(theme, isDetailed),
                  if (_plans.isNotEmpty) const SizedBox(height: 16),
                  
                  // Recent Transactions
                  if (_recentTransactions.isNotEmpty) _buildRecentTransactions(theme, isDetailed),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, String? screenTarget, ThemeData theme) {
    return GestureDetector(
      onTap: screenTarget != null ? () => widget.onNavigate(screenTarget) : null,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: theme.primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 10, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thu chi 6 tháng', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
              Row(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Thu', style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Chi', style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
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
                      color: theme.dividerColor,
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
                        final style = TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10);
                        Widget text;
                        int idx = value.toInt();
                        if (idx >= 0 && idx < _chartLabels.length) {
                          text = Text(_chartLabels[idx], style: style);
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
                      interval: (_chartMaxY / 5) > 0 ? (_chartMaxY / 5).ceilToDouble() : 10,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text('${value.toInt()}M', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: _chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: _expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(ThemeData theme, bool isDetailed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ngân sách tháng', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
              GestureDetector(
                onTap: () => widget.onNavigate('plan'),
                child: Text('Xem thêm →', style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._plans.take(3).map((p) => _buildBudgetItem(p.category, _categorySpentThisMonth[p.category] ?? 0, p.plannedAmount, theme, isDetailed)),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(String cat, double spent, double budget, ThemeData theme, bool isDetailed) {
    double pct = budget > 0 ? (spent / budget) * 100 : 0;
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
                  Icon(Icons.flag_outlined, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(cat, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
                  if (over) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(6)),
                      child: Text('Vượt!', style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              Text(
                '${_fmtCompact(spent, isDetailed)}/${_fmtCompact(budget, isDetailed)}',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
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
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, bool isDetailed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giao dịch gần đây', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 14)),
              GestureDetector(
                onTap: () => widget.onNavigate('journal'),
                child: Text('Tất cả →', style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._recentTransactions.map((t) {
            bool isIncome = t.type.toLowerCase() == 'income';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
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
                        Text(t.note?.isNotEmpty == true ? t.note! : 'Giao dịch', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
                        Text('${t.category} · ${t.transactionDate.day.toString().padLeft(2, '0')}/${t.transactionDate.month.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? "+" : "-"}${_fmtCompact(t.amount, isDetailed)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? Colors.green : Colors.red,
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
