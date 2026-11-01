import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsentLogsTab extends StatefulWidget {
  const ConsentLogsTab({super.key});

  @override
  State<ConsentLogsTab> createState() => _ConsentLogsTabState();
}

class _ConsentLogsTabState extends State<ConsentLogsTab> {
  List<dynamic> _logs = [];
  final Map<String, String> _userEmails = {};

  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = true;
  dynamic _selectedLog;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _copySelectedLog() async {
    if (_selectedLog == null) return;
    final log = _selectedLog;
    final buffer = StringBuffer();
    buffer.writeln('معرف السجل: ${log['id'] ?? ''}');
    buffer.writeln('التاريخ: ${log['created_at'] ?? ''}');
    buffer.writeln(
        'الإيميل: ${log['user_email'] ?? _userEmails[log['user_id']] ?? ''}');
    buffer.writeln('نوع الموافقة: ${log['consent_type'] ?? ''}');
    buffer
        .writeln('تمت الموافقة: ${log['is_accepted'] == true ? 'نعم' : 'لا'}');
    buffer.writeln('إصدار الشروط: ${log['consent_version'] ?? ''}');
    buffer.writeln('إصدار التطبيق: ${log['app_version'] ?? ''}');
    buffer.writeln('الطريقة: ${log['method'] ?? ''}');
    buffer.writeln('عنوان IP: ${log['ip_address'] ?? ''}');
    buffer.writeln('User Agent: ${log['user_agent'] ?? ''}');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم نسخ بيانات السطر', textAlign: TextAlign.right)),
    );
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final supabase = Supabase.instance.client;

      // RLS يسمح بالقراءة للمسؤول فقط؛ نتحقق لنشرح السبب عند الفراغ.
      final me = supabase.auth.currentUser;
      debugPrint('🔎 [Consent] المستخدم الحالي: ${me?.email} | id=${me?.id}');
      if (me != null) {
        try {
          final meRow = await supabase
              .from('users')
              .select('is_admin')
              .eq('id', me.id)
              .maybeSingle();
          _isAdmin = meRow?['is_admin'] == true;
          debugPrint('🔎 [Consent] is_admin = $_isAdmin');
        } catch (e) {
          debugPrint('⚠️ [Consent] تعذر قراءة is_admin: $e');
          _isAdmin = true;
        }
      } else {
        debugPrint('⚠️ [Consent] لا توجد جلسة Supabase (currentUser = null)');
      }

      // جلب الإيميلات اختياري: فشله لا يمنع عرض السجلات.
      try {
        final usersData = await supabase.from('users').select('id, email');
        for (final user in usersData) {
          _userEmails[user['id'].toString()] =
              (user['email'] ?? 'إيميل غير معروف').toString();
        }
        debugPrint(
            '🔎 [Consent] تم جلب ${_userEmails.length} إيميل من جدول users');
      } catch (e) {
        debugPrint('⚠️ [Consent] تعذر جلب إيميلات المستخدمين: $e');
      }

      final logsData = await supabase
          .from('consent_logs')
          .select()
          .order('created_at', ascending: false);

      debugPrint('🔎 [Consent] عدد سجلات الموافقة المرجعة: ${logsData.length}');
      if (logsData.isEmpty) {
        debugPrint(
            '⚠️ [Consent] رجع 0 صف. الاحتمالان: الجدول فارغ فعلًا، أو RLS يمنع القراءة (is_admin=$_isAdmin).');
      } else {
        debugPrint('🔎 [Consent] أول سجل: ${logsData.first}');
      }

      if (!mounted) return;
      setState(() => _logs = logsData);
    } catch (e) {
      debugPrint('❌ [Consent] فشل جلب السجلات: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _safeText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'غير متوفر';
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return 'غير متوفر';
    final date = parsed.toLocal();
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}/${date.month}/${date.day} - ${date.hour}:$minute';
  }

  List<DataRow> _buildRows() {
    return _logs.map((log) {
      final email = _safeText(log['user_email'],
          _safeText(_userEmails[log['user_id']?.toString()], 'مجهول'));
      final isSelected = _selectedLog != null && _selectedLog['id'] == log['id'];

      return DataRow(
        selected: isSelected,
        onSelectChanged: (selected) {
          setState(() {
            _selectedLog = (selected ?? false) ? log : null;
          });
        },
        cells: [
          DataCell(Text(_formatDate(log['created_at']),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(email, style: const TextStyle(color: Colors.blue))),
          DataCell(Text(_safeText(log['consent_type'], 'غير محدد'))),
          DataCell(Text(log['is_accepted'] == true ? 'نعم' : 'لا')),
          DataCell(Text(_safeText(log['consent_version'], 'غير محدد'))),
          DataCell(Text(_safeText(log['app_version'], 'غير متوفر'))),
          DataCell(Text(_safeText(log['method'], 'غير محدد'))),
          DataCell(Text(_safeText(log['ip_address'], 'غير متوفر'),
              style: const TextStyle(color: Colors.grey))),
          DataCell(Text(_safeText(log['user_agent'], 'غير متوفر'),
              style: const TextStyle(color: Colors.grey))),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('تعذر جلب سجلات الموافقة:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red)),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('لا توجد سجلات موافقة حالياً.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              if (!_isAdmin) ...[
                const SizedBox(height: 12),
                const Text(
                  'ملاحظة: حسابك الحالي غير مُعلَّم كمسؤول (is_admin = false)،\n'
                  'وسياسة RLS تمنع غير المسؤول من قراءة جدول consent_logs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'سجلات موافقة المستخدمين (${_logs.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey),
                      ),
                    ),
                    if (_selectedLog != null)
                      TextButton.icon(
                        onPressed: _copySelectedLog,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('نسخ السطر'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      onPressed: _fetchLogs,
                      tooltip: 'تحديث',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      notificationPredicate: (notification) =>
                          notification.depth == 0,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text('تاريخ ووقت الموافقة')),
                            DataColumn(label: Text('إيميل المستخدم')),
                            DataColumn(label: Text('نوع الموافقة')),
                            DataColumn(label: Text('مقبولة؟')),
                            DataColumn(label: Text('إصدار الشروط')),
                            DataColumn(label: Text('إصدار التطبيق')),
                            DataColumn(label: Text('الطريقة')),
                            DataColumn(label: Text('عنوان IP')),
                            DataColumn(label: Text('User Agent')),
                          ],
                          rows: _buildRows(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
