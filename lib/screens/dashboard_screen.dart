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
          PopupMenuButton<String>(
            tooltip: 'خيارات الحساب',
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'password') {
                await _showChangePasswordDialog();
              } else if (value == 'reset') {
                await _sendPasswordResetLink();
              } else if (value == 'account') {
                _showAccountInfo();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'account',
                child: Text('معلومات الحساب'),
              ),
              PopupMenuItem<String>(
                value: 'password',
                child: Text('تغيير كلمة المرور'),
              ),
              PopupMenuItem<String>(
                value: 'reset',
                child: Text('إرسال رابط استعادة كلمة المرور'),
              ),
            ],
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

  // ═══════════════════════════════════════════════════════════
  // خيارات حساب المسؤول (قائمة الثلاث نقاط)
  // ═══════════════════════════════════════════════════════════
  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: color,
      ),
    );
  }

  void _showAccountInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('معلومات الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('البريد: ${user?.email ?? 'غير متوفر'}'),
              const SizedBox(height: 8),
              Text('المعرّف: ${user?.id ?? 'غير متوفر'}'),
              const SizedBox(height: 8),
              Text('آخر دخول: ${user?.lastSignInAt ?? 'غير متوفر'}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetLink() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnack('لا يوجد بريد مرتبط بالحساب الحالي.', Colors.orange);
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showSnack('تم إرسال رابط الاستعادة إلى: $email', Colors.green);
    } catch (e) {
      _showSnack('تعذر إرسال الرابط: $e', Colors.red);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  helperText: '8 أحرف على الأقل',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;
    if (passwordCtrl.text.length < 8) {
      _showSnack('كلمة المرور قصيرة جدًا (8 أحرف على الأقل).', Colors.orange);
      return;
    }
    if (passwordCtrl.text != confirmCtrl.text) {
      _showSnack('كلمتا المرور غير متطابقتين.', Colors.orange);
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: passwordCtrl.text),
      );
      _showSnack('تم تحديث كلمة المرور بنجاح.', Colors.green);
    } on AuthException catch (e) {
      final bool needsMfa =
          e.code == 'insufficient_aal' || e.message.contains('AAL2');
      _showSnack(
        needsMfa
            ? 'الحساب محمي بـ MFA: استخدم "إرسال رابط استعادة كلمة المرور" أو غيّرها من لوحة Supabase.'
            : e.message,
        needsMfa ? Colors.orange : Colors.red,
      );
    } catch (e) {
      _showSnack('تعذر تغيير كلمة المرور: $e', Colors.red);
    }
  }
}
