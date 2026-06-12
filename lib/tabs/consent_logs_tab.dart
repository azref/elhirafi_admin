import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final usersData = await supabase.from('users').select('id, email');
      for (var user in usersData) {
        _userEmails[user['id']] = user['email'] ?? 'إيميل غير معروف';
      }

      final logsData = await supabase
          .from('consent_logs')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _logs = logsData;
      });
    } catch (e) {
      debugPrint('خطأ في جلب سجلات الموافقة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return const Center(
          child: Text('لا توجد سجلات موافقة حالياً.',
              style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              PaginatedDataTable(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('سجلات موافقة المستخدمين',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _fetchLogs,
                        tooltip: 'تحديث'),
                  ],
                ),
                rowsPerPage:
                    _logs.length > 10 ? 10 : (_logs.isEmpty ? 1 : _logs.length),
                columns: const [
                  DataColumn(label: Text('تاريخ ووقت الموافقة')),
                  DataColumn(label: Text('إيميل المستخدم')),
                  DataColumn(label: Text('إصدار الشروط')),
                  DataColumn(label: Text('عنوان IP (إن وجد)')),
                ],
                source: _ConsentDataSource(_logs, _userEmails),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentDataSource extends DataTableSource {
  final List<dynamic> logs;
  final Map<String, String> userEmails;

  _ConsentDataSource(this.logs, this.userEmails);

  @override
  DataRow? getRow(int index) {
    if (index >= logs.length) return null;
    final log = logs[index];

    final date = DateTime.parse(log['created_at']).toLocal();
    final formattedDate =
        '${date.year}/${date.month}/${date.day} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    final email = userEmails[log['user_id']] ?? 'مجهول';

    return DataRow(cells: [
      DataCell(Text(formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(email, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(log['consent_version'] ?? 'غير محدد')),
      DataCell(Text(log['ip_address'] ?? 'غير متوفر',
          style: const TextStyle(color: Colors.grey))),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => logs.length;
  @override
  int get selectedRowCount => 0;
}
