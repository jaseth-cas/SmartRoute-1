import 'package:flutter/material.dart';

class StudentBottomBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const StudentBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    if (currentRoute == '/student_home') currentIndex = 0;
    if (currentRoute == '/routes') currentIndex = 1;
    if (currentRoute == '/map') currentIndex = 2;
    if (currentRoute == '/eta') currentIndex = 3;
    if (currentRoute == '/notifications') currentIndex = 4;

    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onNavigate('/student_home');
            break;
          case 1:
            onNavigate('/routes');
            break;
          case 2:
            onNavigate('/map');
            break;
          case 3:
            onNavigate('/eta');
            break;
          case 4:
            onNavigate('/notifications');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.map), label: 'Rutas'),
        NavigationDestination(icon: Icon(Icons.explore), label: 'Mapa'),
        NavigationDestination(icon: Icon(Icons.timer), label: 'ETA'),
        NavigationDestination(icon: Icon(Icons.notifications), label: 'Alertas'),
      ],
    );
  }
}
