import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool notificationsEnabled = true;
  String proximityMinutes = "5";
  bool notifyStart = true;
  bool notifyEnd = false;
  bool notifyGps = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'CONFIG // PREFERENCIAS DE ALERTA',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: SmartColors.deepBlack,
          ),
        ),
        backgroundColor: SmartColors.neuBackground,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeumorphicBox(
            padding: EdgeInsets.zero,
            isPill: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: SmartColors.deepBlack),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/notifications');
                }
              },
            ),
          ),
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 680,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SectionTitle(text: 'Canal Principal', subtext: 'SERVICIO PUSH'),
            NeumorphicBox(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              borderRadius: BorderRadius.circular(22),
              child: _SettingSwitchRow(
                label: 'ALERTAS GENERALES',
                sublabel: 'Recepción de telemetría y eventos del autobús',
                checked: notificationsEnabled,
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),
            ),
            const SizedBox(height: 22),

            SectionTitle(text: 'Radio de Proximidad', subtext: 'ANTELACIÓN DE LLEGADA'),
            NeumorphicBox(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disparar alarma cuando el bus esté a:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: SmartColors.smartGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Segmented Pills Quivox
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: SmartColors.neuInset,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _MinuteOption(label: '3 MIN', isSelected: proximityMinutes == "3", onTap: () => setState(() => proximityMinutes = "3"))),
                        Expanded(child: _MinuteOption(label: '5 MIN', isSelected: proximityMinutes == "5", onTap: () => setState(() => proximityMinutes = "5"))),
                        Expanded(child: _MinuteOption(label: '10 MIN', isSelected: proximityMinutes == "10", onTap: () => setState(() => proximityMinutes = "10"))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SectionTitle(text: 'Eventos de Telemetría', subtext: 'DISPARADORES'),
            NeumorphicBox(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _SettingSwitchRow(
                    label: 'INICIO DE RECORRIDO',
                    sublabel: 'Aviso cuando el bus enciende motor y sale',
                    checked: notifyStart,
                    onChanged: (val) => setState(() => notifyStart = val),
                  ),
                  const Divider(height: 1),
                  _SettingSwitchRow(
                    label: 'LLEGADA AL COLEGIO',
                    sublabel: 'Confirmación cuando el bus llega al destino',
                    checked: notifyEnd,
                    onChanged: (val) => setState(() => notifyEnd = val),
                  ),
                  const Divider(height: 1),
                  _SettingSwitchRow(
                    label: 'TRAFICO PESADO // DESVÍOS',
                    sublabel: 'Alertas en caso de contingencia o retraso',
                    checked: notifyGps,
                    onChanged: (val) => setState(() => notifyGps = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            PrimaryButton(
              text: 'GUARDAR AJUSTES DE ALERTA',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferencias de notificación guardadas.'),
                    backgroundColor: SmartColors.deepBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            const InfoBanner(
              text: 'Las alertas operan en background sincronizadas con el GPS del bus escolar.',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    ),
  );
}
}

class _SettingSwitchRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchRow({
    required this.label,
    required this.sublabel,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: SmartColors.deepBlack,
                  ),
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: SmartColors.smartGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: checked,
            onChanged: onChanged,
            activeThumbColor: SmartColors.vibrantCyan,
            activeTrackColor: SmartColors.deepBlack,
          ),
        ],
      ),
    );
  }
}

class _MinuteOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MinuteOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SmartColors.deepBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SmartColors.deepBlack.withValues(alpha: 0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isSelected ? SmartColors.ghostWhite : SmartColors.deepBlue,
          ),
        ),
      ),
    );
  }
}
