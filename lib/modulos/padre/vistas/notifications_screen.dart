import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/notification_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLocalNotifications();
  }

  Future<void> _loadLocalNotifications() async {
    await MockData.loadNotifications();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Text(
            'ALERTAS // BANDEJA DE ENTRADA',
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
                    context.go('/student_home');
                  }
                },
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: SmartColors.deepBlue, size: 18),
                  onPressed: () => context.push('/notification_settings'),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/notifications',
          onNavigate: (route) => context.go(route),
        ),
        body: ResponsiveContent(
          maxWidth: 880,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: NeumorphicBox(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CANAL DE ALERTAS PUSH',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.5,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        Text(
                          notificationsEnabled ? 'Recibiendo eventos en vivo' : 'Canal en pausa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: SmartColors.smartGray,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (value) => setState(() => notificationsEnabled = value),
                      activeThumbColor: SmartColors.vibrantCyan,
                      activeTrackColor: SmartColors.deepBlack,
                    ),
                  ],
                ),
              ),
            ),
            if (!notificationsEnabled)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: InfoBanner(
                  text: 'Has pausado las alertas. No recibirás avisos de proximidad ni abordaje.',
                  isWarning: true,
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                itemCount: MockData.notifications.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == MockData.notifications.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 14.0, bottom: 32.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: SmartColors.neuInset,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'FIN DEL HISTORIAL DE EVENTOS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: SmartColors.smartGray,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final notif = MockData.notifications[index];
                  return NotificationCard(
                    notification: notif,
                    actionLabel: "VER",
                    onAction: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Evento verificado: ${notif.title}'),
                          backgroundColor: SmartColors.deepBlue,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
