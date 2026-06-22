import 'package:flutter/material.dart';
import 'package:pisti_app/screens/home_page.dart';
import 'package:pisti_app/screens/joined_page.dart';
import 'package:pisti_app/screens/login_page.dart';
import 'package:pisti_app/screens/profil_page.dart';
import 'services/api_service.dart';
import 'package:pisti_app/screens/map_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
void main() {
  runApp(const PishtiApp());
}

class PishtiApp extends StatelessWidget {
  const PishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          ),

          // 🔥 EKLE
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        );
  }
}

class MainShell extends StatefulWidget {
  final String username;
  final String userId;
  final List<String> userJoinedEvents;
  const MainShell({super.key, required this.username , required this.userId , required this.userJoinedEvents});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  // 1. Sayfalar listesini late (sonradan doldurulacak) olarak tanımlıyoruz
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // 2. Sınıf oluşturulurken widget.username ve widget.userId değerlerini güvenle buraya aktarıyoruz
    pages = [
      HomeScreen(username: widget.username, userId: widget.userId, initialJoinedEvents: widget.userJoinedEvents,), // Artık generic veya boş gelmeyecek!
      MapPage(), 
      JoinedPage(userId: widget.userId), 
      ProfileScreen(userId: widget.userId), // İstersen profil sayfasına da widget.username paslayabilirsin
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          setState(() {
            index = i;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: const Color(0xFF8A8070),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Harita"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Katıldıklarım"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}