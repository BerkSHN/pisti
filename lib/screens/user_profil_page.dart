import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pisti_app/theme/app_colors.dart';
import 'package:pisti_app/services/api_service.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  String _username = "...";
  String _profileImage = "";
  String _bio = ""; // ── HAKKINDA ALANI EKLENDİ ───────────────────────────────
  int _joinedCount = 0;
  bool _isLoading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fetchProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUserProfileSummary(widget.userId);
      if (data != null) {
        setState(() {
          _username = data["full_name"] ??
              data["username"] ??
              data["name"] ??
              "Kullanıcı";
          _profileImage = data["profile_image"] ?? "";
          _bio = data["bio"] ?? ""; // ── API'DEN BİO ÇEKİLİYOR ─────────────────
          if (data["joined_events"] != null) {
            _joinedCount = (data["joined_events"] as List).length;
          }
          _isLoading = false;
        });
        _animCtrl.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _profileImage.isNotEmpty;
    final String initials = _username.isNotEmpty
        ? (_username.length >= 2
            ? _username.substring(0, 2).toUpperCase()
            : _username.toUpperCase())
        : "??";
    final int score = _joinedCount * 100;
    final String rank = _getRank(score);
    final Color rankColor = _getRankColor(score);

    return Scaffold(
      backgroundColor: kBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kCard.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: kBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: kText),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── HEADER BAND (ORTALANMIŞ) ───────────────────────────
                      _buildHeader(hasImage, initials, rankColor, rank),

                      const SizedBox(height: 28),

                      // ── STATS ROW ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatsRow(score, rankColor),
                      ),

                      // ── HAKKINDA BÖLÜMÜ (BOŞ DEĞİLSE GÖSTERİLİR) ────────────
                      if (_bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildBioCard(),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── ROZET BÖLÜMÜ ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildBadgesCard(),
                      ),

                      const SizedBox(height: 20),

                      // ── AKTİVİTE BÖLÜMÜ ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildActivityCard(),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── HEADER (ORTALANMIŞ) ───────────────────────────────────────────────────

  Widget _buildHeader(
      bool hasImage, String initials, Color rankColor, String rank) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Arka plan gradyan bandı
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kPrimary.withValues(alpha: 0.25),
                kBg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Decorative circles
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -30,
          top: 40,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // İçerik - Center ile sarmalanarak tamamen ortalandı
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kPrimary, kPrimaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(48),
                              child: Image.memory(
                                base64Decode(_profileImage),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                    ),
                    // Rank badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: rankColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBg, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        rank,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // İsim
                Text(
                  _username,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kText,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Kullanıcı etiketi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: kPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'Pişti Üyesi',
                        style: TextStyle(
                            fontSize: 12,
                            color: kTextSub,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Boş alan bırakmak için Stack yüksekliğini koruyan hayali bir widget
        const SizedBox(height: 310, width: double.infinity),
      ],
    );
  }

  // ── STATS ROW ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int score, Color rankColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            value: '$_joinedCount',
            label: 'Katılım',
            icon: Icons.event_available_rounded,
            color: kPrimary,
          ),
          _VerticalDivider(),
          _StatItem(
            value: '$score',
            label: 'Puan',
            icon: Icons.star_rounded,
            color: kAmber,
          ),
          _VerticalDivider(),
          _StatItem(
            value: _getRank(score),
            label: 'Seviye',
            icon: Icons.workspace_premium_rounded,
            color: rankColor,
          ),
        ],
      ),
    );
  }

  // ── HAKKINDA KARTI ─────────────────────────────────────────────────────────

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 16, color: kPrimary),
              const SizedBox(width: 6),
              const Text(
                'HAKKINDA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _bio,
            style: const TextStyle(
              fontSize: 14,
              color: kTextSub,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── ROZETLER ────────────────────────────────────────────────────────────────

  Widget _buildBadgesCard() {
    final badges = _getBadges();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, size: 16, color: kAmber),
              const SizedBox(width: 6),
              const Text(
                'ROZETLER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges
                .map((b) => _BadgeChip(
                      emoji: b['emoji']!,
                      label: b['label']!,
                      earned: b['earned'] == 'true',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── AKTİVİTE ────────────────────────────────────────────────────────────────

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: kPrimary),
              const SizedBox(width: 6),
              const Text(
                'AKTİVİTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActivityBar(
            label: 'Katıldığı etkinlikler',
            value: _joinedCount,
            max: 20,
            color: kPrimary,
          ),
          const SizedBox(height: 12),
          _ActivityBar(
            label: 'Puan',
            value: _joinedCount * 100,
            max: 2000,
            color: kAmber,
          ),
          const SizedBox(height: 12),
          _ActivityBar(
            label: 'Rozet ilerleme',
            value: _joinedCount,
            max: 10,
            color: kMint,
          ),
        ],
      ),
    );
  }

  // ── YARDIMCI FONKSİYONLAR ───────────────────────────────────────────────────

  String _getRank(int score) {
    if (score >= 1500) return 'ELİT';
    if (score >= 800) return 'PRO';
    if (score >= 300) return 'AKTİF';
    return 'YENİ';
  }

  Color _getRankColor(int score) {
    if (score >= 1500) return const Color(0xFFFFD700);
    if (score >= 800) return kPrimary;
    if (score >= 300) return kMint;
    return kTextSub;
  }

  List<Map<String, String>> _getBadges() {
    return [
      {
        'emoji': '🏆',
        'label': 'İlk Katılım',
        'earned': (_joinedCount >= 1).toString(),
      },
      {
        'emoji': '🔥',
        'label': '5 Etkinlik',
        'earned': (_joinedCount >= 5).toString(),
      },
      {
        'emoji': '⚡',
        'label': '10 Etkinlik',
        'earned': (_joinedCount >= 10).toString(),
      },
      {
        'emoji': '💎',
        'label': 'Elit Üye',
        'earned': (_joinedCount >= 15).toString(),
      },
      {
        'emoji': '🌟',
        'label': 'Süper Aktif',
        'earned': (_joinedCount >= 20).toString(),
      },
    ];
  }
}

// ─── STAT ITEM ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: kTextSub, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── VERTICAL DIVIDER ─────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 52,
      color: kDivider,
    );
  }
}

// ─── BADGE CHIP ───────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool earned;

  const _BadgeChip({
    required this.emoji,
    required this.label,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1.0 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: earned ? kPrimaryLight : kCardElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned ? kPrimary.withValues(alpha: 0.35) : kBorder,
          ),
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.15),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: earned ? kPrimary : kTextSub,
              ),
            ),
            if (earned) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_circle_rounded, size: 12, color: kPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ACTIVITY BAR ─────────────────────────────────────────────────────────────

class _ActivityBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _ActivityBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: kTextSub, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: kCardElevated,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}