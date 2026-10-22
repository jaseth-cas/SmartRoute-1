import 'package:flutter/material.dart';

class DriverBottomBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const DriverBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    if (currentRoute == '/driver_home') currentIndex = 0;
    if (currentRoute == '/driver_demand') currentIndex = 1;
    if (currentRoute == '/report_incident') currentIndex = 2;

    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onNavigate('/driver_home');
            break;
          case 1:
            onNavigate('/driver_demand');
            break;
          case 2:
            onNavigate('/report_incident');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.people_alt), label: 'Pasajeros'),
        NavigationDestination(icon: Icon(Icons.report_problem), label: 'Reportar'),
      ],
    );
  }
}
