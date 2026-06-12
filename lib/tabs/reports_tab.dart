import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<dynamic> _reports = [];
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final usersData = await supabase.from('users').select('id, email');
      for (var user in usersData) {
        _userNames[user['id']] = user['email'] ?? 'إيميل غير معروف';
      }
      final reportsData = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _reports = reportsData;
      });
    } catch (e) {
      debugPrint('خطأ في جلب البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _banUser(String userId, String reportId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('users').update({'is_banned': true}).eq('id', userId);
      await supabase
          .from('reports')
          .update({'status': 'banned'}).eq('id', reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('تم حظر المستخدم بنجاح 🚫', textAlign: TextAlign.right),
              backgroundColor: Colors.green),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('حدث خطأ: $e', textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'dismissed'}).eq('id', reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تجاهل البلاغ', textAlign: TextAlign.right)),
        );
      }
      _fetchData();
    } catch (e) {
      debugPrint('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty)
      return const Center(
          child: Text('لا توجد بلاغات حالياً. التطبيق آمن! 🎉',
              style: TextStyle(fontSize: 20, color: Colors.green)));

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
                    const Text('قائمة البلاغات الأخيرة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _fetchData,
                        tooltip: 'تحديث'),
                  ],
                ),
                rowsPerPage: _reports.length > 10
                    ? 10
                    : (_reports.isEmpty ? 1 : _reports.length),
                columns: const [
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('إيميل المُبلِّغ (الضحية)')),
                  DataColumn(label: Text('إيميل المُبلَّغ عنه (المسيء)')),
                  DataColumn(label: Text('السبب')),
                  DataColumn(label: Text('التفاصيل')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('الإجراءات')),
                ],
                source: _ReportDataSource(
                  reports: _reports,
                  userNames: _userNames,
                  onBan: _banUser,
                  onDismiss: _dismissReport,
                  onRefresh: _fetchData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDataSource extends DataTableSource {
  final List<dynamic> reports;
  final Map<String, String> userNames;
  final Function(String, String) onBan;
  final Function(String) onDismiss;
  final VoidCallback onRefresh;

  _ReportDataSource({
    required this.reports,
    required this.userNames,
    required this.onBan,
    required this.onDismiss,
    required this.onRefresh,
  });

  Future<void> _unbanUser(
      BuildContext context, String userId, String reportId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('users')
          .update({'is_banned': false}).eq('id', userId);
      await supabase
          .from('reports')
          .update({'status': 'unbanned'}).eq('id', reportId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم رفع الحظر عن المستخدم بنجاح ✅',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.green),
        );
      }
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('حدث خطأ أثناء رفع الحظر: $e',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  DataRow? getRow(int index) {
    if (index >= reports.length) return null;
    final report = reports[index];

    final date = DateTime.parse(report['created_at']).toLocal();
    final formattedDate = '${date.year}/${date.month}/${date.day}';

    final reporterName = userNames[report['reporter_id']] ?? 'مجهول';
    final reportedName = userNames[report['reported_user_id']] ?? 'مجهول';
    final status = report['status'] ?? 'pending';

    Widget statusWidget;
    if (status == 'banned') {
      statusWidget = _buildStatusBadge('تم الحظر', Colors.red);
    } else if (status == 'dismissed') {
      statusWidget = _buildStatusBadge('تم التجاهل', Colors.grey);
    } else if (status == 'unbanned') {
      statusWidget = _buildStatusBadge('رُفع الحظر', Colors.blue);
    } else {
      statusWidget = _buildStatusBadge('معلق', Colors.orange);
    }

    return DataRow(cells: [
      DataCell(Text(formattedDate)),
      DataCell(Tooltip(
          message: reporterName,
          child: SizedBox(
              width: 150,
              child: Text(reporterName,
                  style: const TextStyle(color: Colors.blue),
                  overflow: TextOverflow.ellipsis)))),
      DataCell(Tooltip(
          message: reportedName,
          child: SizedBox(
              width: 150,
              child: Text(reportedName,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis)))),
      DataCell(Text(report['reason'] ?? '')),
      DataCell(Tooltip(
          message: report['description'] ?? 'لا يوجد',
          child: SizedBox(
              width: 200,
              child: Text(report['description'] ?? 'لا يوجد',
                  overflow: TextOverflow.ellipsis)))),
      DataCell(statusWidget),
      DataCell(
        Builder(builder: (context) {
          if (status == 'pending') {
            return Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      onBan(report['reported_user_id'], report['id']),
                  child: const Text('حظر المسيء'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: () => onDismiss(report['id']),
                    child: const Text('تجاهل')),
              ],
            );
          } else if (status == 'banned') {
            return TextButton.icon(
              icon: const Icon(Icons.restore, color: Colors.blue),
              label:
                  const Text('رفع الحظر', style: TextStyle(color: Colors.blue)),
              onPressed: () =>
                  _unbanUser(context, report['reported_user_id'], report['id']),
            );
          } else {
            return const Text('لا يوجد إجراء',
                style: TextStyle(color: Colors.grey));
          }
        }),
      ),
    ]);
  }

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color[100], borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: color[800], fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => reports.length;
  @override
  int get selectedRowCount => 0;
}
