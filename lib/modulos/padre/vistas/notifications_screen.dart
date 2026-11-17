import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/incident_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/notification_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
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
  bool _isLoading = true;
  String? _busCode;
  List<NotificationMock> _notifications = [];
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadNotifications();
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
      final session = context.read<SessionManager>().currentSession;
      final role = session?.role ?? UserRole.student;
      final studentService = context.read<StudentService>();
      final busService = context.read<BusService>();
      final incidentService = context.read<IncidentService>();
      final userId = SupabaseConfig.client.auth.currentUser?.id ?? session?.userId;

      if (_busCode == null && userId != null && userId.isNotEmpty) {
        if (role == UserRole.driver) {
          final bus = await busService.getBusByDriver(userId);
          _busCode = bus?.code;
        } else if (role == UserRole.student) {
          final student = await studentService.getPrimaryStudent(userId);
          _busCode = student?.busCode;
        }
      }

      final realNotifs = await incidentService.getNotifications(
        busCode: (_busCode != null && _busCode!.isNotEmpty) ? _busCode : null,
      );

      if (mounted) {
        setState(() {
          _notifications = realNotifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRealtimeNotifications() {
    try {
      final incidentService = context.read<IncidentService>();
      _notifSub = incidentService.streamNotifications(busCode: _busCode).listen((notifs) {
        if (mounted) {
          setState(() {
            _notifications = (_busCode != null && _busCode!.isNotEmpty)
                ? notifs
                : notifs;
          });
        }
      });
    } catch (e) {
      debugPrint('Aviso suscripción notificaciones: $e');
    }
  }

  String _homeRouteForRole(UserRole role) {
    return switch (role) {
      UserRole.driver => '/driver_home',
      UserRole.owner => '/owner_home',
      UserRole.student => '/student_home',
    };
  }

  @override
  Widget build(BuildContext context) {
    final displayNotifications = _notifications;
    final role = context.watch<SessionManager>().currentSession?.role ?? UserRole.student;
    final fallbackHome = _homeRouteForRole(role);
    final appBarTitle = switch (role) {
      UserRole.driver => 'ALERTAS // CABINA CONDUCTOR',
      UserRole.owner => 'ALERTAS // FLOTA TRANSPORTISTA',
      UserRole.student => 'ALERTAS // BANDEJA DE ENTRADA',
    };

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(fallbackHome);
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Text(
            appBarTitle,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: SmartColors.deepBlack,
            ),
            overflow: TextOverflow.ellipsis,
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
                    context.go(fallbackHome);
                  }
                },
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  tooltip: 'Marcar todas como leídas',
                  icon: const Icon(Icons.done_all_rounded, color: SmartColors.deepBlue, size: 18),
                  onPressed: () async {
                    final incidentService = context.read<IncidentService>();
                    await incidentService.markAllAsRead(busCode: _busCode);
                    await _loadNotifications(silent: true);
                    if (!mounted) return;
                    setState(() {
                      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
                    });
                  },
                ),
              ),
            ),
            if (role == UserRole.student)
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
        bottomNavigationBar: role == UserRole.driver
            ? DriverBottomBar(
                currentRoute: '/driver_home',
                onNavigate: (route) => context.go(route),
              )
            : role == UserRole.student
                ? StudentBottomBar(
                    currentRoute: '/notifications',
                    onNavigate: (route) => context.go(route),
                  )
                : null,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: SmartColors.deepBlue))
                    : displayNotifications.isEmpty
                        ? const EmptyState(
                            message: 'Sin notificaciones',
                            subMessage:
                                'No hay alertas ni avisos registrados aún para tu unidad.',
                            icon: Icons.notifications_none_rounded,
                          )
                        : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: displayNotifications.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (index == displayNotifications.length) {
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
                          final notif = displayNotifications[index];
                          return NotificationCard(
                            notification: notif,
                            actionLabel: "VER",
                            onAction: () async {
                              if (!notif.read) {
                                await context.read<IncidentService>().markAsRead(notif.id);
                                if (!mounted) return;
                                setState(() {
                                  if (index < _notifications.length) {
                                    _notifications[index] = notif.copyWith(read: true);
                                  }
                                });
                              }
                              if (!context.mounted) return;
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
