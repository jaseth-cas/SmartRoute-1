import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('SmartRoute Transportista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: SmartColors.smartBlue)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role_home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: SmartColors.smartGray),
            onPressed: () {
              // Alerts
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: SmartColors.smartBlue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¡Bienvenido!', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                      Text(
                        session?.name ?? "Transportista",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SmartColors.smartBlue, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SmartRouteCard(
              color: SmartColors.smartLightBlue.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: SmartColors.smartBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Rol actual: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('OWNER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
                          ],
                        ),
                        Text('JWT simulado: ${sessionManager.currentToken ?? "N/A"}', style: const TextStyle(fontSize: 10, color: SmartColors.smartGray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/register_bus'),
              icon: const Icon(Icons.add),
              label: const Text('Registrar nuevo autobús', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/owner_map'),
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa de flota', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartDarkBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Mis Autobuses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SmartColors.smartText)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: MockData.buses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _OwnerBusItemImproved(bus: MockData.buses[index]);
              },
            ),
            const SizedBox(height: 24),
            const Text('Historial básico de recorridos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            SmartRouteCard(
              child: Row(
                children: [
                  const Icon(Icons.history, color: SmartColors.smartGray, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _HistoryRow(text: 'BUS-01 completó recorrido Universidad - Centro'),
                        SizedBox(height: 4),
                        _HistoryRow(text: 'BUS-02 disponible para asignación'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OwnerBusItemImproved extends StatefulWidget {
  final BusMock bus;

  const _OwnerBusItemImproved({required this.bus});

  @override
  State<_OwnerBusItemImproved> createState() => _OwnerBusItemImprovedState();
}

class _OwnerBusItemImprovedState extends State<_OwnerBusItemImproved> {
  late String currentDriver;

  @override
  void initState() {
    super.initState();
    currentDriver = widget.bus.driverName;
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Asignar Conductor', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Selecciona un conductor de tu nómina disponible para asignar a la unidad ${widget.bus.code}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: SmartColors.smartGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: SmartColors.smartBlue, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  currentDriver = "Nuevo Conductor (Asignado)";
                });
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Editar Autobús', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Modifica la placa, el modelo o el estado general de la unidad ${widget.bus.code}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: SmartColors.smartGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: SmartColors.smartBlue, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.bus.status.contains('recorrido') || widget.bus.status == 'Disponible';

    return SmartRouteCard(
      child: Column(
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
                child: const Icon(Icons.directions_bus, color: SmartColors.smartBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.bus.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SmartColors.smartText)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOnline ? SmartColors.smartLightGreen : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.bus.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? SmartColors.smartGreen : SmartColors.smartGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _OwnerDetailCol(icon: Icons.badge, label: 'Placa:', value: widget.bus.plate)),
                        Expanded(child: _OwnerDetailCol(icon: Icons.person, label: 'Conductor:', value: currentDriver)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: _OwnerDetailCol(icon: Icons.fiber_manual_record, label: 'Estado:', value: widget.bus.status, iconColor: widget.bus.status == 'Disponible' ? SmartColors.smartBlue : SmartColors.smartGreen)),
                        Expanded(child: _OwnerDetailCol(icon: Icons.alt_route, label: 'Ruta:', value: widget.bus.routeName ?? 'No asignada')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SmartColors.smartBlue,
                    side: const BorderSide(color: SmartColors.smartBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: _showAssignDialog,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Asignar conductor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartColors.smartLightBlue,
                    foregroundColor: SmartColors.smartBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerDetailCol extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _OwnerDetailCol({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = SmartColors.smartGray,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: SmartColors.smartText), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String text;

  const _HistoryRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: SmartColors.smartBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: SmartColors.smartText))),
      ],
    );
  }
}
