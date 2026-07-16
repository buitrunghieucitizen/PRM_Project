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
      {'id': 'profile', 'label': 'Hồ sơ', 'icon': Icons.person_outline},
    ];

    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                  Icon(
                    icon,
                    size: 22,
                    color: isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
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
