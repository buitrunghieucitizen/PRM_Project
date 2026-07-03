import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final Function(String) onNavigate;

  const BottomNav({super.key, required this.active, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'dashboard', 'label': 'Tổng quan', 'icon': Icons.dashboard_outlined},
      {'id': 'journal', 'label': 'Nhật ký', 'icon': Icons.menu_book_outlined},
      {'id': 'plan', 'label': 'Kế hoạch', 'icon': Icons.calendar_today_outlined},
      {'id': 'reports', 'label': 'Báo cáo', 'icon': Icons.bar_chart_outlined},
      {'id': 'goals', 'label': 'Mục tiêu', 'icon': Icons.track_changes_outlined},
    ];

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          bool isActive = active == tab['id'];
          IconData icon = tab['icon'] as IconData;
          return Expanded(
            child: GestureDetector(
              onTap: () => onNavigate(tab['id'] as String),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF0D9488) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 20,
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
