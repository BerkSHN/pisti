import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pisti_app/theme/app_colors.dart';
import 'package:pisti_app/services/api_service.dart';

class ProfileUpdateScreen extends StatefulWidget {
  final String userId;

  const ProfileUpdateScreen({super.key, required this.userId});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  // 🎯 Backend Pydantic şemana (full_name ve username) birebir uyumlu controller'lar
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getUserProfileSummary(widget.userId);

      if (!mounted) return;

      setState(() {
        // Backend'den gelen ham dataları alanlara dolduruyoruz
        _fullNameController.text = data?["full_name"] ?? data?["name"] ?? "";
        _usernameController.text = data?["username"] ?? "";
        _emailController.text = data?["email"] ?? "";
        _bioController.text = data?["bio"] ?? data?["biography"] ?? "";

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text.isNotEmpty && _oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifrenizi değiştirmek için mevcut şifrenizi girmelisiniz."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String? oldPassword = _oldPasswordController.text.trim().isNotEmpty 
          ? _oldPasswordController.text.trim() 
          : null;
      final String? newPassword = _newPasswordController.text.trim().isNotEmpty 
          ? _newPasswordController.text.trim() 
          : null;

      // 🎯 NOT: ApiService.updateProfile metodun arka planda 'username' adında tek bir field parametresi 
      // alıyorsa, backend'deki 'full_name'i de ezmek için buraya _fullNameController değerini gönderiyoruz.
      final result = await ApiService.updateProfile(
        userId: widget.userId,
        username: _fullNameController.text.trim(), // Ön yüzde baskın olan full_name alanını günceller
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil başarıyla güncellendi ✨"),
            backgroundColor: kPrimary,
          ),
        );
        
        // 🎯 Ana ekrana dönerken full_name, username ve bio çakışmasını engellemek için map'i zorla güncelliyoruz
        final Map<String, dynamic> localUpdatedMap = {
          "full_name": _fullNameController.text.trim(),
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "bio": _bioController.text.trim(),
        };

        Navigator.pop(context, localUpdatedMap); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Profil güncellenemedi"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Beklenmeyen bir hata oluştu"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PROFİLİ DÜZENLE",
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: kText),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatar()),
                    const SizedBox(height: 30),

                    // 🎯 Ad Soyad Girişi (Backend'deki full_name alanını kontrol eder)
                    _buildInput(
                      controller: _fullNameController,
                      label: "Ad Soyad",
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ad Soyad alanı boş bırakılamaz";
                        }
                        if (value.trim().length < 2) {
                          return "Ad Soyad en az 2 karakter olmalıdır";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // 🎯 Kullanıcı Adı Girişi (Backend'deki username alanını kontrol eder)
                    _buildInput(
                      controller: _usernameController,
                      label: "Kullanıcı Adı (Takma Ad)",
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Kullanıcı adı boş bırakılamaz";
                        }
                        if (value.trim().length < 3) {
                          return "Kullanıcı adı en az 3 karakter olmalıdır";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    _buildInput(
                      controller: _emailController,
                      label: "E-posta Adresi",
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "E-posta adresi boş olamaz";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    _buildInput(
                      controller: _bioController,
                      label: "Hakkımda (Bio)",
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.only(top: 28, bottom: 16, left: 4),
                      child: Text(
                        "GÜVENLİK VE ŞİFRE",
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    _buildInput(
                      controller: _oldPasswordController,
                      label: "Mevcut Şifre",
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureOldPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOldPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: kTextSub,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildInput(
                      controller: _newPasswordController,
                      label: "Yeni Şifre",
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscureNewPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: kTextSub,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    String initials = "";
    if (_fullNameController.text.isNotEmpty) {
      final parts = _fullNameController.text.trim().split(" ");
      initials = parts.length > 1
          ? "${parts[0][0]}${parts[1][0]}"
          : _fullNameController.text.substring(0, _fullNameController.text.length >= 2 ? 2 : 1);
    } else if (_usernameController.text.isNotEmpty) {
      initials = _usernameController.text.substring(0, _usernameController.text.length >= 2 ? 2 : 1);
    }

    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 16, color: kPrimary),
          label: const Text(
            "Fotoğrafı Değiştir",
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: kText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kTextSub.withValues(alpha: 0.12)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 15),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: kPrimary, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "DEĞİŞİKLİKLERİ KAYDET",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}