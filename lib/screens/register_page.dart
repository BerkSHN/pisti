import 'package:flutter/material.dart';
import 'package:pisti_app/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscurePassword = true;
  bool obscurePassword2 = true;

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
                      child: Text(
                        "🔥",
                        style: TextStyle(fontSize: 40),
                      ),
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
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "E-posta",
                          icon: Icons.mail_outline_rounded,
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "Kullanıcı Adı",
                          icon: Icons.alternate_email_rounded,
                        ),

                        const SizedBox(height: 14),

                        _inputField(
                          hint: "Şifre",
                          icon: Icons.lock_outline_rounded,
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
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
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
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