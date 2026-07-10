import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 32),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'TN',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Trần Nam', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('nam.tran@financeai.com', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('Cài đặt chung'),
                _buildSettingsCard([
                  _buildSettingItem(Icons.person_outline, 'Thông tin cá nhân'),
                  _buildSettingItem(Icons.security, 'Bảo mật & Đăng nhập'),
                  _buildSettingItem(Icons.notifications_none, 'Thông báo'),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Dữ liệu & AI'),
                _buildSettingsCard([
                  _buildSettingItem(Icons.data_usage, 'Dữ liệu của tôi'),
                  _buildSettingItem(Icons.auto_awesome, 'Cấu hình AI tư vấn', color: const Color(0xFF0D9488)),
                ]),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Xử lý đăng xuất (Tương lai có thể map lại onLogout)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF43F5E),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFFFE4E6), width: 1.5),
                    ),
                  ),
                  child: const Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 13),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          int idx = e.key;
          Widget item = e.value;
          return Column(
            children: [
              item,
              if (idx < items.length - 1)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {Color color = const Color(0xFF0F172A)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }
}
