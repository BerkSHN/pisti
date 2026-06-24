import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pisti_app/screens/login_page.dart';
import 'package:pisti_app/screens/profil_edit_page.dart';

import 'package:pisti_app/theme/app_colors.dart';
import 'package:pisti_app/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; 

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  String _username = "...";
  String _email = "...";
  String _bio = "Henüz bir biyografi eklenmemiş."; 

  int _joinedCount = 0;
  String _score = "0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFullProfileData();
  }

  Future<void> _fetchFullProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profileData = await ApiService.getUserProfileSummary(widget.userId);
      debugPrint("DEBUG - Gelen Profil Verisi: $profileData"); 

      if (!mounted) return;

      setState(() {
        if (profileData != null) {
          _username = profileData["full_name"] ??
              profileData["username"] ??
              profileData["name"] ??
              "Kullanıcı";

          _email = profileData["email"] ?? "";
          _bio = profileData["bio"] ?? "Henüz bir biyografi eklenmemiş."; 

          if (profileData["joined_events"] != null) {
            _joinedCount = (profileData["joined_events"] as List).length;
          }
        }

        _score = "${_joinedCount * 100}";
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Profil yükleme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String avatarText = "";
    if (!_isLoading && _username.isNotEmpty && _username != "...") {
      List<String> parts = _username.trim().split(" ");
      if (parts.length > 1 && parts[1].isNotEmpty) {
        avatarText = "${parts[0][0]}${parts[1][0]}".toUpperCase();
      } else {
        avatarText = _username
            .substring(0, _username.length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kPrimary,
        backgroundColor: kCard,
        onRefresh: _fetchFullProfileData, 
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileInfo(avatarText)),
            SliverToBoxAdapter(child: _buildStatsGrid()),
            SliverToBoxAdapter(child: _buildBioSection()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _buildLogoutButton(),
      ),
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kTextSub.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: kPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Hakkımda",
                  style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _bio,
                    style: TextStyle(
                      color: kText.withValues(alpha: 0.65),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: _isLoggingOut ? null : _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: kAccent,
            side: BorderSide(color: kAccent.withValues(alpha: 0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: _isLoggingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kAccent,
                  ),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(
            _isLoggingOut ? "Çıkış yapılıyor..." : "Çıkış Yap",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await ApiService.logout();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      backgroundColor: kBg,
      elevation: 0,
      pinned: true,
      leadingWidth: 100,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.sentiment_satisfied_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Piş',
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -1,
              ),
            ),
            const Text(
              'ti',
              style: TextStyle(
                color: kText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      title: const Text(
        "PROFİL",
        style: TextStyle(
          color: kText,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: kTextSub),
          onPressed: () async {
            // 🎯 Düzenleme ekranından dönen yeni 'user' nesnesini yakalıyoruz
            final dynamic updatedUserData = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileUpdateScreen(userId: widget.userId),
              ),
            );

            // 🎯 Eğer veri boş değilse ve Map yapısındaysa doğrudan ön yüzde state'i güncelliyoruz
            if (updatedUserData != null && updatedUserData is Map<String, dynamic>) {
              setState(() {
                _username = updatedUserData["full_name"] ?? 
                            updatedUserData["username"] ?? 
                            updatedUserData["name"] ?? _username;
                _email = updatedUserData["email"] ?? _email;
                _bio = updatedUserData["bio"] ?? _bio;
              });
            } else {
              // Güvence altına almak için bir değişiklik algılandığında fallback yenileme tetikliyoruz
              _fetchFullProfileData();
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileInfo(String avatarText) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: _isLoading ? 0.0 : 0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: _isLoading ? kCard : kPrimary,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: kBg,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(kTextSub),
                          ),
                        )
                      : Text(
                          avatarText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _isLoading
            ? Container(
                width: 140,
                height: 24,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : Text(
                _username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),
        const SizedBox(height: 8),

        _isLoading
            ? Container(
                width: 190,
                height: 14,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(6),
                ),
              )
            : Text(
                _email,
                style: const TextStyle(
                  color: kTextSub,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Row(
        children: [
          _statItem(_isLoading ? "..." : "$_joinedCount", "Katılım"),
          _statItem(_isLoading ? "..." : _score, "Puan"),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: kTextSub,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}