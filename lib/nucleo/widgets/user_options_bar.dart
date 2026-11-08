import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Barra de opciones unificada para el panel lateral superior derecho:
/// - Botón 1: Ícono de usuario neumórfico que despliega un menú contextual con:
///   * Perfil
///   * Estado
///   * Cerrar sesión (con confirmación)
/// - Botón 2: Notificaciones con badge rojo de alertas activas
class UserAppBarActions extends StatelessWidget {
  final bool showNotificationBell;
  final VoidCallback? onNotificationTap;
  final double? buttonSize;
  final bool noTrailingPadding;

  const UserAppBarActions({
    super.key,
    this.showNotificationBell = true,
    this.onNotificationTap,
    this.buttonSize,
    this.noTrailingPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final role = session?.role ?? UserRole.student;

    String roleLabel = 'Estudiante / Tutor';
    String statusTitle = 'A bordo • BUS-01';
    Color statusColor = SmartColors.smartGreen;

    if (role == UserRole.driver) {
      roleLabel = 'Conductor de Ruta';
      statusTitle = 'En servicio • GPS Activo';
      statusColor = SmartColors.vibrantCyan;
    } else if (role == UserRole.owner) {
      roleLabel = 'Transportista / Flota';
      statusTitle = 'Flota activa • 2 unidades';
      statusColor = SmartColors.electricCyan;
    }

    final effectiveSize = buttonSize ?? 42.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón 1: Usuario con Menú Desplegable (Perfil, Estado, Cerrar sesión)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: NeumorphicBox(
              padding: EdgeInsets.zero,
              isPill: true,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 19,
                tooltip: 'Menú de usuario',
                offset: const Offset(0, 48),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: SmartColors.deepBlue,
                  size: 19,
                ),
                onSelected: (value) {
                if (value == 'perfil') {
                  _handleProfileClick(context, role, sessionManager);
                } else if (value == 'estado') {
                  _handleStatusClick(context, role, sessionManager, statusTitle, statusColor);
                } else if (value == 'logout') {
                  _handleLogoutClick(context, sessionManager);
                }
              },
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                // Cabecera con datos del usuario activo
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, color: SmartColors.deepBlue, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sessionManager.currentUserName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: SmartColors.deepBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              roleLabel.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.5,
                                color: SmartColors.smartGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),

                // Opción 1: Perfil
                PopupMenuItem<String>(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_circle_outlined, size: 18, color: SmartColors.deepBlue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Perfil',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                    ],
                  ),
                ),

                // Opción 2: Estado
                PopupMenuItem<String>(
                  value: 'estado',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.radar_rounded, size: 18, color: statusColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Estado',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SmartColors.deepBlack,
                              ),
                            ),
                            Text(
                              statusTitle,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(height: 1),

                // Opción 3: Cerrar sesión
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: SmartColors.primaryCrimson.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, size: 18, color: SmartColors.primaryCrimson),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cerrar sesión',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.primaryCrimson,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

        // Botón 2: Notificaciones (con badge rojo)
        if (showNotificationBell)
          Padding(
            padding: EdgeInsets.only(right: noTrailingPadding ? 0.0 : 14.0),
            child: SizedBox(
              width: effectiveSize,
              height: effectiveSize,
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 19,
                  icon: const Badge(
                    backgroundColor: SmartColors.primaryCrimson,
                    child: Icon(Icons.notifications_none_rounded, color: SmartColors.deepBlack, size: 19),
                  ),
                  onPressed: onNotificationTap ?? () => context.go('/notifications'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleProfileClick(BuildContext context, UserRole role, SessionManager sessionManager) {
    if (role == UserRole.student) {
      context.push('/student_profile');
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmartColors.deepBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: SmartColors.deepBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perfil de Usuario',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sessionManager.currentUserName,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: SmartColors.deepBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role == UserRole.driver
                    ? 'Conductor Asignado • Unidad BUS-01 (TBX-492)'
                    : 'Transportista Titular • Flota Gómez',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: SmartColors.smartGray),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SmartColors.neuInset,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rol Activo:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SmartColors.smartGray)),
                        Text(role.name.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Enlace Seguro:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SmartColors.smartGray)),
                        Text('JWT ACTIVO // 4G', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CERRAR', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, color: SmartColors.deepBlue)),
            ),
          ],
        ),
      );
    }
  }

  void _handleStatusClick(
    BuildContext context,
    UserRole role,
    SessionManager sessionManager,
    String statusTitle,
    Color statusColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Estado Operativo',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              role == UserRole.student
                  ? 'El estudiante se encuentra debidamente verificado por reconocimiento facial biométrico y la unidad escolar está en camino.'
                  : role == UserRole.driver
                      ? 'La telemetría GPS se encuentra sincronizada con la nube de SmartRoute a 42 km/h con 8 estudiantes a bordo.'
                      : 'Todas las unidades de la flota se encuentran operativas con geocercas y despacho activo.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ENTENDIDO', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, color: SmartColors.deepBlue)),
          ),
        ],
      ),
    );
  }

  void _handleLogoutClick(BuildContext context, SessionManager sessionManager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SmartColors.primaryCrimson.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: SmartColors.primaryCrimson, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir del perfil actual en SmartRoute?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, color: SmartColors.smartGray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SmartColors.primaryCrimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              sessionManager.logout();
              context.go('/login');
            },
            child: Text(
              'CERRAR SESIÓN',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

