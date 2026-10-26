import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/neumorphic_box.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/responsive_layout.dart';
import '../../../nucleo/servicios/bus_service.dart';

class RegisterBusScreen extends StatefulWidget {
  const RegisterBusScreen({super.key});

  @override
  State<RegisterBusScreen> createState() => _RegisterBusScreenState();
}

class _RegisterBusScreenState extends State<RegisterBusScreen> {
  final _formKey = GlobalKey<FormState>();

  String code = "";
  String plate = "";
  String model = "";
  int capacity = 24;
  String school = "Colegio San José";
  bool _isLoading = false;

  final TextEditingController _capacityController = TextEditingController(text: "24");

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveBus() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final busService = context.read<BusService>();
        final newBus = await busService.registerBus(
          code: code,
          plate: plate,
          model: model,
          capacity: capacity,
          schoolName: school.isNotEmpty ? school : 'Colegio San José',
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
                    'Autobús ${newBus.code} registrado correctamente en PostgreSQL',
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
          context.pop(true);
        } else {
          context.go('/owner_home');
        }
      } catch (e) {
        if (!mounted) return;
        final errorMsg = e.toString().contains('23505') || e.toString().contains('unique')
            ? 'Ya existe una unidad con ese código o placa en el sistema.'
            : 'Error al registrar unidad: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
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
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/owner_home');
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
                          'FLEET MANAGEMENT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepPetrol,
                          ),
                        ),
                        Text(
                          'Registrar Autobús',
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

                // Tarjeta informativa Quivox
                NeumorphicBox(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      NeumorphicBox(
                        isPill: true,
                        isDark: true,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          color: SmartColors.electricCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUEVA UNIDAD ESCOLAR',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: SmartColors.deepPetrol,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ingresa los datos técnicos del vehículo para habilitar la telemetría satelital y el despacho.',
                              style: GoogleFonts.plusJakartaSans(
                                color: SmartColors.deepPetrol.withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Código de Autobús Inset
                CustomTextField(
                  label: 'CÓDIGO DE IDENTIFICACIÓN',
                  hint: 'Ej. BUS-03',
                  prefixIcon: Icons.tag_rounded,
                  onChanged: (value) => code = value,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El código es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Placa del vehículo Inset
                CustomTextField(
                  label: 'PLACA DE RODAJE',
                  hint: 'Ej. SJ-884210',
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (value) => plate = value,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'La placa es obligatoria';
                    }
                    if (val.length < 5) return 'Placa inválida';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Modelo del vehículo Inset
                CustomTextField(
                  label: 'MARCA Y MODELO',
                  hint: 'Ej. Mercedes-Benz Sprinter 516',
                  prefixIcon: Icons.directions_car_rounded,
                  onChanged: (value) => model = value,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El modelo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Control de Capacidad Quivox Style (Selector [ - ] [ + ] y chips)
                Text(
                  'CAPACIDAD DE PASAJEROS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: SmartColors.deepPetrol,
                  ),
                ),
                const SizedBox(height: 10),
                NeumorphicBox(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$capacity ASIENTOS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: SmartColors.deepBlack,
                            ),
                          ),
                          Text(
                            'Cupo máximo autorizado',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: SmartColors.deepPetrol.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          NeumorphicBox(
                            isPill: true,
                            padding: const EdgeInsets.all(10),
                            onTap: () {
                              if (capacity > 5) {
                                setState(() {
                                  capacity -= 1;
                                  _capacityController.text = capacity.toString();
                                });
                              }
                            },
                            child: const Icon(
                              Icons.remove_rounded,
                              size: 18,
                              color: SmartColors.deepBlack,
                            ),
                          ),
                          const SizedBox(width: 12),
                          NeumorphicBox(
                            isPill: true,
                            isDark: true,
                            padding: const EdgeInsets.all(10),
                            onTap: () {
                              if (capacity < 60) {
                                setState(() {
                                  capacity += 1;
                                  _capacityController.text = capacity.toString();
                                });
                              }
                            },
                            child: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: SmartColors.electricCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Guardar Cápsula Quivox
                PrimaryButton(
                  text: _isLoading ? 'REGISTRANDO EN BASE DE DATOS...' : 'REGISTRAR AUTOBÚS EN FLOTA',
                  icon: _isLoading ? null : Icons.check_circle_outline_rounded,
                  isDark: true,
                  enabled: !_isLoading,
                  onPressed: _saveBus,
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
