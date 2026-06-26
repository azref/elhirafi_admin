import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsTab extends StatefulWidget {
  final Function(String)? onContactUser;

  const ReportsTab({super.key, this.onContactUser});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<dynamic> _reports = [];
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  // ⬅️ إضافة متحكمات التمرير للاتجاهين
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    // ⬅️ تنظيف المتحكمات لتجنب تسريب الذاكرة
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
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

  Future<void> _unbanUser(String userId, String reportId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('users')
          .update({'is_banned': false}).eq('id', userId);
      await supabase
          .from('reports')
          .update({'status': 'unbanned'}).eq('id', reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم رفع الحظر عن المستخدم بنجاح ✅',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.green),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
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
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) {
      return const Center(
          child: Text('لا توجد بلاغات حالياً. التطبيق آمن! 🎉',
              style: TextStyle(fontSize: 20, color: Colors.green)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // رأس الجدول مع زر التحديث
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('قائمة البلاغات الأخيرة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blueGrey)),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _fetchData,
                        tooltip: 'تحديث'),
                  ],
                ),
              ),
              // ⬅️ شريط السحب الدائم الظهور مع الجدول (تم ربط المتحكمات بدقة)
              Expanded(
                child: Scrollbar(
                  controller: _verticalScroll, // ربط المتحكم العمودي
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 8.0,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _verticalScroll, // ربط المتحكم العمودي
                    scrollDirection: Axis.vertical,
                    physics:
                        const AlwaysScrollableScrollPhysics(), // إجبار التمرير ليكون مرناً
                    child: Scrollbar(
                      controller: _horizontalScroll, // ربط المتحكم الأفقي
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      thickness: 10.0,
                      radius: const Radius.circular(10),
                      notificationPredicate: (notif) =>
                          notif.depth == 0, // منع تداخل التمرير
                      child: SingleChildScrollView(
                        controller: _horizontalScroll, // ربط المتحكم الأفقي
                        scrollDirection: Axis.horizontal,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // إجبار التمرير ليكون مرناً
                        child: _buildDataTable(),
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

  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 16.0,
      horizontalMargin: 16.0,
      headingRowHeight: 50,
      dataRowMaxHeight: 80,
      dataRowMinHeight: 60,
      columns: const [
        DataColumn(
            label: Text('التاريخ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('المُبلِّغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('المُبلَّغ عنه',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('السبب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('التفاصيل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('الحالة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        DataColumn(
            label: Text('الإجراءات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      ],
      rows: _reports.map((report) {
        final date = DateTime.parse(report['created_at']).toLocal();
        final formattedDate = '${date.year}/${date.month}/${date.day}';
        final reporterName = _userNames[report['reporter_id']] ?? 'مجهول';
        final reportedName = _userNames[report['reported_user_id']] ?? 'مجهول';
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
          DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12))),
          DataCell(
            Tooltip(
              message: reporterName,
              child: SizedBox(
                width: 100,
                child: Text(
                  reporterName,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          DataCell(
            Tooltip(
              message: reportedName,
              child: SizedBox(
                width: 100,
                child: Text(
                  reportedName,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: 80,
              child: Text(
                report['reason'] ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            Tooltip(
              message: report['description'] ?? 'لا يوجد',
              child: SizedBox(
                width: 120,
                child: Text(
                  report['description'] ?? 'لا يوجد',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          DataCell(statusWidget),
          DataCell(
            SizedBox(
              width: 280, // عرض كافي لجميع الأزرار
              child: _buildActionButtons(report, status, reportedName),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color[100], borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(
          color: color[800],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      dynamic report, String status, String reportedName) {
    // استخدام SingleChildScrollView للتمرير الأفقي داخل الأزرار
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // الإجراءات حسب الحالة
          if (status == 'pending') ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(70, 30),
                textStyle: const TextStyle(fontSize: 11),
              ),
              onPressed: () =>
                  _banUser(report['reported_user_id'], report['id']),
              child: const Text('حظر'),
            ),
            const SizedBox(width: 4),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(50, 30),
                textStyle: const TextStyle(fontSize: 11),
              ),
              onPressed: () => _dismissReport(report['id']),
              child: const Text('تجاهل'),
            ),
            const SizedBox(width: 4),
          ] else if (status == 'banned') ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: const Size(70, 30),
              ),
              icon: const Icon(Icons.restore, color: Colors.blue, size: 16),
              label: const Text('رفع الحظر',
                  style: TextStyle(color: Colors.blue, fontSize: 11)),
              onPressed: () =>
                  _unbanUser(report['reported_user_id'], report['id']),
            ),
            const SizedBox(width: 4),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('لا يوجد',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            const SizedBox(width: 4),
          ],

          // زر تواصل - يظهر دائماً
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active,
                color: Colors.orange, size: 16),
            label: const Text('تواصل',
                style: TextStyle(color: Colors.orange, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(60, 30),
            ),
            onPressed: () {
              if (widget.onContactUser != null && reportedName != 'مجهول') {
                widget.onContactUser!(reportedName);
              } else if (widget.onContactUser == null) {
                // تنبيه للمطور
                debugPrint('onContactUser غير معرف');
              }
            },
          ),
        ],
      ),
    );
  }
}
