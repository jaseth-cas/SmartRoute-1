import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final financialSummary = MockData.getFleetFinancialSummary();

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: ResponsiveContent.wide(
          maxWidth: 1180,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra superior Quivox Minimalista
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeumorphicBox(
                    isPill: true,
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/role_home');
                      }
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: SmartColors.deepBlack,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'FLEET DISPATCH HUB',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.deepPetrol,
                        ),
                      ),
                      Text(
                        'Panel Transportista',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                    ],
                  ),
                  NeumorphicBox(
                    isPill: true,
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push('/notifications'),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: SmartColors.deepBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tarjeta Perfil Empresa Neumórfica
              NeumorphicBox(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    NeumorphicBox(
                      isPill: true,
                      isDark: true,
                      padding: const EdgeInsets.all(14),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: SmartColors.electricCyan,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPERADOR DE FLOTA',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: SmartColors.deepPetrol,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session?.name ?? "Transportes Gómez",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: SmartColors.deepBlack,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: SmartColors.electricCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Flota Certificada SmartRoute',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SmartColors.deepPetrol,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ResponsiveTwoColumns(
                breakpoint: 880,
                spacing: 24,
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Métricas de Negocio Quivox Style (Ocupación y Recaudación)
                    Text(
                      'MÉTRICAS DE OPERACIÓN',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepPetrol,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: NeumorphicBox(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CAPACIDAD',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: SmartColors.deepPetrol,
                                      ),
                                    ),
                                    NeumorphicBox(
                                      isPill: true,
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.event_seat_rounded,
                                        size: 14,
                                        color: SmartColors.electricCyan,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${financialSummary.occupiedSeats}/${financialSummary.totalSeats}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${financialSummary.occupancyRate.toStringAsFixed(0)}% ocupación activa',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: SmartColors.deepPetrol.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: NeumorphicBox(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'INGRESOS',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: SmartColors.deepPetrol,
                                      ),
                                    ),
                                    NeumorphicBox(
                                      isPill: true,
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.payments_rounded,
                                        size: 14,
                                        color: SmartColors.primaryCrimson,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${financialSummary.totalRevenue.toInt()}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${financialSummary.pendingPaymentsCount} pendiente de cobro',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: SmartColors.deepPetrol.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Botones de Acción Quivox Cápsula
                    PrimaryButton(
                      text: 'REGISTRAR NUEVO AUTOBÚS',
                      icon: Icons.add_rounded,
                      isDark: true,
                      onPressed: () => context.push('/register_bus'),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'MONITOREO GPS EN VIVO',
                      icon: Icons.map_rounded,
                      isCyan: true,
                      onPressed: () {
                        TransitLoadingScreen.open(
                          context,
                          targetRoute: '/owner_map',
                          title: 'MAPA DE FLOTA ESCOLAR',
                          subtitle: 'Sincronizando telemetría y geocercas con la unidad TBX-492...',
                          badge: 'RADAR DE FLOTA GPS',
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Control de Cobros Neumórfico
                    Text(
                      'CONTROL DE CUOTAS Y MENSUALIDADES',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepPetrol,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeumorphicBox(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: MockData.passengers.take(3).map((p) {
                          final isPaid = p.paymentStatus == 'Al día';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: SmartColors.deepBlack,
                                      ),
                                    ),
                                    Text(
                                      'Tutor: ${p.parentName}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: SmartColors.deepPetrol.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                                NeumorphicBox(
                                  isPill: true,
                                  isDark: isPaid,
                                  isCrimson: !isPaid,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    p.paymentStatus.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                right: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lista de Unidades Escolares
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UNIDADES EN SERVICIO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepPetrol,
                          ),
                        ),
                        Text(
                          '${MockData.buses.length} ACTIVAS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepPetrol.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: MockData.buses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _OwnerBusItemImproved(bus: MockData.buses[index]);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Historial Reciente de Recorridos Quivox
                    Text(
                      'BITÁCORA DE RECORRIDOS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepPetrol,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeumorphicBox(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: const [
                          _HistoryRow(text: 'BUS-01 completó recorrido matutino Colegio San José'),
                          SizedBox(height: 10),
                          _HistoryRow(text: 'BUS-02 disponible en base para jornada de la tarde'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botón Cerrar Sesión Carmesí Quivox centrado
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: PrimaryButton(
                    text: 'CERRAR SESIÓN',
                    icon: Icons.logout_rounded,
                    isCrimson: true,
                    onPressed: () {
                      sessionManager.logout();
                      context.go('/login');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
          backgroundColor: SmartColors.neuSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'ASIGNAR CONDUCTOR',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: SmartColors.deepBlack,
              letterSpacing: 1.0,
            ),
          ),
          content: Text(
            'Selecciona un conductor disponible para asignar a la unidad ${widget.bus.code}.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: SmartColors.deepPetrol,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.jetBrainsMono(
                  color: SmartColors.deepPetrol,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.deepBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  currentDriver = "Nuevo Conductor (Asignado)";
                });
                Navigator.pop(context);
              },
              child: Text(
                'CONFIRMAR',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
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
          backgroundColor: SmartColors.neuSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'EDITAR AUTOBÚS',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: SmartColors.deepBlack,
              letterSpacing: 1.0,
            ),
          ),
          content: Text(
            'Modifica la placa, el modelo o la capacidad de asientos de la unidad ${widget.bus.code}.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: SmartColors.deepPetrol,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.jetBrainsMono(
                  color: SmartColors.deepPetrol,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.deepBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'GUARDAR',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline =
        widget.bus.status.contains('recorrido') || widget.bus.status == 'Disponible';

    return NeumorphicBox(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicBox(
                isPill: true,
                isDark: true,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: SmartColors.electricCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.bus.code,
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        NeumorphicBox(
                          isPill: true,
                          isDark: isOnline,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            widget.bus.status.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isOnline ? SmartColors.electricCyan : SmartColors.deepPetrol,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'PLACA',
                            value: widget.bus.plate,
                          ),
                        ),
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'CONDUCTOR',
                            value: currentDriver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'CUPOS',
                            value: '${widget.bus.seatsOccupied}/${widget.bus.capacity}',
                          ),
                        ),
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'COLEGIO',
                            value: widget.bus.schoolName ?? 'No asignado',
                          ),
                        ),
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
                child: NeumorphicBox(
                  isPill: true,
                  onTap: _showEditDialog,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'EDITAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeumorphicBox(
                  isPill: true,
                  isDark: true,
                  onTap: _showAssignDialog,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'ASIGNAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: SmartColors.electricCyan,
                      ),
                    ),
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
  final String label;
  final String value;

  const _OwnerDetailCol({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: SmartColors.deepPetrol.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SmartColors.deepBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            color: SmartColors.electricCyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SmartColors.deepBlack,
            ),
          ),
        ),
      ],
    );
  }
}
