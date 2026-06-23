import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pisti_app/services/api_service.dart'; // ApiService'ini import ettiğinden emin ol

class JoinedPage extends StatefulWidget {
  final String userId; // <-- Giriş yapan kullanıcının ID'si gerekiyor

  const JoinedPage({super.key, required this.userId});

  @override
  State<JoinedPage> createState() => _JoinedPageState();
}

class _JoinedPageState extends State<JoinedPage> {
  List<Map<String, dynamic>> _joinedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJoinedEvents();
  }

  // Veritabanından kullanıcının katıldığı etkinlikleri çeken fonksiyon
  Future<void> _fetchJoinedEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUserJoinedEventsDetails(widget.userId);
      setState(() {
        _joinedEvents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("JoinedPage yükleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP BAR ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Piş",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B00),
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      "ti",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 4, bottom: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Katıldıkların",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // LIST VEYA YÜKLENİYOR GÖSTERGESİ
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                      ),
                    )
                  : _joinedEvents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFFFF6B00),
                          backgroundColor: const Color(0xFF1A1A1A),
                          onRefresh: _fetchJoinedEvents, // Aşağı kaydırınca yeniler
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _joinedEvents.length,
                            itemBuilder: (context, index) {
                              final e = _joinedEvents[index];

                              return GestureDetector(
                                onTap: () => _showEventDetails(e),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // emoji
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFF6B00).withValues(alpha: 0.25),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            e['emoji'] ?? '🎉',
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e['title'] ?? 'Başlıksız Etkinlik',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${e['date'] ?? e['time'] ?? 'Bugün'} • ${e['location'] ?? e['loc'] ?? 'Belirtilmedi'}",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // status
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _color(e['status'] ?? 'Katıldın').withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _color(e['status'] ?? 'Katıldın').withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          e['status'] ?? 'Katıldın',
                                          style: TextStyle(
                                            color: _color(e['status'] ?? 'Katıldın'),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Tıklanınca Açılacak Detay Bottom Sheet Alanı
  void _showEventDetails(Map<String, dynamic> event) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65, // Tarih satırı eklendiği için yüksekliği azıcık artırdık
        decoration: const BoxDecoration(
          color: Color(0xFF161616),
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
                  color: Colors.grey.shade700,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        event['time'] ?? 'Zaman Belirtilmedi',
                        style: const TextStyle(
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 🎯 Eklenen Tarih Satırı (Backend'den date veya tarih anahtarını kontrol eder)
            _infoRow(
              Icons.calendar_today_rounded,
              event['date'] ?? event['tarih'] ?? 'Tarih Belirtilmedi',
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.location_on_rounded,
              event['location'] ?? event['loc'] ?? 'Belirtilmedi',
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.people_alt_rounded,
              "${event['joined'] ?? 1} Katılımcı",
            ),
            const SizedBox(height: 30),
            const Text(
              "Etkinlik Hakkında",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event['description'] ?? event['desc'] ?? 'Açıklama bulunmuyor.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
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

  // Detay alanındaki ikonlu satırlar için yardımcı widget
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF6B00)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Henüz hiçbir etkinliğe katılmamışsa gösterilecek şık bir ekran
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            "Henüz hiçbir etkinliğe katılmadın",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Keşfet sayfasından yeni etkinlikler bulabilirsin.",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _color(String status) {
    switch (status) {
      case 'Katıldın':
        return const Color(0xFF39D98A);
      case 'Yaklaşıyor':
        return const Color(0xFFFFB020);
      case 'Planlandı':
        return const Color(0xFF4DA3FF);
      default:
        return Colors.grey;
    }
  }
}