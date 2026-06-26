import 'package:elhirafi_admin/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استيراد شاشة لوحة التحكم
import 'screens/dashboard_screen.dart';

// ⬅️ إضافة متحكم عام للثيم لسهولة الوصول إليه من أي مكان
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⬅️ قراءة المفاتيح من بيئة البناء مباشرة (أمان تام)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('⚠️ تحذير: مفاتيح Supabase غير متوفرة في بيئة البناء!');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey, // ⬅️ تم التصحيح من publishableKey إلى anonKey
  );

  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⬅️ تغليف التطبيق بمستمع لتغيرات الثيم
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'لوحة تحكم الصانع الحرفي',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, // ⬅️ تحديد الثيم الحالي
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            fontFamily: 'Tajawal',
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blueGrey,
            fontFamily: 'Tajawal',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blueGrey[900],
              foregroundColor: Colors.white,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

// ==========================================
// 🛡️ بوابة الأمان (Auth Gate)
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();

    // الاستماع لتغيرات تسجيل الدخول/الخروج
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('is_admin')
            .eq('id', session.user.id)
            .single();

        setState(() {
          _isAdmin = userData['is_admin'] == true;
        });
      } catch (e) {
        setState(() => _isAdmin = false);
      }
    } else {
      setState(() => _isAdmin = false);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      return const LoginScreen(); // ⬅️ البوابة الحقيقية
    }

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              const Text('عذراً، ليس لديك صلاحية الدخول للوحة التحكم.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('تسجيل الخروج'),
              )
            ],
          ),
        ),
      );
    }

    // إذا كان مسجلاً الدخول وهو مدير، افتح لوحة التحكم!
    return const DashboardScreen();
  }
}
