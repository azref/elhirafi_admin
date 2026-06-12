import 'package:elhirafi_admin/tabs/consent_logs_tab.dart';
import 'package:elhirafi_admin/tabs/notifications_tab.dart';
import 'package:elhirafi_admin/tabs/reports_tab.dart';
// ⬅️ استخدام المسارات المطلقة (Package Imports) لكي لا يضيع المحرر
import 'package:elhirafi_admin/tabs/statistics_tab.dart';
import 'package:elhirafi_admin/tabs/users_tab.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('غرفة العمليات - الإدارة',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey[900],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات العامة'),
              Tab(icon: Icon(Icons.report), text: 'إدارة البلاغات'),
              Tab(icon: Icon(Icons.verified_user), text: 'سجلات الموافقة'),
              Tab(icon: Icon(Icons.people), text: 'إدارة المستخدمين'),
              Tab(
                  icon: Icon(Icons.notifications_active),
                  text: 'إرسال إشعارات'),
            ],
          ),
          actions: [
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
        body: const TabBarView(
          children: [
            StatisticsTab(),
            ReportsTab(),
            ConsentLogsTab(),
            UsersTab(),
            NotificationsTab(),
          ],
        ),
      ),
    );
  }
}
