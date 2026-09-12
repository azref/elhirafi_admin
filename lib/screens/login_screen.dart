import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isMfaRequired = false;
  bool _isEnrolling = false;
  String? _factorId;
  String? _qrCodeUri;

  Future<void> _login() async {
    if (!_isMfaRequired &&
        !_isEnrolling &&
        (_emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور',
                textAlign: TextAlign.right)),
      );
      return;
    }

    if ((_isMfaRequired || _isEnrolling) && _totpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('يرجى إدخال رمز المصادقة', textAlign: TextAlign.right)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if ((_isMfaRequired || _isEnrolling) && _factorId != null) {
        final res = await Supabase.instance.client.auth.mfa
            .challenge(factorId: _factorId!);
        await Supabase.instance.client.auth.mfa.verify(
          factorId: _factorId!,
          challengeId: res.id,
          code: _totpController.text.trim(),
        );
      } else {
        final AuthResponse res =
            await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (res.session != null && res.user != null) {
          final factors = await Supabase.instance.client.auth.mfa.listFactors();
          final totpFactors = factors.totp;

          if (totpFactors.isNotEmpty) {
            final aal = await Supabase.instance.client.auth.mfa
                .getAuthenticatorAssuranceLevel();
            if (aal.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
                aal.nextLevel == AuthenticatorAssuranceLevels.aal2) {
              setState(() {
                _isMfaRequired = true;
                _factorId = totpFactors.first.id;
                _isLoading = false;
              });
              return;
            }
          } else {
            // المستخدم ليس لديه عوامل مصادقة، يجب أن نربط حسابه الآن
            final enrollRes = await Supabase.instance.client.auth.mfa.enroll(
              factorType: FactorType.totp,
              issuer: 'Elhirafi Admin',
            );
            setState(() {
              _isEnrolling = true;
              _factorId = enrollRes.id;
              _qrCodeUri = enrollRes.totp?.qrCode;
              _isLoading = false;
            });
            return;
          }
        }
      }
      // 💡 ملاحظة: لا نحتاج لكتابة كود التوجيه هنا!
      // لأن AuthGate في main.dart تستمع للتغيرات وستقوم بنقلك للوحة التحكم تلقائياً.
    } catch (e, s) {
      debugPrint('MFA ERROR => $e');
      debugPrint('STACK => $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('(${e.runtimeType})\n${e.toString()}',
                textAlign: TextAlign.right),
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
    return Scaffold(
        backgroundColor: Colors.blueGrey[50],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 400, // عرض ثابت لتبدو كبطاقة أنيقة على شاشة الكمبيوتر
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 15, spreadRadius: 5)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        size: 80, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    const Text('تسجيل الدخول للإدارة',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    const SizedBox(height: 32),
                    if (!_isMfaRequired && !_isEnrolling) ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (_isEnrolling && _qrCodeUri != null) ...[
                        const Text(
                          'امسح الكود باستخدام تطبيق المصادقة (مثل Google Authenticator)',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 216,
                          height: 216,
                          child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.string(
                                _qrCodeUri!.replaceFirst(
                                    'data:image/svg+xml;utf8,', ''),
                                width: 200,
                                height: 200,
                              )),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextField(
                          controller: _totpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'رمز المصادقة (6 أرقام)',
                            prefixIcon: Icon(Icons.security),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                (_isMfaRequired || _isEnrolling)
                                    ? 'تأكيد الرمز'
                                    : 'دخول',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
