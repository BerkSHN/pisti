import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pisti_app/screens/login_page.dart';
import 'package:pisti_app/theme/app_colors.dart';
import 'package:pisti_app/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String
  userId; // 🎯 Dışarıdan giriş yapmış kullanıcının ID'sini alıyoruz

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoggingOut = false;

  // Dinamik Profil State Değişkenleri
  String _username = "...";
  String _email = "...";
  int _organizedCount = 0;
  int _joinedCount = 0;
  String _score = "0";
  bool _isLoading = true;

  // Backend'den gelecek dinamik etkinlik listeleri
  List<Map<String, dynamic>> _myCreatedEvents = [];
  List<Map<String, dynamic>> _myJoinedEvents = [];

  // Sabit Etkinlik Rozetleri (İleride katılım sayısına göre kilitleri açılabilir)
  final List<Map<String, String>> _badges = [
    {
      'icon': '🔥',
      'label': 'Seri Başlatan',
      'desc': '5 hafta üst üste etkinlik',
    },
    {'icon': '🤝', 'label': 'Güvenilir', 'desc': '%100 katılım oranı'},
    {'icon': '🏀', 'label': 'Potanın Kralı', 'desc': '10+ Basketbol maçı'},
    {'icon': '🏆', 'label': 'MVP', 'desc': 'En çok beğenilen organizatör'},
    {'icon': '☕', 'label': 'Kahve Gurmesi', 'desc': '5+ Sosyal etkinlik'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFullProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🎯 Backend verilerini eşzamanlı olarak toplayan ana fonksiyon
  Future<void> _fetchFullProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profileData = await ApiService.getUserProfileSummary(widget.userId);
      print(
        "DEBUG - Gelen Profil Verisi: $profileData",
      ); // 🎯 Hâlâ yazmıyorsa debug konsoluna bakın

      if (!mounted) return;

      setState(() {
        if (profileData != null) {
          // 🎯 Tüm ihtimalleri sırayla kontrol ediyoruz (full_name, username, name)
          _username =
              profileData["full_name"] ??
              profileData["username"] ??
              profileData["name"] ??
              "Kullanıcı";

          _email = profileData["email"] ?? "";

          if (profileData["joined_events"] != null) {
            _joinedCount = (profileData["joined_events"] as List).length;
          }
        }

        _myJoinedEvents = [];
        _myCreatedEvents = [];
        _score = "${(_joinedCount * 100) + (_organizedCount * 250)}";
        _isLoading = false;
      });
    } catch (e) {
      print("Profil yükleme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı adının baş harflerinden akıllı avatar oluşturma (Örn: Halit Eren -> HE)
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
        onRefresh: _fetchFullProfileData, // Sayfayı aşağı kaydırınca yeniler
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            // 🎯 Artık tam ekran yüklemesi yok, bileşenler kendi iskeletini çiziyor
            SliverToBoxAdapter(child: _buildProfileInfo(avatarText)),
            SliverToBoxAdapter(child: _buildStatsGrid()),
            SliverToBoxAdapter(child: _buildBadgesSection()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(_buildTabBar()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              sliver: AnimatedBuilder(
                animation: _tabController,
                builder: (ctx, _) {
                  // Sekme listeleri yüklenirken ufak bir loading gösterebiliriz
                  if (_isLoading) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                          ),
                        ),
                      ),
                    );
                  }

                  if (_tabController.index == 0) {
                    // OLUŞTURDUĞUM SEKME LİSTESİ
                    return _myCreatedEvents.isEmpty
                        ? _buildEmptyStateSliver(
                            "Henüz bir etkinlik oluşturmadın.",
                          )
                        : _buildEventList(_myCreatedEvents);
                  } else {
                    // KATILDIĞIM SEKME LİSTESİ
                    return _myJoinedEvents.isEmpty
                        ? _buildEmptyStateSliver(
                            "Henüz hiçbir etkinliğe katılmadın.",
                          )
                        : _buildEventList(_myJoinedEvents.reversed.toList());
                  }
                },
              ),
            ),
            SliverToBoxAdapter(child: _buildLogoutButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          onPressed: () {},
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
                backgroundColor: _isLoading
                    ? kCard
                    : kPrimary, // Yüklenirken soft gri bir halka olur
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

        // 🎯 İsim Alanı Maskesi
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

        // 🎯 Email Alanı Maskesi
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
          _statItem(_isLoading ? "..." : "$_organizedCount", "Organize"),
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

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "BAŞARILAR",
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => true,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: List.generate(_badges.length, (index) {
                final badge = _badges[index];
                return Container(
                  width: 95,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        badge['icon']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: kPrimary,
      indicatorWeight: 4,
      labelColor: kPrimary,
      unselectedLabelColor: kTextSub,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      tabs: const [
        Tab(text: "OLUŞTURDUĞUM"),
        Tab(text: "KATILDIĞIM"),
      ],
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> data) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        // 🎯 Key ekleyerek listeler arası geçişte state senkronizasyon hatasını önlüyoruz
        (ctx, i) {
          final String id = (data[i]['_id'] ?? data[i]['id'] ?? i.toString())
              .toString();
          return _buildEventCard(data[i], ValueKey(id));
        },
        childCount: data.length,
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, Key key) {
    return GestureDetector(
      key: key,
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kTextSub.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                event['emoji'] ?? '🎉',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Başlıksız Etkinlik',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kText,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['time'] ?? 'Zaman Belirtilmedi',
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kTextSub.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 Eğer liste boşsa gösterilecek modern boş durum sliver'ı
  Widget _buildEmptyStateSliver(String message) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 40,
                color: kTextSub.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: kCardElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextSub,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  event['emoji'] ?? '🎉',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? 'Etkinlik',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                      Text(
                        event['time'] ?? '',
                        style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _infoRow(
              Icons.location_on_rounded,
              event['location'] ?? event['loc'] ?? 'Belirtilmedi',
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.people_alt_rounded,
              "${event['joined'] ?? 0} Katılımcı",
            ),
            const SizedBox(height: 30),
            const Text(
              "Etkinlik Hakkında",
              style: TextStyle(
                color: kText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event['description'] ?? event['desc'] ?? 'Açıklama bulunmuyor.',
              style: TextStyle(
                color: kText.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "KAPAT",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: kText, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: kBg, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
