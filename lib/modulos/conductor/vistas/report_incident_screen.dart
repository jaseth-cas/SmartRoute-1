import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/servicios/incident_service.dart';
import '../../../nucleo/widgets/driver_bottom_bar.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = "";
  String description = "";
  String incidentType = "Mecánico"; // Valor por defecto
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
          const SnackBar(
            content: Text('Incidente registrado y notificado en tiempo real a los padres'),
            backgroundColor: SmartColors.smartGreen,
          ),
        );
        context.pop();
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
      backgroundColor: SmartColors.smartBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/report_incident',
        onNavigate: (route) => context.go(route),
      ),
      appBar: AppBar(
        title: const Text('Reportar Incidente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SmartColors.smartLightRed,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartColors.smartRed.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: SmartColors.smartRed, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Usa este formulario para reportar retrasos o problemas. Se enviará una alerta al administrador de forma inmediata.',
                        style: TextStyle(color: SmartColors.smartRed.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Tipo de incidente', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: incidentType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: SmartColors.smartSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SmartColors.smartBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SmartColors.smartBorder),
                  ),
                ),
                items: incidentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    incidentType = val!;
                  });
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Título del reporte',
                hint: 'Ej. Llanta ponchada en la vía',
                prefixIcon: Icons.title,
                validator: (val) => val == null || val.isEmpty ? 'El título es obligatorio' : null,
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 16),

              const Text('Descripción detallada', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 4,
                onChanged: (val) => description = val,
                validator: (val) => val == null || val.isEmpty ? 'Brinda más detalles' : null,
                decoration: InputDecoration(
                  hintText: 'Describe lo que pasó...',
                  hintStyle: const TextStyle(color: SmartColors.smartGray),
                  filled: true,
                  fillColor: SmartColors.smartSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SmartColors.smartBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SmartColors.smartBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SmartColors.smartBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                text: _isLoading ? 'Enviando alerta...' : 'Enviar Reporte',
                icon: _isLoading ? null : Icons.send,
                enabled: !_isLoading,
                backgroundColor: SmartColors.smartYellow,
                foregroundColor: Colors.white,
                onPressed: _submitReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
