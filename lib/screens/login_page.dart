import 'package:flutter/material.dart';
import 'package:pisti_app/main.dart';
import 'package:pisti_app/theme/app_colors.dart';
import 'package:pisti_app/services/api_service.dart';

import 'package:pisti_app/screens/register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage("E-posta ve şifre alanlarını doldurun");
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
      return;
    }

    _showMessage(result["message"]?.toString() ?? "Giriş yapılamadı");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withValues(alpha: .15),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent.withValues(alpha: .08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: .4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("☺️", style: TextStyle(fontSize: 40)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Pişti",
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Yeni insanlarla tanış,\nberaber etkinliklere katıl.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSub,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField(
                          hint: "E-posta",
                          icon: Icons.mail_outline_rounded,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "Şifre",
                          icon: Icons.lock_outline_rounded,
                          controller: _passwordController,
                          obscure: obscurePassword,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kTextSub,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Şifremi Unuttum",
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Giriş Yap",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: kBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("veya", style: TextStyle(color: kTextSub)),
                      ),
                      Expanded(child: Container(height: 1, color: kBorder)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _socialButton(icon: "G", title: "Google ile devam et"),

                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hesabın yok mu?",
                        style: TextStyle(color: kTextSub),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(color: kText),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: kPrimary),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: kTextSub),
        ),
      ),
    );
  }

  Widget _socialButton({required String icon, required String title}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(
              color: kText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: kText, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
