import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // ⬅️ متحكمات التمرير لربطها بشريط التمرير المرئي
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('users')
          .select()
          .order('createdAt', ascending: false);

      setState(() {
        _allUsers = data;
        _filteredUsers = data;
      });
    } catch (e) {
      debugPrint('خطأ في جلب المستخدمين: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phoneNumber'] ?? user['phone'] ?? '')
            .toString()
            .toLowerCase();

        return name.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            phone.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _toggleBanStatus(String userId, bool currentBanStatus) async {
    try {
      final newStatus = !currentBanStatus;
      await Supabase.instance.client
          .from('users')
          .update({'is_banned': newStatus}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                newStatus ? 'تم حظر المستخدم بنجاح 🚫' : 'تم رفع الحظر بنجاح ✅',
                textAlign: TextAlign.right),
            backgroundColor: newStatus ? Colors.red : Colors.green,
          ),
        );
      }
      _fetchUsers();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🔍 شريط البحث
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، الإيميل، أو رقم الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 📊 عنوان الجدول
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'قائمة المستخدمين (${_filteredUsers.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),

          // 📋 جدول المستخدمين (ممتد وقابل للتمرير مع شريط تمرير)
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Scrollbar(
                      controller: _verticalScroll,
                      thumbVisibility:
                          true, // ⬅️ إظهار شريط التمرير العمودي دائماً
                      child: SingleChildScrollView(
                        controller: _verticalScroll,
                        scrollDirection: Axis.vertical,
                        child: Scrollbar(
                          controller: _horizontalScroll,
                          thumbVisibility:
                              true, // ⬅️ إظهار شريط التمرير الأفقي دائماً
                          child: SingleChildScrollView(
                            controller: _horizontalScroll,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              // ⬅️ إجبار الجدول على التمدد بعرض الشاشة بالكامل
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    Colors.blueGrey[50]),
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                                columns: const [
                                  DataColumn(
                                      label: Text('الاسم',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('الإيميل',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('رقم الهاتف',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('البلد / المدينة',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('الحالة',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('الإجراءات',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredUsers.map((user) {
                                  final name = user['name'] ?? 'بدون اسم';
                                  final email = user['email'] ?? 'بدون إيميل';
                                  final phone = user['phoneNumber'] ??
                                      user['phone'] ??
                                      'بدون رقم';
                                  final location =
                                      '${user['country'] ?? ''} - ${user['primaryWorkCity'] ?? ''}';
                                  final isBanned = user['is_banned'] == true;

                                  return DataRow(cells: [
                                    DataCell(Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))),
                                    DataCell(Text(email,
                                        style: const TextStyle(
                                            color: Colors.blue))),
                                    DataCell(Text(phone)),
                                    DataCell(Text(location == ' - '
                                        ? 'غير محدد'
                                        : location)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBanned
                                              ? Colors.red[100]
                                              : Colors.green[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isBanned ? 'محظور' : 'نشط',
                                          style: TextStyle(
                                              color: isBanned
                                                  ? Colors.red[800]
                                                  : Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isBanned
                                              ? Colors.green
                                              : Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: Icon(
                                            isBanned
                                                ? Icons.check_circle
                                                : Icons.block,
                                            size: 18),
                                        label: Text(
                                            isBanned ? 'رفع الحظر' : 'حظر'),
                                        onPressed: () => _toggleBanStatus(
                                            user['id'], isBanned),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
