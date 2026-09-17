import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../components/smart_route_card.dart';
import '../components/section_title.dart';
import '../components/primary_button.dart';
import '../components/info_banner.dart';

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
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Configurar notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/notifications');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: 'General'),
            SmartRouteCard(
              child: _SettingSwitchRow(
                label: 'Activar notificaciones',
                checked: notificationsEnabled,
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(text: 'Alerta de proximidad'),
            SmartRouteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notificarme cuando el bus esté a:', style: TextStyle(fontSize: 14, color: SmartColors.smartGray)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _MinuteOption(label: '3 min', isSelected: proximityMinutes == "3", onTap: () => setState(() => proximityMinutes = "3"))),
                      const SizedBox(width: 8),
                      Expanded(child: _MinuteOption(label: '5 min', isSelected: proximityMinutes == "5", onTap: () => setState(() => proximityMinutes = "5"))),
                      const SizedBox(width: 8),
                      Expanded(child: _MinuteOption(label: '10 min', isSelected: proximityMinutes == "10", onTap: () => setState(() => proximityMinutes = "10"))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(text: 'Eventos de ruta'),
            SmartRouteCard(
              child: Column(
                children: [
                  _SettingSwitchRow(label: 'Al iniciar la ruta', checked: notifyStart, onChanged: (val) => setState(() => notifyStart = val)),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _SettingSwitchRow(label: 'Al finalizar la ruta', checked: notifyEnd, onChanged: (val) => setState(() => notifyEnd = val)),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _SettingSwitchRow(label: 'Actualizaciones GPS', checked: notifyGps, onChanged: (val) => setState(() => notifyGps = val)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Guardar configuración', onPressed: () { /* Visual save */ }),
            const SizedBox(height: 24),
            const InfoBanner(
              text: 'Configuración simulada. No se enviarán notificaciones reales a este dispositivo.',
              icon: Icons.info,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Switch(
          value: checked,
          onChanged: onChanged,
          activeThumbColor: SmartColors.smartBlue,
        ),
      ],
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? SmartColors.smartLightBlue : Colors.white,
        foregroundColor: isSelected ? SmartColors.smartBlue : SmartColors.smartGray,
        side: BorderSide(color: isSelected ? SmartColors.smartBlue : SmartColors.smartBorder),
        padding: const EdgeInsets.symmetric(vertical: 0),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // matching material 3 rounded look
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
    );
  }
}
