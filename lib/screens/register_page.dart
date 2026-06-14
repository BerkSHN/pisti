import 'package:flutter/material.dart';
import 'package:pisti_app/services/api_service.dart';
import 'package:pisti_app/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscurePassword = true;
  bool obscurePassword2 = true;
  bool _isLoading = false;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordAgainController.text.isEmpty) {
      _showMessage("Tüm alanları doldurun");
      return;
    }

    if (_passwordController.text != _passwordAgainController.text) {
      _showMessage("Şifreler eşleşmiyor");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage("Şifre en az 6 karakter olmalı");
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı, giriş yapabilirsiniz")),
      );
      return;
    }

    _showMessage(result["message"]?.toString() ?? "Kayıt oluşturulamadı");
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
          // Background Glow (same as login)
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withOpacity(.15),
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
                color: kAccent.withOpacity(.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo (same style)
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
                          color: kPrimary.withOpacity(.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("🔥", style: TextStyle(fontSize: 40)),
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
                    "Hemen kayıt ol,\netkinliklere katılmaya başla.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSub,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // REGISTER CARD
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField(
                          hint: "Ad Soyad",
                          icon: Icons.person_outline_rounded,
                          controller: _fullNameController,
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "E-posta",
                          icon: Icons.mail_outline_rounded,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "Kullanıcı Adı",
                          icon: Icons.alternate_email_rounded,
                          controller: _usernameController,
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

                        _inputField(
                          hint: "Şifre Tekrar",
                          icon: Icons.lock_outline_rounded,
                          controller: _passwordAgainController,
                          obscure: obscurePassword2,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword2 = !obscurePassword2;
                              });
                            },
                            icon: Icon(
                              obscurePassword2
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kTextSub,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
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
                                    "Kayıt Ol",
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Zaten hesabın var mı?",
                        style: TextStyle(color: kTextSub),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Giriş Yap",
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
}
