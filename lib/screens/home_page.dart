import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:pisti_app/main.dart';
import 'package:pisti_app/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pisti_app/services/api_service.dart';

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

// 🎯 YENİ: 81 il listesi (şehir seçici için)
const List<String> _turkishCities = [
  'Tümü',
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara',
  'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman',
  'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne',
  'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri',
  'Kilis', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya',
  'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
  'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun',
  'Siirt', 'Sinop', 'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat',
  'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
];

// 🎯 DÜZELTME: Tek tarih yerine tarih ARALIĞI (başlangıç / bitiş)
DateTime? _selectedFilterDateStart;
DateTime? _selectedFilterDateEnd;
String? _selectedFilterCategory;
List<Map<String, dynamic>> _events = [];

// 🎯 YENİ: Seçili şehir (üst bardaki konum pili) ve arama metni
String _selectedCity = 'Edirne';
String _searchQuery = '';

// 🎯 DÜZELTME: "DD/MM/YYYY" formatındaki event tarihini DateTime'a çeviren yardımcı fonksiyon
DateTime? _parseEventDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  final parts = dateStr.split('/');
  if (parts.length != 3) return null;
  try {
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> get _filteredEvents {
  return _events.where((e) {
    final matchCategory = _selectedFilterCategory == null ||
        e['category'] == _selectedFilterCategory;

    bool matchDate = true;
    if (_selectedFilterDateStart != null && _selectedFilterDateEnd != null) {
      final eventDate = _parseEventDate(e['date']?.toString());
      if (eventDate != null) {
        final startDay = DateTime(
          _selectedFilterDateStart!.year,
          _selectedFilterDateStart!.month,
          _selectedFilterDateStart!.day,
        );
        final endDay = DateTime(
          _selectedFilterDateEnd!.year,
          _selectedFilterDateEnd!.month,
          _selectedFilterDateEnd!.day,
          23, 59, 59,
        );
        matchDate = !eventDate.isBefore(startDay) && !eventDate.isAfter(endDay);
      } else {
        matchDate = false;
      }
    }

    // 🎯 YENİ: Şehre göre filtrele (üst bardaki konum pili). "Tümü" ise filtre uygulanmaz.
    final matchCity = _selectedCity == 'Tümü' ||
        (e['city']?.toString().trim().toLowerCase() ==
            _selectedCity.trim().toLowerCase());

    // 🎯 YENİ: Arama çubuğuna göre filtrele
    bool matchSearch = true;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final title = (e['title']?.toString() ?? '').toLowerCase();
      final location = (e['location']?.toString() ?? '').toLowerCase();
      final desc = (e['desc']?.toString() ?? '').toLowerCase();
      final creator = (e['creator']?.toString() ?? '').toLowerCase();
      final category = (e['category']?.toString() ?? '').toLowerCase();
      final city = (e['city']?.toString() ?? '').toLowerCase();
      matchSearch = title.contains(q) ||
          location.contains(q) ||
          desc.contains(q) ||
          creator.contains(q) ||
          category.contains(q) ||
          city.contains(q);
    }

    return matchCategory && matchDate && matchCity && matchSearch;
  }).toList();
}

// 🎯 YENİ: 81 ili arayarak ya da kaydırarak seçtirten ortak şehir seçici (bottom sheet)
Future<String?> _showCityPicker(BuildContext context, {String? initialCity}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      String query = '';
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _turkishCities
              .where((c) => c.toLowerCase().contains(query.trim().toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kTextSub.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ŞEHİR SEÇ',
                  style: TextStyle(
                    color: kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: kCardElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: kTextSub),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 14, color: kText),
                          decoration: InputDecoration.collapsed(
                            hintText: 'İl ara... (ör. İstanbul)',
                            hintStyle: TextStyle(color: kTextSub, fontSize: 14),
                          ),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(color: kTextSub, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: kDivider),
                          itemBuilder: (context, i) {
                            final city = filtered[i];
                            final selected = city == initialCity;
                            return ListTile(
                              title: Text(
                                city,
                                style: TextStyle(
                                  color: selected ? kPrimary : kText,
                                  fontWeight:
                                      selected ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: selected
                                  ? Icon(Icons.check_circle_rounded,
                                      color: kPrimary, size: 18)
                                  : null,
                              onTap: () => Navigator.pop(context, city),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final String username;
  final String userId;
  final List<String> initialJoinedEvents;

  const HomeScreen({super.key, required this.username, required this.userId, required this.initialJoinedEvents});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  
  late Set<String> _myJoinedEventIds;
  Map<String, int> _joinedCounts = {};

  // 🎯 YENİ: Etkinlik oluştururken seçilen şehir
  String? _selectedCreateCity;

Future<void> _submitEvent() async {
  if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lütfen etkinlik adı ve konum alanlarını doldurun!')),
    );
    return;
  }

  // 🎯 EĞER TARİH SEÇİLMEDİYSE BUGÜNÜN TARİHİNİ DD/MM/YYYY FORMATINDA AYARLA
  String eventDate = _dateController.text;
  if (eventDate.isEmpty) {
    final now = DateTime.now();
    eventDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  final Map<String, dynamic> eventData = {
    "title": _titleController.text,
    "location": _locationController.text,
    "city": _selectedCreateCity ?? _selectedCity, // 🎯 YENİ: il bilgisi DB'ye gidiyor
    "date": eventDate, // 🎯 DÜZELTME: Artık tarih verisi de DB'ye gidiyor
    "time": _timeController.text.isEmpty ? "Bugün" : _timeController.text,
    "max": int.tryParse(_maxPlayersController.text) ?? 10,
    "desc": _descController.text,
    "emoji": _selectedCategoryEmoji,
    "category": _selectedCategoryLabel,
    "categoryColor": "#FF6B00",
    "joined": 1,
    "likes": 0,
    "comments": 0, 
    "shares": 0,
    "creator": widget.username,
    "avatar": (widget.username.trim().isNotEmpty) 
      ? widget.username.trim()[0].toUpperCase() 
      : "U",
    "avatarColor": "#10B981",
    "tags": [_selectedCategoryLabel, "Yeni"],
    "imageUrl": null
  };
    
  final response = await ApiService.createEvent(eventData, widget.userId);
  if (!mounted) return;

  if (response["success"] == true) {
    final createdEvent = response["data"];
    if (createdEvent != null) {
      final String newEventId = (createdEvent["_id"] ?? createdEvent["id"] ?? "").toString();
      
      if (newEventId.isNotEmpty) {
        setState(() {
          _myJoinedEventIds.add(newEventId);
        });
      }
    }

    _titleController.clear();
    _locationController.clear();
    _dateController.clear();
    _timeController.clear();
    _maxPlayersController.clear();
    _descController.clear();
    setState(() {
      _selectedCreateCity = null;
    });
    
    _toggleCompose();

    await _loadEvents(); 

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etkinlik başarıyla paylaşıldı! 🎉')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response["message"] ?? 'Etkinlik paylaşılamadı.')),
    );
  }
}

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale("tr", "TR"),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}/"
            "${pickedDate.month.toString().padLeft(2, '0')}/"
            "${pickedDate.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text =
            "${pickedTime.hour.toString().padLeft(2, '0')}:"
            "${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }  

  // 🎯 YENİ: Üst bardaki şehir pilini açar, seçilince ana akışı filtreler
  Future<void> _pickHomeCity() async {
    final picked = await _showCityPicker(context, initialCity: _selectedCity);
    if (picked != null) {
      setState(() {
        _selectedCity = picked;
      });
    }
  }

  // 🎯 YENİ: Etkinlik oluşturma formundaki şehir seçici
  Future<void> _pickCreateCity() async {
    final picked = await _showCityPicker(context, initialCity: _selectedCreateCity);
    if (picked != null) {
      setState(() {
        _selectedCreateCity = picked == 'Tümü' ? null : picked;
      });
    }
  }

  final _scrollController = ScrollController();
  bool _isComposeExpanded = false;
  late AnimationController _composeAnimCtrl;
  late Animation<double> _composeAnim;
  int _bottomNavIndex = 0;
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController(); // 🎯 YENİ: arama çubuğu controller'ı

  String _selectedCategoryLabel = 'Spor';
  String _selectedCategoryEmoji = '🏀';
  Color _selectedCategoryColor = const Color(0xFFFF6B00);
  
Future<void> _loadEvents() async {
  try {
    final data = await ApiService.getEvents();
    final updatedJoinedEvents = await ApiService.getUserJoinedEvents(widget.userId);

    if (!mounted) return;

    setState(() {
      _events = List<Map<String, dynamic>>.from(data);
      _myJoinedEventIds = Set<String>.from(updatedJoinedEvents);
      _joinedCounts.clear();
      for (var event in _events) {
        final String eventId = (event['_id'] ?? event['id'] ?? '').toString();
        if (eventId.isNotEmpty) {
          _joinedCounts[eventId] = int.tryParse(event['joined'].toString()) ?? 0;
        }
      }
    });
  } catch (e) {
    print("LOAD EVENTS HATASI: $e");
  }
}

  @override
void initState() {
  super.initState();
  _myJoinedEventIds = Set<String>.from(widget.initialJoinedEvents);
  _selectedCreateCity = _selectedCity; // 🎯 YENİ: oluşturma formu varsayılan olarak seçili şehirle başlasın
  _loadEvents();

  _composeAnimCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  _composeAnim = CurvedAnimation(
    parent: _composeAnimCtrl,
    curve: Curves.easeInOutCubic,
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    _composeAnimCtrl.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _maxPlayersController.dispose();
    _descController.dispose();
    _searchController.dispose();
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

 void _onJoinChanged(String eventId, bool joined) {
  setState(() {
    final currentCount = _joinedCounts[eventId] ?? 0; 
    
    if (joined) {
      _joinedCounts[eventId] = currentCount + 1;
    } else {
      _joinedCounts[eventId] = (currentCount - 1).clamp(0, 9999);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // 🎯 DÜZELTME: Compose açıkken dışarıya tıklanınca kapanması için GestureDetector sarıldı
      child: GestureDetector(
        onTap: () {
          if (_isComposeExpanded) {
            _toggleCompose();
            FocusScope.of(context).unfocus();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildSearchBar(), // 🎯 YENİ: arama çubuğu
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildComposeBox()),
                      
                      SliverToBoxAdapter(child: _buildSectionHeader()),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final filtered = _filteredEvents;
                            final String currentEventId = (filtered[i]['_id'] ?? filtered[i]['id'] ?? '').toString();
                            final bool hasJoinedBefore = _myJoinedEventIds.contains(currentEventId);
                            final int currentCount = _joinedCounts[currentEventId] ?? int.tryParse(filtered[i]['joined'].toString()) ?? 0;

                            return _EventCard(
                              key: ValueKey(currentEventId), 
                              event: filtered[i],
                              eventId: currentEventId, 
                              userId: widget.userId, 
                              isAlreadyJoined: hasJoinedBefore, 
                              currentJoined: currentCount,
                              onJoinChanged: (joined) {
                                _onJoinChanged(currentEventId, joined);
                                setState(() {
                                  if (joined) {
                                    _myJoinedEventIds.add(currentEventId);
                                  } else {
                                    _myJoinedEventIds.remove(currentEventId);
                                  }
                                });
                              },
                            );
                          },
                          childCount: _filteredEvents.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                )
              ],
            ),
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
          _buildLocationPill(), // 🎯 DÜZELTME: bildirim zili kaldırıldı, sadece şehir pili kaldı
        ],
      ),
    );
  }

  // ── LOCATION PILL (81 il seçici) ────────────────────────────────────────────

  Widget _buildLocationPill() {
    return GestureDetector(
      onTap: _pickHomeCity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, size: 14, color: kPrimary),
            const SizedBox(width: 4),
            Text(
              _selectedCity,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: kTextSub),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: kTextSub),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: InputDecoration.collapsed(
                  hintText: 'Etkinlik, konum veya kategori ara...',
                  hintStyle: TextStyle(color: kTextSub, fontSize: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(Icons.close_rounded, size: 18, color: kTextSub),
              ),
          ],
        ),
      ),
    );
  }

  // ── COMPOSE BOX ────────────────────────────────────────────────────────────

  Widget _buildComposeBox() {
    return GestureDetector(
      // İç tıklamaların üst GestureDetector'a geçmesini engelle
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.12),
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
                          color: kPrimary.withValues(alpha: 0.45),
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
                      onTap: () {
                        if (_isComposeExpanded) {
                          _submitEvent();
                        } else {
                          _toggleCompose();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: _isComposeExpanded ? const Color(0xFFFF6B00) : kCardElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _isComposeExpanded ? Colors.transparent : kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isComposeExpanded ? 'Etkinliği Paylaş' : 'Ne yapmak istiyorsun?',
                              style: TextStyle(
                                color: _isComposeExpanded ? Colors.white : kTextSub,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _isComposeExpanded ? '🚀' : '🎯', 
                              style: const TextStyle(fontSize: 16),
                            ),
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
            // 🎯 DÜZELTME: Alttaki "Paylaş" butonu kaldırıldı, sadece QuickChip'ler kaldı
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _QuickChip(icon: '🏀', label: 'Spor', color: kPrimary),
                  const SizedBox(width: 8),
                  _QuickChip(icon: '☕', label: 'Sosyal', color: kAmber),
                  const SizedBox(width: 8),
                  _QuickChip(icon: '🗺️', label: 'Harita', color: kMint),
                ],
              ),
            ),
          ],
        ),
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
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: '🎯  Etkinlik adı (ör. "Basketbol maçı")'),
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(hintText: '📍  Konum (ör. "Kapalı Spor Salonu")'),
          ),
          const SizedBox(height: 8),

          // 🎯 YENİ: Şehir seçici (81 il, arayarak veya kaydırarak)
          GestureDetector(
            onTap: _pickCreateCity,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: kCardElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, size: 16, color: kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCreateCity ?? '🏙️  Şehir seç',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedCreateCity != null ? kText : kTextSub,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: kTextSub),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    hintText: '📅  Tarih seç',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: const InputDecoration(
                    hintText: '🕐  Saat seç',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _maxPlayersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '👥  Maks. katılımcı sayısı'),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: TextField(
              controller: _descController,
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
              children: _categories.map((c) {
                final isSelected = _selectedCategoryLabel == c['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c['label'] as String),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategoryLabel = c['label'] as String;
                        _selectedCategoryEmoji = c['icon'] as String;
                        if (_selectedCategoryLabel == 'Spor') _selectedCategoryColor = const Color(0xFFFF6B00);
                        else _selectedCategoryColor = Colors.blue; 
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── SECTION HEADER ──────────────────────────────────────────────────────────
  
  Widget _buildSectionHeader() 
  { void _openFilterSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kTextSub.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "FİLTRELE",
                  style: TextStyle(
                    color: kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: kCardElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kBorder),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.date_range_rounded, color: kPrimary),
                    title: Text(
                      (_selectedFilterDateStart == null || _selectedFilterDateEnd == null)
                          ? "Tarih aralığı seç"
                          : "${_selectedFilterDateStart!.day}.${_selectedFilterDateStart!.month}.${_selectedFilterDateStart!.year}  -  "
                            "${_selectedFilterDateEnd!.day}.${_selectedFilterDateEnd!.month}.${_selectedFilterDateEnd!.year}",
                      style: const TextStyle(
                        color: kText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: kTextSub),
                    onTap: () async {
                      final pickedRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: (_selectedFilterDateStart != null && _selectedFilterDateEnd != null)
                            ? DateTimeRange(
                                start: _selectedFilterDateStart!,
                                end: _selectedFilterDateEnd!,
                              )
                            : null,
                        locale: const Locale("tr", "TR"),
                      );

                      if (pickedRange != null) {
                        setModalState(() {
                          _selectedFilterDateStart = pickedRange.start;
                          _selectedFilterDateEnd = pickedRange.end;
                        });
                        setState(() {});
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Kategori",
                  style: TextStyle(
                    color: kTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final selected =
                        _selectedFilterCategory == c['label'];

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          _selectedFilterCategory =
                              selected ? null : c['label'] as String;
                        });
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? kPrimary
                              : kCardElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? kPrimary
                                : kBorder,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: kPrimary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c['icon'] as String),
                            const SizedBox(width: 6),
                            Text(
                              c['label'] as String,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : kText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilterCategory = null;
                        _selectedFilterDateStart = null;
                        _selectedFilterDateEnd = null;
                      });
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "FİLTREYİ SIFIRLA",
                      style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
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
                // 🎯 DÜZELTME: sabit "Edirne" yerine seçili şehir gösteriliyor
                '${_selectedCity == "Tümü" ? "Türkiye" : _selectedCity} · ${_filteredEvents.length} etkinlik',
                style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
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
            color: Colors.black.withValues(alpha: 0.3),
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
              color: kPrimary.withValues(alpha: 0.5),
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
                color: kPrimary.withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: kAccent.withValues(alpha: 0.2),
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

    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.28), 2.6, paint);
    final leftBody = Path()
      ..moveTo(size.width * 0.12, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.58, size.width * 0.44, size.height * 0.82);
    canvas.drawPath(leftBody, strokePaint..style = PaintingStyle.stroke);

    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), 2.6, paint..color = Colors.white.withValues(alpha: 0.85));
    final rightBody = Path()
      ..moveTo(size.width * 0.56, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.58, size.width * 0.88, size.height * 0.82);
    canvas.drawPath(rightBody, strokePaint..color = Colors.white.withValues(alpha: 0.85));

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

// ─── EVENT CARD ───────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final int currentJoined;
  final ValueChanged<bool> onJoinChanged;
  final String userId;
  final String eventId;
  final bool isAlreadyJoined;

  const _EventCard({
    super.key,
    required this.event,
    required this.currentJoined,
    required this.onJoinChanged,
    required this.userId,
    required this.eventId,
    required this.isAlreadyJoined,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {

  late bool _joined;
  bool _liked = false;
  late int _likeCount;
  late AnimationController _likeAnim;
  late Animation<double> _likeScale;

  // 🎯 YENİ: Yorum listesi ve yorum sayacı
  List<Map<String, dynamic>> _comments = [];
  bool _showComments = false;
  final _commentController = TextEditingController();

  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.blue;
    }
    String cleanHex = hexString.replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF' + cleanHex;
    }
    return Color(int.parse(cleanHex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _joined = widget.isAlreadyJoined;
    _likeCount = int.parse(widget.event['likes'].toString());
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
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlreadyJoined != oldWidget.isAlreadyJoined) {
      setState(() {
        _joined = widget.isAlreadyJoined; 
      });
    }
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _likeAnim.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  // 🎯 YENİ: Yorum bölümünü aç/kapat
  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
    HapticFeedback.lightImpact();
  }

  // 🎯 YENİ: Yorum gönder
  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add({
        'author': 'Sen',
        'text': text,
        'time': 'Şimdi',
      });
    });
    _commentController.clear();
    HapticFeedback.lightImpact();
  }

void _toggleJoin(bool isFull) async {
  if (isFull && !_joined) return;

  final newJoined = !_joined;

  widget.onJoinChanged(newJoined);
  setState(() {
    _joined = newJoined;
  });

  if (newJoined) {
    print("API'YE GİDEN KATILMA İSTEĞİ -> userId: '${widget.userId}', eventId: '${widget.eventId}'");
    
    final result = await ApiService.joinEvent(
      userId: widget.userId,
      eventId: widget.eventId,
    );

    if (result["success"] != true) {
      widget.onJoinChanged(!newJoined);
      setState(() {
        _joined = !newJoined;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Veritabanına kaydedilemedi.")),
      );
    }
  } else {
    print("API'YE GİDEN AYRILMA İSTEĞİ -> userId: '${widget.userId}', eventId: '${widget.eventId}'");

    final result = await ApiService.leaveEvent(
      userId: widget.userId,
      eventId: widget.eventId,
    );

    if (result["success"] != true) {
      widget.onJoinChanged(!newJoined);
      setState(() {
        _joined = !newJoined;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Veritabanından silinemedi.")),
      );
    }
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
    final max = int.parse(e['max'].toString());
    final pct = (joined / max).clamp(0.0, 1.0);
    final isFull = joined >= max;
    final tags = List<String>.from(e['tags'] ?? []); 

    final catColor = _parseHexColor(e['categoryColor']?.toString()); 
    final avatarColor = _parseHexColor(e['avatarColor']?.toString());

    // 🎯 YENİ: Toplam yorum sayısı (backend'den gelen + yerel eklenen)
    final int baseCommentCount = int.tryParse(e['comments'].toString()) ?? 0;
    final int totalComments = baseCommentCount + _comments.length;

    // 🎯 YENİ: Etkinlik tarihi (ve varsa şehir) gösterimi için hazırlık
    final String eventDateText = (e['date']?.toString().trim().isNotEmpty ?? false)
        ? e['date'].toString()
        : 'Tarih belirtilmedi';
    final String eventCity = (e['city']?.toString().trim() ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: catColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                _AvatarCircle(initials: e['avatar'] as String, color: avatarColor, size: 36),
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
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: catColor.withValues(alpha: 0.25)),
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
                    eventCity.isNotEmpty ? '${e['location']} · $eventCity' : e['location'] as String,
                    style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 🎯 YENİ: Etkinlik kartında tarih ve saat gösterimi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: kTextSub),
                const SizedBox(width: 4),
                Text(
                  eventDateText,
                  style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w600),
                ),
                if ((e['time']?.toString().trim().isNotEmpty ?? false)) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.access_time_rounded, size: 12, color: kTextSub),
                  const SizedBox(width: 4),
                  Text(
                    e['time'].toString(),
                    style: TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              e['desc'] as String,
              style: TextStyle(fontSize: 14, color: kText.withValues(alpha: 0.6), height: 1.55),
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
                  border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
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
                // 🎯 DÜZELTME: Beğeni butonu çalışır hale getirildi
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
                // 🎯 DÜZELTME: Yorum butonu tıklanınca yorum bölümünü açıyor
                GestureDetector(
                  onTap: _toggleComments,
                  child: _ActionBtn(
                    icon: _showComments
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    label: '$totalComments',
                    color: _showComments ? kPrimary : kTextSub,
                  ),
                ),
                const SizedBox(width: 4),
                // 🎯 DÜZELTME: Paylaş butonu çalışır hale getirildi
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
                          ? kMint.withValues(alpha: 0.12)
                          : (isFull ? kCardElevated : null),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _joined ? kMint : (isFull ? kBorder : Colors.transparent),
                      ),
                      boxShadow: _joined || isFull
                          ? []
                          : [
                              BoxShadow(
                                color: kPrimary.withValues(alpha: 0.45),
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

          // 🎯 YENİ: Yorum bölümü (açılır/kapanır)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: _showComments
                ? _buildCommentsSection()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 🎯 YENİ: Yorum bölümü widget'ı
  Widget _buildCommentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: kCardElevated,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: kDivider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mevcut yorumlar
          if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Henüz yorum yok. İlk yorumu sen yap!',
                style: TextStyle(fontSize: 13, color: kTextSub),
              ),
            )
          else
            ...(_comments.map((c) => _buildCommentItem(c)).toList()),

          const SizedBox(height: 10),

          // Yorum yazma alanı
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(fontSize: 13, color: kText),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Yorum yaz...',
                      hintStyle: TextStyle(color: kTextSub, fontSize: 13),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 YENİ: Tek yorum satırı widget'ı
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (comment['author'] as String)[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment['author'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comment['time'] as String,
                        style: TextStyle(fontSize: 10, color: kTextSub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment['text'] as String,
                    style: TextStyle(fontSize: 13, color: kText.withValues(alpha: 0.8)),
                  ),
                ],
              ),
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
                catColor.withValues(alpha: 0.3),
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
                    color: catColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: -30,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.10),
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
                color: kCard.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
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
                color: color.withValues(alpha: 0.15),
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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