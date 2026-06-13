import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  // متحكمات الإشعار العام
  final _allTitleCtrl = TextEditingController();
  final _allMessageCtrl = TextEditingController();
  bool _isSendingAll = false;

  // متحكمات الإشعار المخصص
  final _targetEmailCtrl = TextEditingController();
  final _targetTitleCtrl = TextEditingController();
  final _targetMessageCtrl = TextEditingController();
  bool _isSendingTarget = false;

  @override
  void dispose() {
    _allTitleCtrl.dispose();
    _allMessageCtrl.dispose();
    _targetEmailCtrl.dispose();
    _targetTitleCtrl.dispose();
    _targetMessageCtrl.dispose();
    super.dispose();
  }

  // 🚀 دالة إرسال الإشعار عبر OneSignal API
  Future<void> _sendPushNotification({
    required String title,
    required String message,
    String? targetUserId, // إذا كان null، يُرسل للجميع
  }) async {
    // ⬅️ قراءة المفاتيح من بيئة البناء مباشرة (أمان تام)
    const appId = String.fromEnvironment('ONESIGNAL_APP_ID');
    const restApiKey = String.fromEnvironment('ONESIGNAL_REST_API_KEY');

    if (appId.isEmpty || restApiKey.isEmpty) {
      throw Exception('مفاتيح OneSignal غير متوفرة في بيئة البناء.');
    }

    final Map<String, dynamic> payload = {
      "app_id": appId,
      "headings": {"en": title, "ar": title},
      "contents": {"en": message, "ar": message},
    };

    if (targetUserId != null) {
      // إرسال لمستخدم محدد عبر الـ ID الخاص به في Supabase
      payload["include_external_user_ids"] = [targetUserId];
    } else {
      // إرسال للجميع
      payload["included_segments"] = ["All"];
    }

    final response = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $restApiKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل الإرسال: ${response.body}');
    }
  }

  // 📢 معالج الإرسال للجميع
  Future<void> _handleSendToAll() async {
    if (_allTitleCtrl.text.isEmpty || _allMessageCtrl.text.isEmpty) {
      _showSnackBar('يرجى تعبئة العنوان والرسالة', Colors.orange);
      return;
    }

    setState(() => _isSendingAll = true);
    try {
      await _sendPushNotification(
        title: _allTitleCtrl.text.trim(),
        message: _allMessageCtrl.text.trim(),
      );
      _showSnackBar(
          'تم إرسال الإشعار لجميع المستخدمين بنجاح! 🚀', Colors.green);
      _allTitleCtrl.clear();
      _allMessageCtrl.clear();
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isSendingAll = false);
    }
  }

  // 🎯 معالج الإرسال لمستخدم محدد (المسيء)
  Future<void> _handleSendToTarget() async {
    final email = _targetEmailCtrl.text.trim();
    if (email.isEmpty ||
        _targetTitleCtrl.text.isEmpty ||
        _targetMessageCtrl.text.isEmpty) {
      _showSnackBar('يرجى تعبئة الإيميل، العنوان، والرسالة', Colors.orange);
      return;
    }

    setState(() => _isSendingTarget = true);
    try {
      // 1. البحث عن المستخدم في Supabase بواسطة الإيميل
      final userRes = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userRes == null) {
        throw Exception('لم يتم العثور على مستخدم بهذا البريد الإلكتروني.');
      }

      final targetUserId = userRes['id'];

      // 2. إرسال الإشعار لهذا المستخدم فقط
      await _sendPushNotification(
        title: _targetTitleCtrl.text.trim(),
        message: _targetMessageCtrl.text.trim(),
        targetUserId: targetUserId,
      );

      _showSnackBar('تم إرسال الإشعار للمستخدم بنجاح! 🎯', Colors.green);
      _targetEmailCtrl.clear();
      _targetTitleCtrl.clear();
      _targetMessageCtrl.clear();
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isSendingTarget = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مركز الإشعارات والتنبيهات 🔔',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 🟦 بطاقة الإرسال للجميع (تحديثات، أخبار)
            // ==========================================
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign,
                            color: Colors.blue.shade700, size: 30),
                        const SizedBox(width: 10),
                        Text('إشعار عام (لجميع المستخدمين)',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'يستخدم لإرسال التحديثات، الأخبار، أو العروض لجميع من يمتلك التطبيق.',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: _allTitleCtrl,
                        label: 'عنوان الإشعار',
                        icon: Icons.title),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _allMessageCtrl,
                        label: 'نص الرسالة',
                        icon: Icons.message,
                        maxLines: 3),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingAll ? null : _handleSendToAll,
                        icon: _isSendingAll
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.send),
                        label: Text(_isSendingAll
                            ? 'جاري الإرسال...'
                            : 'إرسال للجميع الآن'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // 🟧 بطاقة الإرسال المخصص (إنذار مسيء)
            // ==========================================
            Card(
              elevation: 4,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade800, size: 30),
                        const SizedBox(width: 10),
                        Text('إنذار مخصص (الرد على مسيء)',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'يستخدم لإرسال تنبيه أو إنذار لمستخدم محدد بناءً على بريده الإلكتروني.',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: _targetEmailCtrl,
                        label: 'البريد الإلكتروني للمستخدم',
                        icon: Icons.email,
                        isEmail: true),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _targetTitleCtrl,
                        label: 'عنوان الإنذار',
                        icon: Icons.title),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _targetMessageCtrl,
                        label: 'نص الإنذار',
                        icon: Icons.message,
                        maxLines: 3),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSendingTarget ? null : _handleSendToTarget,
                        icon: _isSendingTarget
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.send_and_archive),
                        label: Text(_isSendingTarget
                            ? 'جاري الإرسال...'
                            : 'إرسال الإنذار للمستخدم'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 دالة مساعدة لبناء حقول الإدخال بشكل أنيق
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isEmail = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueGrey, width: 2)),
      ),
    );
  }
}
