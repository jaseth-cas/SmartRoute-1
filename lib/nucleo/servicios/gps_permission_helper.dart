import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Helper centralizado para verificar permisos de ubicación y activación de GPS
/// en los 3 módulos (Padre/Estudiante, Conductor y Transportista) post-login.
class GpsPermissionHelper {
  GpsPermissionHelper._();

  static bool _isDialogOpen = false;

  /// Verifica permisos y estado del GPS del dispositivo.
  /// Si están denegados o el GPS está apagado, muestra un diálogo interactivo con
  /// detección automática de regreso (`AppLifecycleState.resumed`).
  static Future<bool> ensureLocationReady(
    BuildContext context, {
    bool showPromptIfDisabled = true,
  }) async {
    if (_isDialogOpen || !context.mounted) return false;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if ((permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) &&
          showPromptIfDisabled &&
          context.mounted) {
        await _showLocationRequirementDialog(
          context,
          isPermissionIssue: true,
          isPermanentDenial: permission == LocationPermission.deniedForever,
        );
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && showPromptIfDisabled && context.mounted) {
        await _showLocationRequirementDialog(
          context,
          isPermissionIssue: false,
          isPermanentDenial: false,
        );
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      return serviceEnabled;
    } catch (e) {
      debugPrint('Aviso verificando estado GPS: $e');
      return false;
    }
  }

  static Future<void> _showLocationRequirementDialog(
    BuildContext context, {
    required bool isPermissionIssue,
    required bool isPermanentDenial,
  }) async {
    if (_isDialogOpen || !context.mounted) return;
    _isDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _GpsActivationDialog(
          isPermissionIssue: isPermissionIssue,
          isPermanentDenial: isPermanentDenial,
        ),
      );
    } finally {
      _isDialogOpen = false;
    }
  }
}

class _GpsActivationDialog extends StatefulWidget {
  final bool isPermissionIssue;
  final bool isPermanentDenial;

  const _GpsActivationDialog({
    required this.isPermissionIssue,
    required this.isPermanentDenial,
  });

  @override
  State<_GpsActivationDialog> createState() => _GpsActivationDialogState();
}

class _GpsActivationDialogState extends State<_GpsActivationDialog>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAndAutoClose();
    }
  }

  Future<void> _recheckAndAutoClose() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final perm = await Geolocator.checkPermission();
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (mounted && granted && enabled) {
        Navigator.of(context).pop();
        return;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (widget.isPermissionIssue) {
      if (widget.isPermanentDenial) {
        await Geolocator.openAppSettings();
      } else {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        } else {
          await _recheckAndAutoClose();
        }
      }
    } else {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPermissionIssue
        ? 'PERMISO DE UBICACIÓN REQUERIDO'
        : 'GPS DEL DISPOSITIVO APAGADO';
    final description = widget.isPermissionIssue
        ? (widget.isPermanentDenial
            ? 'SmartRoute necesita acceso a tu ubicación para rastrear rutas escolares y capturar domicilios con precisión. Habilítalo en Ajustes de la aplicación.'
            : 'Concede acceso a tu ubicación GPS para activar el rastreo satelital en tiempo real y el cálculo de rutas.')
        : 'El GPS de tu teléfono está desactivado. Actívalo para capturar ubicaciones exactas y sincronizar la telemetría del autobús.';
    final buttonText = widget.isPermissionIssue
        ? (widget.isPermanentDenial ? 'ABRIR AJUSTES' : 'CONCEDER PERMISO')
        : 'ACTIVAR GPS';

    return AlertDialog(
      backgroundColor: SmartColors.neuSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SmartColors.vibrantCyan.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isPermissionIssue
                  ? Icons.location_searching_rounded
                  : Icons.gps_off_rounded,
              color: SmartColors.deepBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: SmartColors.deepBlack,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: SmartColors.deepPetrol,
              height: 1.4,
            ),
          ),
          if (_checking) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: SmartColors.vibrantCyan,
              backgroundColor: SmartColors.smartLightBlue,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'MÁS TARDE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SmartColors.smartGray,
            ),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: SmartColors.deepBlack,
            foregroundColor: SmartColors.vibrantCyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _handlePrimaryAction,
          icon: const Icon(Icons.gps_fixed_rounded, size: 16),
          label: Text(
            buttonText,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
