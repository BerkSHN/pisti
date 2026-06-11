import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pisti_app/main.dart';
import 'package:pisti_app/screens/home_page.dart';
import 'package:pisti_app/theme/app_colors.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Etkinlik odaklı mantıklı rozetler
  final List<Map<String, String>> _badges = [
    {'icon': '🔥', 'label': 'Seri Başlatan', 'desc': '5 hafta üst üste etkinlik'},
    {'icon': '🤝', 'label': 'Güvenilir', 'desc': '%100 katılım oranı'},
    {'icon': '🏀', 'label': 'Potanın Kralı', 'desc': '10+ Basketbol maçı'},
    {'icon': '🏆', 'label': 'MVP', 'desc': 'En çok beğenilen organizatör'},
    {'icon': '☕', 'label': 'Kahve Gurmesi', 'desc': '5+ Sosyal etkinlik'},
  ];

  final List<Map<String, dynamic>> _myEvents = [
    {
      'emoji': '🏀',
      'title': 'Basketbol Maçı',
      'time': 'Pazar 17:00',
      'loc': 'Atatürk Spor Salonu, Kadıköy',
      'color': kPrimary,
      'joined': 7,
      'max': 10,
      'desc': 'Sertifikalı saha, 5v5 maç. Herkesi bekleriz!',
    },
    {
      'emoji': '♟️',
      'title': 'Satranç Turnuvası',
      'time': 'Cmt 14:00',
      'loc': 'Moda Kültür Merkezi',
      'color': kAmber,
      'joined': 12,
      'max': 16,
      'desc': 'Swiss sistem, 10+5 tempo. Ödüllü turnuva!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildProfileInfo()),
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
              builder: (ctx, _) => _tabController.index == 0 
                ? _buildEventList(_myEvents) 
                : _buildEventList(_myEvents.reversed.toList()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- LOGO VE ORTALI BAŞLIK ---
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
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimary, kPrimaryDark]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.sentiment_satisfied_outlined, size: 20, color: Colors.white)),
            ),
            const SizedBox(width: 4),
            const Text('Piş', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
            const Text('ti', style: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
          ],
        ),
      ),
      centerTitle: true,
      title: const Text("PROFİL", style: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
      actions: [
        IconButton(icon: const Icon(Icons.settings_outlined, color: kTextSub), onPressed: () {}),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5)],
                ),
              ),
              const CircleAvatar(
                radius: 50,
                backgroundColor: kPrimary,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: kBg,
                  child: Text("BŞ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kText)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text("Berk Şahin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kText)),
        const Text("@berksahin", style: TextStyle(color: kTextSub, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Row(
        children: [
          _statItem("12", "Organize"),
          _statItem("45", "Katılım"),
          _statItem("1.2k", "Puan"),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSub, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
          onNotification: (notification) => true, // gesture'ı korur
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
                  border: Border.all(color: kPrimary),
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
  // --- DÜZELTİLMİŞ TABBAR ---
  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: kPrimary,
      indicatorWeight: 4,
      labelColor: kPrimary,
      unselectedLabelColor: kTextSub,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      tabs: const [Tab(text: "OLUŞTURDUĞUM"), Tab(text: "KATILDIĞIM")],
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> data) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _buildEventCard(data[i]),
        childCount: data.length,
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return GestureDetector(
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
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16)),
              child: Text(event['emoji'], style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'], style: const TextStyle(fontWeight: FontWeight.w900, color: kText, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(event['time'], style: const TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: kTextSub.withValues(alpha: 0.5), size: 16),
          ],
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
        decoration: const BoxDecoration(color: kCardElevated, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kTextSub, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(event['emoji'], style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kText)),
                      Text(event['time'], style: TextStyle(color: event['color'], fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _infoRow(Icons.location_on_rounded, event['loc']),
            const SizedBox(height: 12),
            _infoRow(Icons.people_alt_rounded, "${event['joined']} / ${event['max']} Katılımcı"),
            const SizedBox(height: 30),
            const Text("Etkinlik Hakkında", style: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            Text(event['desc'], style: TextStyle(color: kText.withValues(alpha: 0.6), height: 1.5)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: () => Navigator.pop(context),
                child: const Text("KATIL", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
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
        Expanded(child: Text(text, style: const TextStyle(color: kText, fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// --- TABBAR DELEGATE ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: kBg, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}