import 'package:elhirafi_admin/tabs/consent_logs_tab.dart';
import 'package:elhirafi_admin/tabs/notifications_tab.dart';
import 'package:elhirafi_admin/tabs/reports_tab.dart';
// ⬅️ استخدام المسارات المطلقة (Package Imports) لكي لا يضيع المحرر
import 'package:elhirafi_admin/tabs/statistics_tab.dart';
import 'package:elhirafi_admin/tabs/users_tab.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart'; // ⬅️ استيراد main للوصول إلى themeNotifier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _targetEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToNotifications(String email) {
    setState(() {
      _targetEmail = email;
    });
    _tabController.animateTo(4); // ⬅️ الانتقال لتبويب الإشعارات (الفهرس 4)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غرفة العمليات - الإدارة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        bottom: TabBar(
          controller: _tabController, // ⬅️ ربط المتحكم
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات العامة'),
            Tab(icon: Icon(Icons.report), text: 'إدارة البلاغات'),
            Tab(icon: Icon(Icons.verified_user), text: 'سجلات الموافقة'),
            Tab(icon: Icon(Icons.people), text: 'إدارة المستخدمين'),
            Tab(icon: Icon(Icons.notifications_active), text: 'إرسال إشعارات'),
          ],
        ),
        actions: [
          // ⬅️ زر تبديل الثيم
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white),
                tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                onPressed: () {
                  themeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          )
        ],
      ),
      // ⬅️ أزلنا كلمة const من هنا لكي لا تسبب أي تعارض
      body: TabBarView(
        controller: _tabController, // ⬅️ ربط المتحكم
        children: [
          const StatisticsTab(),
          ReportsTab(
              onContactUser: _goToNotifications), // ⬅️ تمرير دالة الانتقال
          const ConsentLogsTab(),
          const UsersTab(),
          NotificationsTab(targetEmail: _targetEmail), // ⬅️ تمرير الإيميل
        ],
      ),
    );
  }
}
