import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/datos/mock_data.dart';
import '../../../nucleo/modelos/models.dart';
import '../../../nucleo/widgets/neumorphic_box.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/servicios/incident_service.dart';
import '../../../nucleo/widgets/driver_bottom_bar.dart';
import '../../../nucleo/widgets/responsive_layout.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = "";
  String description = "";
  String incidentType = "Mecánico";
  bool _isLoading = false;

  final List<String> incidentTypes = [
    "Mecánico",
    "Tráfico",
    "Accidente",
    "Pasajero",
    "Otro"
  ];

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final newNotification = NotificationMock(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        message: '[$incidentType] $description',
        time: 'Justo ahora',
        read: false,
        type: (incidentType == 'Mecánico' || incidentType == 'Accidente')
            ? 'alert'
            : 'info',
      );

      await MockData.addNotification(newNotification);

      try {
        final incidentService = context.read<IncidentService>();
        await incidentService.reportIncident(
          busCode: 'BUS-01',
          title: title,
          description: description,
          incidentType: incidentType,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SmartColors.deepBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: SmartColors.electricCyan, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Incidente registrado y notificado en tiempo real a los padres',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/driver_home');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reportar incidente: $e'),
            backgroundColor: SmartColors.smartRed,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/report_incident',
        onNavigate: (route) => context.go(route),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 680,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: SingleChildScrollView(
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar Minimalista Quivox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicBox(
                      isPill: true,
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'INCIDENT LOG',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepPetrol,
                          ),
                        ),
                        Text(
                          'Reportar Incidente',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 24),

                // Banner de Alerta Neumórfico Crimson
                NeumorphicBox(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeumorphicBox(
                        isPill: true,
                        isCrimson: true,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIORIDAD ALTA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: SmartColors.primaryCrimson,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Este formulario genera un despacho inmediato a la central y notifica en tiempo real a los tutores involucrados en la ruta.',
                              style: GoogleFonts.plusJakartaSans(
                                color: SmartColors.deepPetrol.withValues(alpha: 0.85),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Selector de Tipo de Incidente Quivox Capsule
                Text(
                  'TIPO DE INCIDENCIA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: SmartColors.deepPetrol,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: incidentTypes.map((type) {
                      final isSelected = incidentType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: NeumorphicBox(
                          isPill: true,
                          isDark: isSelected,
                          onTap: () {
                            setState(() {
                              incidentType = type;
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              if (isSelected) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: SmartColors.electricCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                type.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isSelected
                                      ? Colors.white
                                      : SmartColors.deepBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Título del Reporte Inset
                CustomTextField(
                  label: 'TÍTULO DEL REPORTE',
                  hint: 'Ej. Falla mecánica en neumático',
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (val) => val == null || val.isEmpty
                      ? 'El título es obligatorio'
                      : null,
                  onChanged: (val) => title = val,
                ),
                const SizedBox(height: 20),

                // Descripción Detallada Hundida Inset Neumórfica
                Text(
                  'DESCRIPCIÓN DETALLADA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: SmartColors.deepPetrol,
                  ),
                ),
                const SizedBox(height: 8),
                NeumorphicBox(
                  isInset: true,
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextFormField(
                    maxLines: 4,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: SmartColors.deepBlack,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (val) => description = val,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Brinda más detalles' : null,
                    decoration: InputDecoration(
                      hintText: 'Detalla ubicación, gravedad y acciones tomadas...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: SmartColors.deepPetrol.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Quivox Cápsula Crimson
                PrimaryButton(
                  text: _isLoading ? 'ENVIANDO ALERTA...' : 'ENVIAR REPORTE CRÍTICO',
                  icon: _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  isCrimson: true,
                  enabled: !_isLoading,
                  onPressed: _submitReport,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
