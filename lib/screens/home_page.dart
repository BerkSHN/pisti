import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:pisti_app/main.dart';
import 'package:pisti_app/theme/app_colors.dart';
final _categories = [
  {'icon': '🏀', 'label': 'Spor'},
  {'icon': '☕', 'label': 'Kahve'},
  {'icon': '🎬', 'label': 'Sinema'},
  {'icon': '🚴', 'label': 'Bisiklet'},
  {'icon': '🎮', 'label': 'Oyun'},
  {'icon': '📚', 'label': 'Okuma'},
  {'icon': '🍷', 'label': 'Tadım'},
  {'icon': '♟️', 'label': 'Satranç'},
];

final _events = [
  {
    'id': 1,
    'emoji': '🏀',
    'title': 'Basketbol Maçı',
    'location': 'Atatürk Spor Salonu, Edirne',
    'time': 'Pazar 17:00',
    'joined': 7,
    'max': 10,
    'category': 'Spor',
    'creator': 'Berk Aydın',
    'avatar': 'BA',
    'avatarColor': Color(0xFFFF6B00),
    'desc': 'Seviye fark etmez, herkes bekliyoruz! Forma getirmeye gerek yok.',
    'tags': ['Açık seviye', 'Ücretsiz'],
    'likes': 24,
    'comments': 5,
    'shares': 3,
    'imageUrl': null,
    'categoryColor': Color(0xFFFF6B00),
  },
  {
    'id': 2,
    'emoji': '☕',
    'title': 'Sabah Kahvesi Buluşması',
    'location': 'Moda Sahili, Edirne',
    'time': 'Cumartesi 09:30',
    'joined': 3,
    'max': 6,
    'category': 'Sosyal',
    'creator': 'Selin Kaya',
    'avatar': 'SK',
    'avatarColor': Color(0xFFFFB020),
    'desc': 'Deniz manzarasında sabah kahvesi içmek isteyen herkesi bekliyorum.',
    'tags': ['Yeni gelenlere açık', 'Ücretsiz'],
    'likes': 41,
    'comments': 9,
    'shares': 7,
    'imageUrl': null,
    'categoryColor': Color(0xFFFFB020),
  },
  {
    'id': 3,
    'emoji': '🚴',
    'title': 'Boğaz Bisiklet Turu',
    'location': 'Beşiktaş İskelesi',
    'time': 'Pazar 08:00',
    'joined': 11,
    'max': 15,
    'category': 'Spor',
    'creator': 'Can Demiral',
    'avatar': 'CD',
    'avatarColor': Color(0xFF39D98A),
    'desc': '~25 km rota, başlangıç seviyesine uygun tempo. Bisikletsizler için kiralık seçenek var.',
    'tags': ['Bisiklet lazım', 'Ücretsiz'],
    'likes': 67,
    'comments': 14,
    'shares': 11,
    'imageUrl': null,
    'categoryColor': Color(0xFF39D98A),
  },
  {
    'id': 4,
    'emoji': '🍷',
    'title': 'Şarap Tadımı Akşamı',
    'location': 'Nişantaşı, Private Mekan',
    'time': 'Cuma 20:00',
    'joined': 6,
    'max': 8,
    'category': 'Sosyal',
    'creator': 'Elif Mert',
    'avatar': 'EM',
    'avatarColor': Color(0xFFFF6B6B),
    'desc': '4 farklı şarap, peynir tabağı eşliğinde keyifli bir akşam. Rezervasyon zorunlu.',
    'tags': ['Ücretli (150₺)', 'Yetişkin'],
    'likes': 89,
    'comments': 22,
    'shares': 15,
    'imageUrl': null,
    'categoryColor': Color(0xFFFF6B6B),
  },
  {
    'id': 5,
    'emoji': '♟️',
    'title': 'Satranç Turnuvası',
    'location': 'Beyoğlu Kültür Merkezi',
    'time': 'Cumartesi 14:00',
    'joined': 9,
    'max': 16,
    'category': 'Oyun',
    'creator': 'Mert Yıldız',
    'avatar': 'MY',
    'avatarColor': Color(0xFFFF6B00),
    'desc': 'Swiss sistem, tüm seviyeler katılabilir. Küçük ödüller var.',
    'tags': ['Turnuva', 'Ücretsiz'],
    'likes': 33,
    'comments': 8,
    'shares': 6,
    'imageUrl': null,
    'categoryColor': Color(0xFFFF6B00),
  },
  {
    'id': 6,
    'emoji': '🎬',
    'title': 'Film Gecesi: Kubrick',
    'location': 'Beşiktaş, Ev Ortamı',
    'time': 'Perşembe 20:30',
    'joined': 4,
    'max': 7,
    'category': 'Eğlence',
    'creator': 'Deniz Şahin',
    'avatar': 'DS',
    'avatarColor': Color(0xFF06B6D4),
    'desc': 'Bu hafta Kubrick retrospektifi. Büyük ekran, karanlık oda, popcorn hazır!',
    'tags': ['Sanat filmi', 'Ücretsiz'],
    'likes': 55,
    'comments': 12,
    'shares': 8,
    'imageUrl': null,
    'categoryColor': Color(0xFF06B6D4),
  },
];

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  int _selectedCat = -1;
  bool _isComposeExpanded = false;
  late AnimationController _composeAnimCtrl;
  late Animation<double> _composeAnim;
  int _bottomNavIndex = 0;

  // Mutable joined counts per event id
  final Map<int, int> _joinedCounts = {};

  @override
  void initState() {
    super.initState();
    for (final e in _events) {
      _joinedCounts[e['id'] as int] = e['joined'] as int;
    }
    _composeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _composeAnim = CurvedAnimation(parent: _composeAnimCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composeAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleCompose() {
    setState(() => _isComposeExpanded = !_isComposeExpanded);
    if (_isComposeExpanded) {
      _composeAnimCtrl.forward();
    } else {
      _composeAnimCtrl.reverse();
    }
  }

  void _onJoinChanged(int eventId, bool joined) {
    setState(() {
      final base = _events.firstWhere((e) => e['id'] == eventId)['joined'] as int;
      _joinedCounts[eventId] = base + (joined ? 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildComposeBox()),
                    SliverToBoxAdapter(child: _buildCategoryRow()),
                    SliverToBoxAdapter(child: _buildSectionHeader()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _EventCard(
                          event: _events[i],
                          currentJoined: _joinedCounts[_events[i]['id'] as int] ?? _events[i]['joined'] as int,
                          onJoinChanged: (joined) => _onJoinChanged(_events[i]['id'] as int, joined),
                        ),
                        childCount: _events.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: kBg,
      child: Row(
        children: [
          _PishtiLogo(),
          const Spacer(),
          _LocationPill(),
          const SizedBox(width: 10),
          _NotifBell(),
        ],
      ),
    );
  }

  // ── COMPOSE BOX ────────────────────────────────────────────────────────────

  Widget _buildComposeBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleCompose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: kCardElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Ne yapmak istiyorsun?',
                            style: TextStyle(
                              color: kTextSub,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Text('🎯', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _composeAnim,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _composeAnim.value,
                  child: child,
                ),
              );
            },
            child: _buildExpandedCompose(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _QuickChip(icon: '🏀', label: 'Spor', color: kPrimary),
                const SizedBox(width: 8),
                _QuickChip(icon: '☕', label: 'Sosyal', color: kAmber),
                const SizedBox(width: 8),
                _QuickChip(icon: '🗺️', label: 'Harita', color: kMint),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleCompose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Paylaş',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCompose() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: kDivider, height: 1),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: kCardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 28, color: kPrimary),
                  const SizedBox(height: 6),
                  Text('Fotoğraf ekle', style: TextStyle(fontSize: 13, color: kTextSub, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ComposeField(hint: '🎯  Etkinlik adı (ör. "Basketbol maçı")'),
          const SizedBox(height: 8),
          _ComposeField(hint: '📍  Konum'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ComposeField(hint: '📅  Tarih')),
              const SizedBox(width: 8),
              Expanded(child: _ComposeField(hint: '🕐  Saat')),
            ],
          ),
          const SizedBox(height: 8),
          _ComposeField(hint: '👥  Maks. katılımcı sayısı'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: kText),
              decoration: InputDecoration.collapsed(
                hintText: '✍️  Açıklama ekle...',
                hintStyle: TextStyle(color: kTextSub, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _CategorySelectChip(
                  label: c['label'] as String,
                  emoji: c['icon'] as String,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _selectedCat == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = selected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? kPrimary : kBorder),
                boxShadow: selected
                    ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon'] as String, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : kText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SECTION HEADER ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yakınındaki etkinlikler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kText,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Edirne · ${_events.length} etkinlik',
                style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 13, color: kPrimary),
                  const SizedBox(width: 4),
                  Text('Filtrele',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Keşfet', index: 0, current: _bottomNavIndex, onTap: (i) => setState(() => _bottomNavIndex = i)),
          _NavItem(icon: Icons.map_outlined, label: 'Harita', index: 1, current: _bottomNavIndex, onTap: (i) => setState(() => _bottomNavIndex = i)),
          const SizedBox(width: 58),
          _NavItem(icon: Icons.bookmark_border_rounded, label: 'Katıldıklarım', index: 2, current: _bottomNavIndex, onTap: (i) => setState(() => _bottomNavIndex = i)),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 3, current: _bottomNavIndex, onTap: (i) => setState(() => _bottomNavIndex = i)),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggleCompose,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ─── LOGO WIDGET ──────────────────────────────────────────────────────────────

class _PishtiLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flame + People logo
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.5),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: kAccent.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 0),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(22, 22),
              painter: _PishtiLogoPainter(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Wordmark
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Piş',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kPrimary,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              'ti',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kText,
                letterSpacing: -1.0,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 3, bottom: 4),
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── LOGO PAINTER: Flame + Connected People ────────────────────────────────

class _PishtiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Left person
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.28), 2.6, paint);
    final leftBody = Path()
      ..moveTo(size.width * 0.12, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.58, size.width * 0.44, size.height * 0.82);
    canvas.drawPath(leftBody, strokePaint..style = PaintingStyle.stroke);

    // Right person
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), 2.6, paint..color = Colors.white.withOpacity(0.85));
    final rightBody = Path()
      ..moveTo(size.width * 0.56, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.58, size.width * 0.88, size.height * 0.82);
    canvas.drawPath(rightBody, strokePaint..color = Colors.white.withOpacity(0.85));

    // Connection spark / flame between them
    final flamePaint = Paint()
      ..color = kAccent
      ..style = PaintingStyle.fill;

    final flame = Path()
      ..moveTo(size.width * 0.50, size.height * 0.18)
      ..cubicTo(
        size.width * 0.58, size.height * 0.30,
        size.width * 0.58, size.height * 0.44,
        size.width * 0.50, size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.42, size.height * 0.44,
        size.width * 0.42, size.height * 0.30,
        size.width * 0.50, size.height * 0.18,
      );
    canvas.drawPath(flame, flamePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── LOCATION PILL ────────────────────────────────────────────────────────────

class _LocationPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 14, color: kPrimary),
          const SizedBox(width: 4),
          const Text(
            'Edirne',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText),
          ),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: kTextSub),
        ],
      ),
    );
  }
}

// ─── NOTIF BELL ───────────────────────────────────────────────────────────────

class _NotifBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: kCard,
            shape: BoxShape.circle,
            border: Border.all(color: kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.notifications_outlined, size: 20, color: kText),
        ),
        Positioned(
          top: -1, right: -1,
          child: Container(
            width: 11, height: 11,
            decoration: BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: kBg, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── EVENT CARD ───────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final int currentJoined;
  final ValueChanged<bool> onJoinChanged;

  const _EventCard({
    required this.event,
    required this.currentJoined,
    required this.onJoinChanged,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {
  bool _joined = false;
  bool _liked = false;
  late int _likeCount;
  late AnimationController _likeAnim;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.event['likes'] as int;
    _likeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _likeAnim.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _likeAnim.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _toggleJoin(bool isFull) {
    if (!isFull || _joined) {
      final newJoined = !_joined;
      setState(() => _joined = newJoined);
      widget.onJoinChanged(newJoined);
      HapticFeedback.mediumImpact();
    }
  }

  void _shareEvent() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(event: widget.event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final joined = widget.currentJoined;
    final max = e['max'] as int;
    final pct = (joined / max).clamp(0.0, 1.0);
    final isFull = joined >= max;
    final tags = e['tags'] as List<String>;
    final catColor = e['categoryColor'] as Color;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageArea(e, catColor),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _AvatarCircle(initials: e['avatar'] as String, color: e['avatarColor'] as Color, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['creator'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText),
                      ),
                      Text(
                        e['time'] as String,
                        style: TextStyle(fontSize: 11, color: kTextSub),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: catColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    e['category'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: catColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '${e['emoji']}  ${e['title']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: kText,
                height: 1.2,
                letterSpacing: -0.4,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 13, color: kPrimary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    e['location'] as String,
                    style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              e['desc'] as String,
              style: TextStyle(fontSize: 14, color: kText.withOpacity(0.6), height: 1.55),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withOpacity(0.25)),
                ),
                child: Text(t,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  )),
              )).toList(),
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 13, color: kTextSub),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '$joined / $max katılımcı',
                        key: ValueKey(joined),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isFull ? '🔴 Dolu!' : '${max - joined} yer kaldı',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isFull ? kAccent : kMint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: kCardElevated,
                    valueColor: AlwaysStoppedAnimation(isFull ? kAccent : catColor),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: kDivider,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          ),

          // ── Action row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: ScaleTransition(
                    scale: _likeScale,
                    child: _ActionBtn(
                      icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: '$_likeCount',
                      color: _liked ? kPrimary : kTextSub,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${e['comments']}',
                  color: kTextSub,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _shareEvent,
                  child: _ActionBtn(
                    icon: Icons.repeat_rounded,
                    label: '${e['shares']}',
                    color: kTextSub,
                  ),
                ),
                const Spacer(),
                // JOIN button
                GestureDetector(
                  onTap: () => _toggleJoin(isFull),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: _joined
                          ? null
                          : (isFull
                              ? null
                              : const LinearGradient(
                                  colors: [kPrimary, kPrimaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )),
                      color: _joined
                          ? kMint.withOpacity(0.12)
                          : (isFull ? kCardElevated : null),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _joined ? kMint : (isFull ? kBorder : Colors.transparent),
                      ),
                      boxShadow: _joined || isFull
                          ? []
                          : [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_joined) ...[
                          Icon(Icons.check_circle_rounded, size: 15, color: kMint),
                          const SizedBox(width: 5),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _joined ? 'Katıldın' : (isFull ? 'Dolu' : 'Katıl'),
                            key: ValueKey(_joined ? 'joined' : (isFull ? 'full' : 'join')),
                            style: TextStyle(
                              color: _joined ? kMint : (isFull ? kTextSub : Colors.white),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(Map<String, dynamic> e, Color catColor) {
    return Stack(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              colors: [
                catColor.withOpacity(0.3),
                kCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: -30,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Text(
                  e['emoji'] as String,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10, right: 10,
          child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 14, color: catColor),
                  const SizedBox(width: 4),
                  Text('Fotoğraf',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SHARE SHEET ──────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  final Map<String, dynamic> event;
  const _ShareSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Etkinliği paylaş',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText),
          ),
          const SizedBox(height: 6),
          Text(
            '${event['title']} • ${event['time']}',
            style: TextStyle(fontSize: 13, color: kTextSub),
          ),
          const SizedBox(height: 20),
          _ShareOption(
            icon: Icons.repeat_rounded,
            color: kPrimary,
            title: 'Tekrar Paylaş',
            subtitle: 'Profilinden herkese göster',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ShareOption(
            icon: Icons.edit_note_rounded,
            color: kAmber,
            title: 'Alıntıyla Paylaş',
            subtitle: 'Yorum ekleyerek paylaş',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ShareOption(
            icon: Icons.link_rounded,
            color: kMint,
            title: 'Bağlantı Kopyala',
            subtitle: 'Uygulamadan dışarı paylaş',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          _ShareOption(
            icon: Icons.send_rounded,
            color: kAccent,
            title: 'Arkadaşa Gönder',
            subtitle: 'Direkt mesaj ile davet et',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: kTextSub)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextSub),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER WIDGETS ──────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _AvatarCircle({required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.33,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionBtn({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 4),
          Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _QuickChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ComposeField extends StatelessWidget {
  final String hint;
  const _ComposeField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: kCardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 14, color: kText),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: TextStyle(color: kTextSub, fontSize: 14),
        ),
      ),
    );
  }
}

class _CategorySelectChip extends StatefulWidget {
  final String label;
  final String emoji;
  const _CategorySelectChip({required this.label, required this.emoji});

  @override
  State<_CategorySelectChip> createState() => _CategorySelectChipState();
}

class _CategorySelectChipState extends State<_CategorySelectChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selected = !_selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _selected ? kPrimary : kCardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _selected ? kPrimary : kBorder),
        ),
        child: Text(
          '${widget.emoji} ${widget.label}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _selected ? Colors.white : kTextSub,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: active ? kPrimaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: active ? kPrimary : kTextSub),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? kPrimary : kTextSub,
            ),
          ),
        ],
      ),
    );
  }
}