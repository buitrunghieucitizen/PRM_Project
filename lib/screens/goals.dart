import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Goals extends StatefulWidget {
  const Goals({super.key});

  @override
  State<Goals> createState() => _GoalsState();
}

class _GoalsState extends State<Goals> {
  final List<Map<String, dynamic>> _goals = [
    {
      'id': 1,
      'name': 'Mua nhà',
      'emoji': '🏠',
      'color': const Color(0xFF0D9488),
      'target': 800000000.0,
      'current': 120000000.0,
      'monthly': 8000000.0,
      'aiMonths': 85,
      'aiTip': 'Tăng lên 12M/tháng → rút ngắn còn tháng 8/2030',
      'projection': [
        {'m': 'T6/26', 'v': 120.0}, {'m': 'T12/26', 'v': 216.0}, {'m': 'T6/27', 'v': 312.0},
        {'m': 'T12/27', 'v': 408.0}, {'m': 'T6/28', 'v': 504.0}, {'m': 'T12/28', 'v': 600.0},
        {'m': 'T6/29', 'v': 696.0}, {'m': 'T12/29', 'v': 792.0}, {'m': 'T3/30', 'v': 800.0},
      ],
    },
    {
      'id': 2,
      'name': 'Quỹ khẩn cấp',
      'emoji': '🛡️',
      'color': const Color(0xFF10B981),
      'target': 100000000.0,
      'current': 45000000.0,
      'monthly': 5000000.0,
      'aiMonths': 11,
      'aiTip': 'Đang tiến rất tốt! Hoàn thành vào tháng 5/2027',
      'projection': [
        {'m': 'T6/26', 'v': 45.0}, {'m': 'T9/26', 'v': 60.0}, {'m': 'T12/26', 'v': 75.0},
        {'m': 'T3/27', 'v': 90.0}, {'m': 'T5/27', 'v': 100.0},
      ],
    },
    {
      'id': 3,
      'name': 'Du lịch Châu Âu',
      'emoji': '✈️',
      'color': const Color(0xFF3B82F6),
      'target': 80000000.0,
      'current': 15000000.0,
      'monthly': 3000000.0,
      'aiMonths': 22,
      'aiTip': 'Tăng lên 5M/tháng → đi hè 2027 như kế hoạch',
      'projection': [
        {'m': 'T6/26', 'v': 15.0}, {'m': 'T12/26', 'v': 33.0},
        {'m': 'T6/27', 'v': 51.0}, {'m': 'T12/27', 'v': 69.0}, {'m': 'T4/28', 'v': 80.0},
      ],
    },
  ];

  final List<Map<String, dynamic>> _initMessages = [
    {'role': 'assistant', 'text': 'Xin chào! 🎯 Tôi phân tích mục tiêu tài chính và dự đoán thời gian đạt được dựa trên dữ liệu thực.'},
    {'role': 'assistant', 'text': '📊 Tóm tắt:\n• Mua nhà: 15% - ~85 tháng\n• Quỹ khẩn cấp: 45% - ~11 tháng ✅\n• Du lịch: 19% - ~22 tháng\n\nƯu tiên hoàn thiện Quỹ khẩn cấp trước!'},
  ];

  late Map<String, dynamic> _selected;
  bool _showAI = false;
  bool _showAdd = false;
  late List<Map<String, dynamic>> _messages;
  final TextEditingController _chatController = TextEditingController();
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _selected = _goals[0];
    _messages = List.from(_initMessages);
  }

  String _fmt(double n, [bool short = false]) {
    if (short) {
      if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}T';
      if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(0)}M';
      return '${(n / 1e3).toStringAsFixed(0)}K';
    }
    // Very simple formatting for VND
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + ' ₫';
  }

  void _handleSend() {
    String text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _thinking = true;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final List<String> r = [
        "Với mục tiêu **${_selected['name']}**: nếu tăng tiết kiệm thêm 2M/tháng, đạt sớm hơn 12 tháng so với dự kiến.",
        "Rủi ro lạm phát ~4%/năm. Nên đặt mục tiêu dự phòng +10% để đảm bảo đủ vốn.",
        "Tỷ lệ hoàn thành hiện tại ${((_selected['current'] / _selected['target']) * 100).round()}%. Hãy đặt auto-transfer vào ngày 1 hàng tháng!",
      ];
      setState(() {
        _messages.add({'role': 'assistant', 'text': r[DateTime.now().millisecond % r.length]});
        _thinking = false;
      });
    });
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
                            Text('Theo dõi & dự đoán với AI', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showAI = true),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.auto_awesome, color: Color(0xFF2DD4BF), size: 17),
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
                    Row(
                      children: _goals.map((g) {
                        int pct = ((g['current'] / g['target']) * 100).round();
                        bool isSelected = _selected['id'] == g['id'];
                        Color gColor = g['color'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = g),
                            child: Container(
                              margin: EdgeInsets.only(right: g['id'] != _goals.last['id'] ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? gColor : Colors.white.withOpacity(0.07),
                                border: Border.all(color: isSelected ? gColor : Colors.transparent, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(g['emoji'] as String, style: const TextStyle(fontSize: 20)),
                                  Text('$pct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'DM Mono')),
                                  Text(g['name'] as String, style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B), fontSize: 10), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
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
                                  color: (_selected['color'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(_selected['emoji'] as String, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selected['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('Dự kiến ~${_selected['aiMonths']} tháng', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                '${((_selected['current'] / _selected['target']) * 100).round()}%',
                                style: TextStyle(fontWeight: FontWeight.w800, color: _selected['color'], fontSize: 18, fontFamily: 'DM Mono'),
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
                              widthFactor: (_selected['current'] / _selected['target']).clamp(0.0, 1.0) as double,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selected['color'] as Color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(_selected['current'], true), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'DM Mono')),
                              Text(_fmt(_selected['target'], true), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontFamily: 'DM Mono')),
                            ],
                          ),
                          
                          // AI tip
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 13),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.5),
                                      children: [
                                        const TextSpan(text: 'AI: ', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                                        TextSpan(text: _selected['aiTip'] as String),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                      const Text('Tiết kiệm/tháng', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text('${_fmt(_selected['monthly'], true)} ₫', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14, fontFamily: 'DM Mono')),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                      Text('${_fmt(_selected['target'] - _selected['current'], true)} ₫', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF43F5E), fontSize: 14, fontFamily: 'DM Mono')),
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

                    // Projection chart
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📈 Dự báo tiến độ', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: _buildProjectionChart(),
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
                          ..._goals.asMap().entries.map((e) {
                            int i = e.key;
                            var g = e.value;
                            int pct = ((g['current'] / g['target']) * 100).round();
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
                                        color: (g['color'] as Color).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(g['emoji'] as String, style: const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(g['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14)),
                                              Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: g['color'], fontSize: 13, fontFamily: 'DM Mono')),
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
                                              widthFactor: (g['current'] / g['target']).clamp(0.0, 1.0) as double,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: g['color'] as Color,
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

        // AI drawer
        if (_showAI) _buildAIDrawer(),

        // Add modal
        if (_showAdd) _buildAddModal(),
      ],
    );
  }

  Widget _buildProjectionChart() {
    List proj = _selected['projection'];
    List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < proj.length; i++) {
      double val = proj[i]['v'].toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
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
                int index = value.toInt();
                if (index < 0 || index >= proj.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(proj[index]['m'] as String, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text('${value.toInt()}M', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (proj.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: _selected['color'] as Color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(radius: 4, color: _selected['color'] as Color, strokeWidth: 0);
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDrawer() {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AI Tư vấn mục tiêu', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                        Text('● Phân tích thời gian thực', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showAI = false),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _thinking) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 36),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                            child: const Text('...', style: TextStyle(color: Color(0xFF374151), fontSize: 14, letterSpacing: 2)),
                          ),
                        ],
                      ),
                    );
                  }
                  final m = _messages[index];
                  bool isUser = m['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.smart_toy, color: Colors.white, size: 13),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              m['text'] as String,
                              style: TextStyle(color: isUser ? Colors.white : const Color(0xFF374151), fontSize: 14, height: 1.4),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 36),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Phân tích mục tiêu', 'Tăng tốc tiết kiệm', 'Dự báo rủi ro'].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _chatController.text = s;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              border: Border.all(color: const Color(0xFFCCFBF1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(s, style: const TextStyle(color: Color(0xFF0D9488), fontSize: 12)),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Hỏi về mục tiêu...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.send, color: Colors.white, size: 16),
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
                onPressed: () => setState(() => _showAdd = false),
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
