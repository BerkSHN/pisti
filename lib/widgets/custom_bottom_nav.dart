import 'package:flutter/material.dart';
import 'package:pisti_app/screens/home_page.dart';
import 'package:pisti_app/screens/profil_page.dart';
import 'package:pisti_app/theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  // 1. Kullanıcı adı verisini karşılayabilmesi için değişken ekliyoruz
  final String username;
  // 1. Kullanıcı ID verisini karşılayabilmesi için değişken ekliyoruz
  final String userId;
  final List<String> userJoinedEvents;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.username,
    required this.userId,
    required this.userJoinedEvents, // 1. Zorunlu parametre haline getiriyoruz
     // 2. Zorunlu parametre haline getiriyoruz
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;

    switch (index) {
      case 0:
        // 3. Hatanın çözümü: 'widget.username' yerine doğrudan yukarıda tanımladığımız 'username' değişkenini veriyoruz
        page = HomeScreen(username: username, userId: userId, initialJoinedEvents: userJoinedEvents,);
        break;
      case 1:
        // Şimdilik test amaçlı HomeScreen kalabilir, ileride MapScreen() vb. ile değiştirirsiniz
        page = HomeScreen(username: username , userId: userId, initialJoinedEvents: userJoinedEvents,);
        break;
      case 2:
        page = HomeScreen(username: username , userId: userId, initialJoinedEvents: userJoinedEvents,);
        break;
      case 3:
        page = ProfileScreen(userId: userId);
        break;
      default:
        page = HomeScreen(username: username, userId: userId, initialJoinedEvents: userJoinedEvents,);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: kCard,
        border: Border(
          top: BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Keşfet',
            index: 0,
            current: currentIndex,
            onTap: (i) => _navigate(context, i),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Harita',
            index: 1,
            current: currentIndex,
            onTap: (i) => _navigate(context, i),
          ),
          const SizedBox(width: 58),
          _NavItem(
            icon: Icons.bookmark_border_rounded,
            label: 'Katıldıklarım',
            index: 2,
            current: currentIndex,
            onTap: (i) => _navigate(context, i),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            index: 3,
            current: currentIndex,
            onTap: (i) => _navigate(context, i),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: active ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.blue : Colors.grey)),
          ],
        ),
      ),
    );
  }
}