import 'package:flutter/material.dart';

class JoinedPage extends StatelessWidget {
  JoinedPage({super.key});

  final List<Map<String, dynamic>> joinedEvents = [
    {
      'emoji': '🏀',
      'title': 'Basketbol Maçı',
      'time': 'Pazar 17:00',
      'location': 'Kadıköy Spor Salonu',
      'status': 'Yaklaşıyor',
    },
    {
      'emoji': '☕',
      'title': 'Sabah Kahvesi Buluşması',
      'time': 'Cumartesi 09:30',
      'location': 'Moda Sahili',
      'status': 'Katıldın',
    },
    {
      'emoji': '🚴',
      'title': 'Boğaz Bisiklet Turu',
      'time': 'Pazar 08:00',
      'location': 'Beşiktaş',
      'status': 'Planlandı',
    },
  ];

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

            // LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: joinedEvents.length,
                itemBuilder: (context, index) {
                  final e = joinedEvents[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
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
                                const Color(0xFFFF6B00).withOpacity(0.25),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              e['emoji'],
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
                                e['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${e['time']} • ${e['location']}",
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
                            color: _color(e['status']).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _color(e['status']).withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            e['status'],
                            style: TextStyle(
                              color: _color(e['status']),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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