import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _urlController =
      TextEditingController(); // رابط اختياري (مثل رابط المتجر للتحديث)

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    final restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];

    if (appId == null ||
        restApiKey == null ||
        appId.isEmpty ||
        restApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: مفاتيح OneSignal غير موجودة في ملف .env',
              textAlign: TextAlign.right),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'included_segments': ['All'], // ⬅️ إرسال لجميع المستخدمين
          'headings': {
            'en': _titleController.text,
            'ar': _titleController.text
          },
          'contents': {
            'en': _messageController.text,
            'ar': _messageController.text
          },
          if (_urlController.text.isNotEmpty)
            'url': _urlController.text, // ⬅️ رابط عند الضغط على الإشعار
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الإشعار لجميع المستخدمين بنجاح! 🚀',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.green,
            ),
          );
          // تفريغ الحقول بعد النجاح
          _titleController.clear();
          _messageController.clear();
          _urlController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إرسال الإشعار: ${response.body}',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('حدث خطأ أثناء الاتصال: $e', textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: 600, // عرض ثابت لتبدو كبطاقة أنيقة
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 5)
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'إرسال إشعار للجميع (Broadcast)',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيصل هذا الإشعار إلى جميع هواتف المستخدمين (حرفيين وعملاء) فوراً.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 📝 حقل العنوان
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار (مثال: تحديث جديد متاح!)',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'يرجى كتابة عنوان الإشعار' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // 📝 حقل النص
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'نص الإشعار (مثال: يرجى تحديث التطبيق للاستفادة من الميزات الجديدة)',
                      prefixIcon: Padding(
                        padding:
                            EdgeInsets.only(bottom: 60), // لرفع الأيقونة للأعلى
                        child: Icon(Icons.message),
                      ),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'يرجى كتابة نص الإشعار' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔗 حقل الرابط (اختياري)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText:
                          'رابط التوجيه (اختياري - مثال: رابط متجر جوجل بلاي)',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 🚀 زر الإرسال
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _sendNotification,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(
                      _isLoading ? 'جاري الإرسال...' : 'إرسال الإشعار الآن',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
