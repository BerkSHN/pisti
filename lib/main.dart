import 'package:flutter/material.dart';
import 'package:pisti_app/screens/home_page.dart';
import 'package:pisti_app/screens/joined_page.dart';
import 'package:pisti_app/screens/login_page.dart';
import 'package:pisti_app/screens/profil_page.dart';
import 'services/api_service.dart';

import 'package:pisti_app/screens/map_page.dart';
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
      home: const LoginScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = [
    HomeScreen(),
    MapPage(), // Map
    JoinedPage(), // Favorites
    ProfileScreen(),
  ];

  

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