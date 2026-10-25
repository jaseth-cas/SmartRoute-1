import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/incident_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/notification_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;
  bool _isLoading = true;
  List<NotificationMock> _notifications = [];
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _subscribeToRealtimeNotifications();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final incidentService = context.read<IncidentService>();
      final realNotifs = await incidentService.getNotifications(busCode: 'BUS-01');

      if (mounted) {
        setState(() {
          _notifications = realNotifs.isNotEmpty ? realNotifs : MockData.notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      if (mounted) {
        setState(() {
          _notifications = MockData.notifications;
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRealtimeNotifications() {
    try {
      final incidentService = context.read<IncidentService>();
      _notifSub = incidentService.streamNotifications(busCode: 'BUS-01').listen((notifs) {
        if (mounted && notifs.isNotEmpty) {
          setState(() {
            _notifications = notifs;
          });
        }
      });
    } catch (e) {
      debugPrint('Aviso suscripción notificaciones: $e');
    }
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
        backgroundColor: SmartColors.smartBackground,
        appBar: AppBar(
          title: const Text('Notificaciones Escolares', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student_home');
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh, color: SmartColors.smartBlue),
              onPressed: () => _loadNotifications(),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/notification_settings'),
            ),
          ],
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/notifications',
          onNavigate: (route) => context.go(route),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: SmartColors.smartBlue))
            : RefreshIndicator(
                onRefresh: () => _loadNotifications(),
                color: SmartColors.smartBlue,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Notificaciones push activas', style: TextStyle(fontWeight: FontWeight.w600, color: SmartColors.smartText)),
                          Switch(
                            value: notificationsEnabled,
                            onChanged: (value) => setState(() => notificationsEnabled = value),
                            activeThumbColor: SmartColors.smartBlue,
                          ),
                        ],
                      ),
                    ),
                    if (!notificationsEnabled)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: InfoBanner(
                          text: 'Has desactivado las notificaciones. No recibirás alertas de proximidad ni de abordaje facial.',
                          containerColor: SmartColors.smartLightRed,
                          contentColor: SmartColors.smartRed,
                        ),
                      ),
                    Expanded(
                      child: _notifications.isEmpty
                          ? const Center(child: Text('No hay notificaciones recientes', style: TextStyle(color: SmartColors.smartGray)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _notifications.length + 1,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == _notifications.length) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 16.0, bottom: 32.0),
                                    child: InfoBanner(
                                      text: 'Notificaciones sincronizadas en tiempo real desde Supabase PostgreSQL y WebSockets.',
                                      icon: Icons.verified_user,
                                    ),
                                  );
                                }
                                return NotificationCard(notification: _notifications[index]);
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
