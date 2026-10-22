import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  void _toggleAbsence(StudentPassengerMock student) {
    final bool willBeAbsent = student.status != PassengerStatus.absent;

    if (willBeAbsent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¿Reportar Inasistencia?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Se notificará inmediatamente al conductor del ${student.busCode}. '
            'El sistema recalculará la ruta escolar para omitir la parada de recogida en tu domicilio y ahorrar tiempo de recorrido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: SmartColors.smartGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                MockData.reportAbsence(student.id, true);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ausencia registrada. Ruta del transportista optimizada.'),
                    backgroundColor: SmartColors.smartRed,
                  ),
                );
              },
              child: const Text('Confirmar Ausencia'),
            ),
          ],
        ),
      );
    } else {
      MockData.reportAbsence(student.id, false);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha reactivado la recogida escolar de hoy.'),
          backgroundColor: SmartColors.smartGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = MockData.getDefaultStudentRoute();
    final defaultStop = MockData.getDefaultStudentStop();
    final student = MockData.getPrimaryStudent();
    final isAbsent = student.status == PassengerStatus.absent;
    final isOnboard = student.status == PassengerStatus.onboard;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/images/logo2.png', width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'SmartRoute Escolar',
                style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: SmartColors.smartBlue),
              onPressed: () => context.push('/student_profile'),
            ),
            IconButton(
              icon: const Badge(
                child: Icon(Icons.notifications_none, color: SmartColors.smartText),
              ),
              onPressed: () => context.go('/notifications'),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/student_home',
          onNavigate: (route) => context.go(route),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del Padre / Tutor
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: SmartColors.smartLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.family_restroom, color: SmartColors.smartBlue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${session?.name ?? "Carlos Gómez"} 👋',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: SmartColors.smartText,
                          ),
                        ),
                        Text(
                          'Tutor de ${student.name} • ${student.schoolName}',
                          style: const TextStyle(fontSize: 12, color: SmartColors.smartGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- KILLER FEATURE: TARJETA DE SEGURIDAD Y ABORDAJE BIOMÉTRICO (AI BOARDING) ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAbsent
                        ? [Colors.grey.shade100, Colors.grey.shade200]
                        : isOnboard
                            ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isAbsent
                        ? Colors.grey.shade400
                        : isOnboard
                            ? SmartColors.smartGreen
                            : SmartColors.smartBlue,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAbsent
                                ? Colors.grey.shade300
                                : isOnboard
                                    ? SmartColors.smartGreen
                                    : SmartColors.smartBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAbsent
                                ? Icons.person_off
                                : isOnboard
                                    ? Icons.face_retouching_natural
                                    : Icons.directions_bus,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAbsent
                                    ? 'Ausencia Notificada'
                                    : isOnboard
                                        ? '¡Estudiante a Bordo!'
                                        : 'En Espera de Recogida',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isAbsent
                                      ? Colors.grey.shade800
                                      : isOnboard
                                          ? const Color(0xFF065F46)
                                          : SmartColors.smartBlue,
                                ),
                              ),
                              Text(
                                isAbsent
                                    ? 'El bus escolar omitirá tu parada hoy'
                                    : isOnboard
                                        ? 'Abordaje verificado a las ${student.lastBoardingTime ?? "07:14 AM"}'
                                        : 'El bus escolar se aproxima a tu domicilio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAbsent
                                      ? Colors.grey.shade600
                                      : isOnboard
                                          ? const Color(0xFF047857)
                                          : SmartColors.smartDarkBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: SmartColors.smartGreen, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isOnboard ? 'Prueba facial validada (Edge AI)' : 'Sello de Confianza SmartRoute',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartColors.smartText),
                            ),
                          ],
                        ),
                        Text(
                          student.busCode,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: SmartColors.smartBlue, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- BOTÓN KILLER FEATURE: REPORTAR AUSENCIA (GESTIÓN DE CUPOS / AHORRO DE RUTA) ---
              SmartRouteCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAbsent ? SmartColors.smartLightRed : SmartColors.smartLightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAbsent ? Icons.event_busy : Icons.event_available,
                        color: isAbsent ? SmartColors.smartRed : SmartColors.smartBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAbsent ? '¿Mateo sí asistirá hoy?' : '¿Tu hijo no asistirá hoy?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isAbsent ? 'Presiona para reactivar la recogida.' : 'Avisa al chofer y optimiza su trayecto.',
                            style: const TextStyle(fontSize: 11, color: SmartColors.smartGray),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAbsent ? SmartColors.smartGreen : SmartColors.smartRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _toggleAbsence(student),
                      child: Text(
                        isAbsent ? 'Reactivar' : 'No Asiste',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- FINANZAS / ESTADO DE MENSUALIDAD ESCOLAR (SAAS / MARKETPLACE) ---
              SmartRouteCard(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.credit_card, color: SmartColors.smartBlue, size: 20),
                            SizedBox(width: 8),
                            Text('Suscripción y Cupo Escolar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Cupo Activo', style: TextStyle(color: SmartColors.smartGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mensualidad de Octubre:', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text('\$${student.monthlyFee.toInt()} COP', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estado de pago:', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text(student.paymentStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartGreen)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- ESTIMACIÓN DE LLEGADA (ETA) ---
              const SectionTitle(text: 'Tiempo Estimado del Bus Escolar'),
              GestureDetector(
                onTap: () {
                  if (defaultRoute != null) {
                    context.push('/route_detail/${defaultRoute.code}');
                  }
                },
                child: SmartRouteCard(
                  color: const Color(0xFFF0F7FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            defaultRoute?.name ?? 'Ruta Escolar Norte',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SmartColors.smartText),
                          ),
                          const Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isAbsent ? '0' : '${defaultRoute?.etaMinutes ?? 5}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: isAbsent ? Colors.grey : SmartColors.smartBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MIN',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isAbsent ? Colors.grey : SmartColors.smartGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recogida: ${student.pickupAddress}', style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                          StatusChip(text: isAbsent ? 'Omitido' : 'En camino'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- MAPA EN VIVO DEL BUS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SectionTitle(text: 'Rastreo en Vivo del Bus'),
                  Text('Ver en mapa', style: TextStyle(fontSize: 12, color: SmartColors.smartBlue, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (defaultRoute != null && defaultStop != null) {
                    context.push('/map/${defaultRoute.code}/${defaultStop.stopCode}');
                  }
                },
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SmartColors.smartBorder),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 36, color: SmartColors.smartBlue),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: SmartColors.smartBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Abrir Mapa en Tiempo Real', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const InfoBanner(text: 'SmartRoute: Transporte Escolar Seguro con Reconocimiento Facial y Monitoreo de Ruta.'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
