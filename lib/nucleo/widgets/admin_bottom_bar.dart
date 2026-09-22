import 'package:flutter/material.dart';

class AdminBottomBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AdminBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    if (currentRoute == '/admin_home') currentIndex = 0;
    if (currentRoute == '/manage_routes') currentIndex = 1;
    if (currentRoute == '/manage_stops') currentIndex = 2;
    if (currentRoute == '/manage_buses') currentIndex = 3;

    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onNavigate('/admin_home');
            break;
          case 1:
            onNavigate('/manage_routes');
            break;
          case 2:
            onNavigate('/manage_stops');
            break;
          case 3:
            onNavigate('/manage_buses');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.map), label: 'Rutas'),
        NavigationDestination(icon: Icon(Icons.place), label: 'Paradas'),
        NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Buses'),
      ],
    );
  }
}
