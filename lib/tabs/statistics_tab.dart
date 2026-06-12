import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  bool _isLoading = true;

  List<dynamic> _allUsers = [];
  List<dynamic> _bannedUsers = [];
  List<dynamic> _allReports = [];
  List<dynamic> _pendingReports = [];

  String _selectedCategory = 'all_users';

  final ScrollController _mainScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  @override
  void dispose() {
    _mainScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final usersRes = await supabase
          .from('users')
          .select()
          .order('createdAt', ascending: false);
      _allUsers = usersRes;
      _bannedUsers = _allUsers.where((u) {
        final isBanned = u['is_banned'];
        return isBanned == true || isBanned == 'true' || isBanned == 1;
      }).toList();

      final reportsRes = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);
      _allReports = reportsRes;
      _pendingReports =
          _allReports.where((r) => r['status'] == 'pending').toList();
    } catch (e) {
      debugPrint('خطأ في جلب الإحصائيات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scrollbar(
      controller: _mainScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _mainScroll, // ⬅️ التمرير المشترك للشاشة بأكملها
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 🔄 شريط العنوان والتحديث
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchStatistics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث البيانات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey,
                  ),
                ),
                const Text(
                  'نظرة عامة تفاعلية',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🗂️ شبكة البطاقات التفاعلية (مضغوطة الارتفاع)
            Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.count(
                shrinkWrap: true, // ⬅️ يسمح للشبكة بالتمدد داخل التمرير الرئيسي
                crossAxisCount: isWideScreen ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    isWideScreen ? 3.0 : 2.5, // ⬅️ تقليل الارتفاع بشكل كبير
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: 'إجمالي المستخدمين',
                    value: _allUsers.length.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                    categoryKey: 'all_users',
                  ),
                  _buildStatCard(
                    title: 'المستخدمين المحظورين',
                    value: _bannedUsers.length.toString(),
                    icon: Icons.block,
                    color: Colors.red,
                    categoryKey: 'banned_users',
                  ),
                  _buildStatCard(
                    title: 'إجمالي البلاغات',
                    value: _allReports.length.toString(),
                    icon: Icons.report_problem,
                    color: Colors.orange,
                    categoryKey: 'all_reports',
                  ),
                  _buildStatCard(
                    title: 'بلاغات معلقة',
                    value: _pendingReports.length.toString(),
                    icon: Icons.pending_actions,
                    color: _pendingReports.isNotEmpty
                        ? Colors.redAccent
                        : Colors.green,
                    categoryKey: 'pending_reports',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // 📋 عنوان القائمة السفلية
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _getListTitle(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 16),

            // ⬇️ القائمة المفلترة
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scrollbar(
                    controller: _horizontalScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 48),
                        child: _buildDetailsTable(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String categoryKey,
  }) {
    final isSelected = _selectedCategory == categoryKey;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blueGrey.shade800, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : [const BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 40, color: Colors.white.withOpacity(0.4)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getListTitle() {
    switch (_selectedCategory) {
      case 'all_users':
        return 'تفاصيل: جميع المستخدمين (${_allUsers.length})';
      case 'banned_users':
        return 'تفاصيل: المستخدمين المحظورين (${_bannedUsers.length})';
      case 'all_reports':
        return 'تفاصيل: جميع البلاغات (${_allReports.length})';
      case 'pending_reports':
        return 'تفاصيل: البلاغات المعلقة (${_pendingReports.length})';
      default:
        return 'التفاصيل';
    }
  }

  Widget _buildDetailsTable() {
    if (_selectedCategory == 'all_users' ||
        _selectedCategory == 'banned_users') {
      final list = _selectedCategory == 'all_users' ? _allUsers : _bannedUsers;
      if (list.isEmpty)
        return const Padding(
            padding: EdgeInsets.all(32), child: Text('لا توجد بيانات لعرضها.'));

      return DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
        columns: const [
          DataColumn(
              label:
                  Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('الإيميل',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('الهاتف',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('الحالة',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: list.map((user) {
          final isBanned = user['is_banned'] == true ||
              user['is_banned'] == 'true' ||
              user['is_banned'] == 1;
          return DataRow(cells: [
            DataCell(Text(user['name'] ?? 'مجهول')),
            DataCell(Text(user['email'] ?? 'مجهول')),
            DataCell(Text(user['phoneNumber'] ?? user['phone'] ?? 'مجهول')),
            DataCell(Text(isBanned ? '🚫 محظور' : '✅ نشط',
                style: TextStyle(
                    color: isBanned ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      );
    } else {
      final list =
          _selectedCategory == 'all_reports' ? _allReports : _pendingReports;
      if (list.isEmpty)
        return const Padding(
            padding: EdgeInsets.all(32), child: Text('لا توجد بيانات لعرضها.'));

      return DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
        columns: const [
          DataColumn(
              label: Text('رقم البلاغ',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('السبب', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('التفاصيل',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('الحالة',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: list.map((report) {
          final status = report['status'] ?? 'pending';
          // ⬅️ تم إصلاح الحالة هنا: أي بلاغ غير معلق يعتبر "تم الحل"
          String statusText = status == 'pending' ? '⏳ معلق' : '✅ تم الحل';
          Color statusColor =
              status == 'pending' ? Colors.orange : Colors.green;

          return DataRow(cells: [
            DataCell(Text(report['id'].toString())),
            DataCell(Text(report['reason'] ?? 'غير محدد')),
            DataCell(Text((report['details'] ?? '').toString().length > 30
                ? '${report['details'].toString().substring(0, 30)}...'
                : report['details'] ?? '')),
            DataCell(Text(statusText,
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      );
    }
  }
}
