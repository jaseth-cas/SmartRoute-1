import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List<BusMock> _buses = [];
  List<StudentPassengerMock> _passengers = [];
  FleetFinancialSummary _financialSummary = const FleetFinancialSummary(
    totalSeats: 36,
    occupiedSeats: 32,
    totalRevenue: 2080.0,
    pendingRevenue: 65.0,
    pendingPaymentsCount: 1,
    totalStudents: 5,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    setState(() => _isLoading = true);
    final busService = context.read<BusService>();
    final studentService = context.read<StudentService>();

    try {
      final busesFuture = busService.getAllBuses();
      final summaryFuture = studentService.getFleetFinancialSummary();
      final studentsFuture = studentService.getAllStudents();

      final results = await Future.wait([busesFuture, summaryFuture, studentsFuture]);

      if (mounted) {
        setState(() {
          _buses = results[0] as List<BusMock>;
          _financialSummary = results[1] as FleetFinancialSummary;
          _passengers = results[2] as List<StudentPassengerMock>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos de flota en OwnerHomeScreen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRegisterBus() async {
    final result = await context.push<bool>('/register_bus');
    if (result == true) {
      await _loadFleetData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text(
          'SmartRoute Transportista',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: SmartColors.smartBlue),
        ),
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
            icon: const Icon(Icons.refresh, color: SmartColors.smartBlue),
            tooltip: 'Recargar datos',
            onPressed: _loadFleetData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: SmartColors.smartGray),
            onPressed: () {
              // Alerts
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFleetData,
        color: SmartColors.smartBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: LinearProgressIndicator(
                    backgroundColor: SmartColors.smartLightBlue,
                    color: SmartColors.smartBlue,
                  ),
                ),

              // Perfil
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: SmartColors.smartLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business_center, color: SmartColors.smartBlue, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Panel de Dueño de Flota', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text(
                          session?.name ?? "Transportes Gómez (Escolar)",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SmartColors.smartBlue, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sello Trust & Safety de la Empresa
              InkWell(
                onTap: () {
                  if (_buses.isNotEmpty) {
                    TrustSafetyDialog.show(
                      context,
                      bus: _buses.first,
                      isOwnerView: true,
                      onStatusChanged: _loadFleetData,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: SmartRouteCard(
                  color: SmartColors.smartLightGreen.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: SmartColors.smartGreen, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Flota Certificada SmartRoute (Trust & Safety)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartGreen)),
                            Text('Toca para auditar antecedentes, licencias y RTM de conductores.', style: TextStyle(fontSize: 10, color: SmartColors.smartText)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: SmartColors.smartGreen, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- MÉTRICAS DE NEGOCIO (SAAS / MARKETPLACE DE TRANSPORTISTAS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rendimiento del Negocio (En Vivo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SmartColors.smartText)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: SmartColors.smartLightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: SmartColors.smartGreen, size: 8),
                        SizedBox(width: 4),
                        Text('PostgreSQL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SmartColors.smartGreen)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _BusinessMetricCard(
                    title: 'Ocupación de Cupos',
                    value: '${_financialSummary.occupiedSeats}/${_financialSummary.totalSeats}',
                    subtitle: '${_financialSummary.occupancyRate.toStringAsFixed(0)}% Asientos ocupados',
                    icon: Icons.event_seat,
                    color: SmartColors.smartBlue,
                    bgColor: SmartColors.smartLightBlue,
                  ),
                  const SizedBox(width: 12),
                  _BusinessMetricCard(
                    title: 'Recaudación Mes',
                    value: '\$${_financialSummary.totalRevenue.toInt()}',
                    subtitle: '${_financialSummary.pendingPaymentsCount} Cobro en mora',
                    icon: Icons.monetization_on,
                    color: SmartColors.smartGreen,
                    bgColor: SmartColors.smartLightGreen,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botones de acción
              ElevatedButton.icon(
                onPressed: _navigateToRegisterBus,
                icon: const Icon(Icons.add),
                label: const Text('Registrar nuevo autobús escolar', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartColors.smartBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => context.push('/owner_map'),
                icon: const Icon(Icons.map),
                label: const Text('Monitoreo GPS de flota en vivo', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartColors.smartDarkBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Mis Autobuses Escolares
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mis Unidades Escolares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SmartColors.smartText)),
                  Text('${_buses.length} unidades', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              if (_buses.isEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SmartColors.smartBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.directions_bus_outlined, size: 40, color: SmartColors.smartGray),
                        SizedBox(height: 8),
                        Text('No hay autobuses registrados aún', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartText)),
                        SizedBox(height: 4),
                        Text('Registra tu primer autobús escolar para comenzar.', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _buses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _OwnerBusItemImproved(
                      bus: _buses[index],
                      onUpdated: _loadFleetData,
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Resumen de Cobro a Padres (Marketplace / SaaS)
              const Text('Control de Cobros de Mensualidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              SmartRouteCard(
                child: Column(
                  children: [
                    if (_passengers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('No hay pasajeros matriculados actualmente', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                      )
                    else
                      ..._passengers.take(5).map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Tutor: ${p.parentName} (${p.busCode})', style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                              ],
                            ),
                            Row(
                              children: [
                                Text('\$${p.monthlyFee.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: p.paymentStatus == 'Al día' ? SmartColors.smartLightGreen : SmartColors.smartLightRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.paymentStatus,
                                    style: TextStyle(
                                      color: p.paymentStatus == 'Al día' ? SmartColors.smartGreen : SmartColors.smartRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Historial de recorridos
              const Text('Historial reciente de recorridos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          _HistoryRow(text: 'BUS-01 completó recorrido hacia Colegio San José'),
                          SizedBox(height: 4),
                          _HistoryRow(text: 'BUS-02 disponible para jornada de la tarde'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cerrar sesión
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
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BusinessMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SmartColors.smartBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: SmartColors.smartGray), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _OwnerBusItemImproved extends StatefulWidget {
  final BusMock bus;
  final VoidCallback? onUpdated;

  const _OwnerBusItemImproved({required this.bus, this.onUpdated});

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
          content: Text('Modifica la placa, el modelo o la capacidad de asientos de la unidad ${widget.bus.code}.'),
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
                        Expanded(child: _OwnerDetailCol(icon: Icons.event_seat, label: 'Cupos:', value: '${widget.bus.seatsOccupied}/${widget.bus.capacity}')),
                        Expanded(child: _OwnerDetailCol(icon: Icons.school, label: 'Colegio:', value: widget.bus.schoolName ?? 'No asignado')),
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
                child: OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Editar', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SmartColors.smartBlue,
                    side: const BorderSide(color: SmartColors.smartBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    TrustSafetyDialog.show(
                      context,
                      bus: widget.bus,
                      isOwnerView: true,
                      onStatusChanged: widget.onUpdated,
                    );
                  },
                  icon: Icon(
                    widget.bus.isVerified ? Icons.verified : Icons.gpp_maybe,
                    size: 14,
                    color: widget.bus.isVerified ? SmartColors.smartGreen : SmartColors.smartYellow,
                  ),
                  label: Text(
                    widget.bus.isVerified ? 'Sello OK' : 'Auditar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.bus.isVerified ? SmartColors.smartGreen : SmartColors.smartYellow,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.bus.isVerified ? SmartColors.smartGreen : SmartColors.smartYellow,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAssignDialog,
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Conductor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  const _OwnerDetailCol({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SmartColors.smartGray, size: 12),
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
