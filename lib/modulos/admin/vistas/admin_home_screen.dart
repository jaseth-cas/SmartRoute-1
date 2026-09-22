import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/admin_bottom_bar.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart'; // IMPORTANTE AÑADIR ESTO

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isLoading = true;
  int _activeRoutes = 0;
  int _activeStops = 0;
  int _activeBuses = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await MockData.loadRoutes();
    await MockData.loadStops();
    setState(() {
      _activeRoutes = MockData.routes.where((r) => r.status == 'Activa').length;
      _activeStops = MockData.stops.length;
      _activeBuses = MockData.buses.length;
      _isLoading = false;
    });
  }

  void _refreshDashboard() {
    setState(() {
      _activeRoutes = MockData.routes.where((r) => r.status == 'Activa').length;
      _activeStops = MockData.stops.length;
      _activeBuses = MockData.buses.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return PopScope(
      canPop: false, // Igual que en estudiante, previene salir de la app con 'atrás'
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Quitamos la flecha de atrás para consistencia
          title: Row(
            children: [
              Image.asset('assets/images/logo2.png', width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'SmartRoute',
                style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: SmartColors.smartRed),
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
            ),
            IconButton(
              icon: const Badge(
                child: Icon(Icons.notifications_none, color: SmartColors.smartText),
              ),
              onPressed: () {
                // Notificaciones
              },
            ),
          ],
        ),
        bottomNavigationBar: AdminBottomBar(
          currentRoute: '/admin_home',
          onNavigate: (route) => context.go(route),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: SmartColors.smartLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: SmartColors.smartBlue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${session?.name ?? "Admin"} 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: SmartColors.smartText,
                        ),
                      ),
                      const Text(
                        'Aquí tienes un resumen general del sistema.',
                        style: TextStyle(fontSize: 12, color: SmartColors.smartGray),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.map,
                    value: _activeRoutes.toString(),
                    label: 'Rutas',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.place,
                    value: _activeStops.toString(),
                    label: 'Paradas',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.directions_bus,
                    value: _activeBuses.toString(),
                    label: 'Buses',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Torre de Control (En vivo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SmartColors.smartLightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: SmartColors.smartGreen),
                      SizedBox(width: 4),
                      Text('En línea', style: TextStyle(fontSize: 10, color: SmartColors.smartGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SmartColors.smartBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Imagen del mapa de fondo
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/img.png', // Usamos el mismo mapa que el estudiante
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Capa oscura para que resalte el texto
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    // Pines de buses simulados (Torre de control)
                    const Positioned(
                      top: 40,
                      left: 60,
                      child: _AdminMapMarker(busCode: 'BUS-01', color: SmartColors.smartGreen),
                    ),
                    const Positioned(
                      bottom: 50,
                      right: 80,
                      child: _AdminMapMarker(busCode: 'BUS-02', color: SmartColors.smartBlue),
                    ),
                    const Positioned(
                      top: 80,
                      right: 40,
                      child: _AdminMapMarker(busCode: 'BUS-03', color: Colors.orange),
                    ),
                    // Overlay inferior
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.satellite_alt, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '$_activeBuses autobuses reportando',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: SmartColors.smartBlue, borderRadius: BorderRadius.circular(4)),
                              child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAssignStopsBottomSheet(context),
              icon: const Icon(Icons.share_location),
              label: const Text('Asignar paradas a rutas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ), // Cierra SingleChildScrollView
      ), // Cierra Scaffold
    );   // Cierra PopScope
  }

  void _showAssignStopsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final activeRoutes = MockData.routes.where((r) => r.status == 'Activa').toList();
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Seleccionar Ruta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
              const SizedBox(height: 8),
              const Text('Elige la ruta a la que deseas asignarle paradas.', style: TextStyle(color: SmartColors.smartGray)),
              const SizedBox(height: 16),
              if (activeRoutes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay rutas activas disponibles.', textAlign: TextAlign.center, style: TextStyle(color: SmartColors.smartGray)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeRoutes.length,
                    separatorBuilder: (_, __) => const Divider(color: SmartColors.smartBorder),
                    itemBuilder: (context, index) {
                      final route = activeRoutes[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: SmartColors.smartLightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.map, color: SmartColors.smartBlue, size: 20),
                        ),
                        title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(route.code, style: const TextStyle(color: SmartColors.smartGray)),
                        trailing: const Icon(Icons.chevron_right, color: SmartColors.smartGray),
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          context.push('/assign_stops/${route.code}');
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _AdminMetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SmartColors.smartLightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SmartColors.smartBlue, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: SmartColors.smartText)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AdminMapMarker extends StatelessWidget {
  final String busCode;
  final Color color;

  const _AdminMapMarker({required this.busCode, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.directions_bus, color: color, size: 16),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(busCode, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
