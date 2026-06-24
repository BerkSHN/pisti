
import 'package:flutter/material.dart';
import 'package:pisti_app/services/api_service.dart';
import 'package:pisti_app/theme/app_colors.dart';

class CalendarPage extends StatefulWidget {
  final String userId;

  const CalendarPage({super.key, required this.userId});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int? _selectedDay;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _months = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
  ];

  final List<String> _weekDays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUserJoinedEventsDetails(widget.userId);

      if (data.isNotEmpty) {
        debugPrint("=== CalendarPage: İlk etkinlik keys: ${data.first.keys.toList()}");
        debugPrint("=== CalendarPage: İlk etkinlik: ${data.first}");
      } else {
        debugPrint("=== CalendarPage: API boş liste döndürdü");
      }

      setState(() {
        _allEvents = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Takvim yükleme hatası: $e");
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final matchesSearch = query.isEmpty ||
            (event['title'] ?? '').toLowerCase().contains(query) ||
            (event['location'] ?? '').toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  /// API'den gelen herhangi bir tarih string'ini DateTime'a çevirir.
  DateTime? _parseEventDate(dynamic raw) {
    if (raw == null) return null;

    if (raw is int || raw is double) {
      final ms = raw is int ? raw : (raw as double).toInt();
      final epoch = ms > 1e11 ? ms : ms * 1000;
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final maybeNum = int.tryParse(s);
    if (maybeNum != null) {
      final epoch = maybeNum > 1e11 ? maybeNum : maybeNum * 1000;
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }

    if (s.contains('/')) {
      try {
        final parts = s.split(' ');
        final dateParts = parts[0].split('/');
        if (dateParts.length == 3) {
          final day   = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year  = int.parse(dateParts[2]);
          int hour = 0, minute = 0;
          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            hour   = int.tryParse(timeParts[0]) ?? 0;
            minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
          }
          return DateTime(year, month, day, hour, minute);
        }
      } catch (_) {}
    }

    if (s.contains('-')) {
      final normalized = s.replaceFirst(
        RegExp(r'(\d{4}-\d{2}-\d{2})\s(\d{2}:\d{2})'),
        r'$1T$2',
      );
      try {
        return DateTime.parse(normalized);
      } catch (_) {}
      final datePart = s.split(RegExp(r'[T ]')).first;
      try {
        return DateTime.parse(datePart);
      } catch (_) {}
    }

    return null;
  }

  /// Etkinlik verisinden tarih bilgisi taşıyan ham değeri döndürür.
  /// 🎯 DÜZELTME: Saat kaybını önlemek için hem 'date' hem 'time' birleştirilerek kontrol ediliyor.
  dynamic _extractRawDate(Map<String, dynamic> event) {
    // Öncelikle backend'deki birleşik datetime alanını dene
    if (event.containsKey('datetime') && event['datetime'] != null && event['datetime'].toString().isNotEmpty) {
      return event['datetime'];
    }
    
    // Eğer date ve time ayrı ayrı varsa birleştirerek anlamlı bir format üret
    if (event.containsKey('date') && event['date'] != null && event['date'].toString().isNotEmpty) {
      final dateStr = event['date'].toString();
      final timeStr = (event.containsKey('time') && event['time'] != null) ? event['time'].toString() : '00:00';
      return "$dateStr $timeStr".strip();
    }

    const fallbackKeys = [
      'startTime', 'start_time', 'eventDate', 'event_date',
      'dateTime', 'startDate', 'start_date', 'createdAt',
      'created_at', 'scheduledAt', 'scheduled_at', 'hour',
    ];
    for (final key in fallbackKeys) {
      if (event.containsKey(key) && event[key] != null) {
        return event[key];
      }
    }
    return null;
  }

  /// Ayın etkinlik haritası: gün numarası → etkinlik listesi
  Map<int, List<Map<String, dynamic>>> _buildDayEventMap() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final event in _filteredEvents) {
      final raw = _extractRawDate(event);
      final dt = _parseEventDate(raw);
      if (dt != null && dt.year == _selectedYear && dt.month == _selectedMonth) {
        map.putIfAbsent(dt.day, () => []).add(event);
      }
    }
    return map;
  }

  int _getDaysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  int _getFirstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _selectedDay = null;
    });
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kTextSub.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, kPrimaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          event['emoji'] ?? '🎉',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Başlıksız Etkinlik',
                            style: const TextStyle(
                              color: kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event['status'] ?? 'Katıldın',
                              style: const TextStyle(
                                color: kPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: kBorder.withOpacity(0.6)),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.calendar_today_rounded, "Tarih",
                    _formatEventDate(_extractRawDate(event))),
                _buildDetailRow(Icons.access_time_filled_rounded, "Saat",
                    _formatEventTime(event)), // 🎯 DÜZELTME: Doğrudan event haritası gönderiliyor
                _buildDetailRow(Icons.location_on_rounded, "Mekan",
                    event['location'] ?? 'Belirtilmedi'),
                if ((event['desc'] ?? event['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: kBorder.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(
                    "Açıklama",
                    style: TextStyle(
                      color: kTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event['desc'] ?? event['description'],
                    style: const TextStyle(color: kText, fontSize: 14, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatEventDate(dynamic raw) {
    final dt = _parseEventDate(raw);
    if (dt != null) return "${dt.day} ${_months[dt.month - 1]} ${dt.year}";
    final s = raw?.toString() ?? '';
    return s.isNotEmpty ? s : 'Belirtilmedi';
  }

  /// 🎯 DÜZELTME: Backend'den gelen münferit 'time' alanını koruyarak güvenli saat basımı sağlar
  String _formatEventTime(Map<String, dynamic> event) {
    if (event.containsKey('time') && event['time'] != null && event['time'].toString().isNotEmpty) {
      return event['time'].toString();
    }
    final raw = _extractRawDate(event);
    final dt = _parseEventDate(raw);
    if (dt != null) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    final s = raw?.toString() ?? '';
    if (s.contains(' ')) return s.split(' ').last;
    if (s.contains('T')) return s.split('T').last.substring(0, 5);
    return 'Belirtilmedi';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: kTextSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayEvents(int day, List<Map<String, dynamic>> events) {
    if (events.isEmpty) return;
    if (events.length == 1) {
      _showEventDetails(events.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextSub.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "$day ${_months[_selectedMonth - 1]} Etkinlikleri",
              style: const TextStyle(
                  color: kText, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...events.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(e['emoji'] ?? '🎉',
                      style: const TextStyle(fontSize: 28)),
                  title: Text(e['title'] ?? 'Etkinlik',
                      style: const TextStyle(
                          color: kText, fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    _formatEventTime(e), // 🎯 DÜZELTME: Güncel metod entegrasyonu
                    style: const TextStyle(color: kTextSub, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEventDetails(e);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEventMap = _buildDayEventMap();
    final totalDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    final firstWeekday = _getFirstWeekdayOfMonth(_selectedYear, _selectedMonth);
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == _selectedYear && today.month == _selectedMonth;

    final leadingBlanks = firstWeekday - 1;
    final gridCellCount = leadingBlanks + totalDays;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildMonthNavigator(),
            _buildWeekDayHeaders(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kPrimary)))
                  : _buildCalendarGrid(leadingBlanks, totalDays,
                      gridCellCount, dayEventMap, today, isCurrentMonth),
            ),
            if (_searchController.text.isNotEmpty) _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimary, kPrimaryDark]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Center(
              child: Text("📅", style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "Takvim",
            style: TextStyle(
                color: kText, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedYear = DateTime.now().year;
                _selectedMonth = DateTime.now().month;
                _selectedDay = DateTime.now().day;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Bugün",
                style: TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: kText),
        decoration: InputDecoration(
          hintText: "Etkinlik veya mekan ara...",
          hintStyle:
              TextStyle(color: kTextSub.withOpacity(0.6), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: kPrimary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: kTextSub.withOpacity(0.7), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: kCard,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navArrow(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          GestureDetector(
            onTap: () => _showMonthYearPicker(),
            child: Row(
              children: [
                Text(
                  _months[_selectedMonth - 1],
                  style: const TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 6),
                Text(
                  "$_selectedYear",
                  style: TextStyle(
                      color: kTextSub,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: kTextSub, size: 18),
              ],
            ),
          ),
          _navArrow(Icons.chevron_right_rounded, () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Icon(icon, color: kText, size: 20),
      ),
    );
  }

  void _showMonthYearPicker() {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: kTextSub.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Yıl",
                      style: TextStyle(
                          color: kTextSub,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Row(
                    children: [2024, 2025, 2026, 2027].map((y) {
                      final sel = y == tempYear;
                      return GestureDetector(
                        onTap: () => setStateModal(() => tempYear = y),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? kPrimary : kBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text("$y",
                              style: TextStyle(
                                  color: sel ? Colors.white : kText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final sel = (i + 1) == tempMonth;
                  return GestureDetector(
                    onTap: () => setStateModal(() => tempMonth = i + 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_months[i],
                          style: TextStyle(
                              color: sel ? Colors.white : kText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedYear = tempYear;
                      _selectedMonth = tempMonth;
                      _selectedDay = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Uygula",
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDayHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        children: _weekDays.map((day) {
          final isWeekend = day == "Cmt" || day == "Paz";
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isWeekend ? kPrimary.withOpacity(0.7) : kTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    int leadingBlanks,
    int totalDays,
    int gridCellCount,
    Map<int, List<Map<String, dynamic>>> dayEventMap,
    DateTime today,
    bool isCurrentMonth,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 0.72,
      ),
      itemCount: gridCellCount,
      itemBuilder: (ctx, index) {
        if (index < leadingBlanks) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - leadingBlanks + 1;
        final events = dayEventMap[dayNumber] ?? [];
        final hasEvent = events.isNotEmpty;
        final isToday = isCurrentMonth && today.day == dayNumber;
        final isSelected = _selectedDay == dayNumber;
        final isWeekend = (index % 7) == 5 || (index % 7) == 6;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = dayNumber);
            if (hasEvent) _showDayEvents(dayNumber, events);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimary
                  : isToday
                      ? kPrimary.withOpacity(0.15)
                      : hasEvent
                          ? kCard
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: kPrimary, width: 1.5)
                  : hasEvent && !isSelected
                      ? Border.all(
                          color: kPrimary.withOpacity(0.3), width: 1)
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "$dayNumber",
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? kPrimary
                            : isWeekend
                                ? kPrimary.withOpacity(0.7)
                                : kText,
                    fontSize: 13,
                    fontWeight: (isToday || isSelected || hasEvent)
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                if (hasEvent) ...[
                  const SizedBox(height: 3),
                  events.length == 1
                      ? Text(
                          events.first['emoji'] ?? '🎉',
                          style: const TextStyle(fontSize: 11),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0;
                                i < events.length.clamp(0, 3);
                                i++)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      events.first['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : kText,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: _filteredEvents.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 22, color: kTextSub.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Text(
                    "Etkinlik bulunamadı",
                    style: TextStyle(
                        color: kTextSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              itemCount: _filteredEvents.length,
              separatorBuilder: (_, __) =>
                  Divider(color: kBorder.withOpacity(0.5), height: 1),
              itemBuilder: (ctx, i) {
                final e = _filteredEvents[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 2, horizontal: 0),
                  leading: Text(e['emoji'] ?? '🎉',
                      style: const TextStyle(fontSize: 24)),
                  title: Text(
                    e['title'] ?? 'Etkinlik',
                    style: const TextStyle(
                        color: kText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  subtitle: Text(
                    e['location'] ?? '',
                    style: TextStyle(color: kTextSub, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: kTextSub, size: 18),
                  onTap: () => _showEventDetails(e),
                );
              },
            ),
    );
  }
}

// 🎯 DÜZELTME: String uzantısı kodun en altına güvenli çalışması için eklendi.
extension on String {
  String strip() => trim();
}

