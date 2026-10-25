import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Diálogo interactivo del Sello de Confianza y Seguridad (Trust & Safety)
/// Implementa RF-03 y RNF-12: Auditoría documental del transportista
/// (Antecedentes judiciales, Licencia C2, Seguro escolar y Revisión RTM).
class TrustSafetyDialog extends StatefulWidget {
  final BusMock bus;
  final bool isOwnerView;
  final VoidCallback? onStatusChanged;

  const TrustSafetyDialog({
    super.key,
    required this.bus,
    this.isOwnerView = false,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required BusMock bus,
    bool isOwnerView = false,
    VoidCallback? onStatusChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TrustSafetyDialog(
        bus: bus,
        isOwnerView: isOwnerView,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<TrustSafetyDialog> createState() => _TrustSafetyDialogState();
}

class _TrustSafetyDialogState extends State<TrustSafetyDialog> {
  late bool _isVerified;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.bus.isVerified;
  }

  Future<void> _toggleCertification() async {
    setState(() => _isSaving = true);
    final busService = context.read<BusService>();
    final newStatus = !_isVerified;

    try {
      await busService.updateBusVerification(
        busCode: widget.bus.code,
        isVerified: newStatus,
      );

      if (mounted) {
        setState(() {
          _isVerified = newStatus;
          _isSaving = false;
        });
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus ? SmartColors.smartGreen : SmartColors.smartRed,
            content: Text(
              newStatus
                  ? 'Sello de Confianza activado para unidad ${widget.bus.code}'
                  : 'Certificación suspendida para unidad ${widget.bus.code}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SmartColors.smartRed,
            content: Text('Error al actualizar certificación: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con escudo y distintivo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? SmartColors.smartLightGreen
                          : SmartColors.smartLightRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVerified ? Icons.verified_user : Icons.gpp_bad_outlined,
                      color: _isVerified ? SmartColors.smartGreen : SmartColors.smartRed,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'SmartRoute',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: SmartColors.smartBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isVerified
                                    ? SmartColors.smartLightGreen
                                    : SmartColors.smartLightRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isVerified ? 'CERTIFICADO' : 'PENDIENTE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _isVerified ? SmartColors.smartGreen : SmartColors.smartRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sello de Confianza Escolar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SmartColors.smartText,
                          ),
                        ),
                        Text(
                          'Auditoría y Validación Documental (RNF-12)',
                          style: TextStyle(fontSize: 11, color: SmartColors.smartGray),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: SmartColors.smartGray, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjeta de la Unidad y Conductor
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SmartColors.smartBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SmartColors.smartBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_bus, color: SmartColors.smartBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unidad: ${widget.bus.code} • ${widget.bus.plate}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartColors.smartText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Conductor asignado: ${widget.bus.driverName}',
                            style: const TextStyle(fontSize: 12, color: SmartColors.smartGray),
                          ),
                          Text(
                            'Modelo: ${widget.bus.model} (${widget.bus.capacity} cupos)',
                            style: const TextStyle(fontSize: 11, color: SmartColors.smartGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Lista de Documentos Obligatorios Auditados
              const Text(
                'Documentación Legal y Técnica Auditada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartColors.smartText),
              ),
              const SizedBox(height: 12),

              _DocumentCheckItem(
                title: 'Récord Policivo y Antecedentes Penales',
                subtitle: 'Certificado Nacional de Policía #POL-89422. Sin anotaciones penales ni medidas correctivas.',
                statusText: 'Limpio y Aprobado',
                isValid: true,
                icon: Icons.shield_outlined,
              ),
              const SizedBox(height: 10),
              _DocumentCheckItem(
                title: 'Licencia Comercial de Conducción',
                subtitle: 'Categoría C2 habilitada para servicio escolar. Vigente hasta 28/05/2028.',
                statusText: 'Vigente',
                isValid: true,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 10),
              _DocumentCheckItem(
                title: 'Póliza de Seguros Todo Riesgo Escolar',
                subtitle: 'Cobertura médica y civil contractual/extracontractual para pasajeros menores.',
                statusText: 'Póliza Activa',
                isValid: true,
                icon: Icons.health_and_safety_outlined,
              ),
              const SizedBox(height: 10),
              _DocumentCheckItem(
                title: 'Revisión Técnico-Mecánica (RTM)',
                subtitle: 'Inspección aprobada por CDA acreditado. Vigencia semestral reglamentaria.',
                statusText: 'RTM al Día',
                isValid: true,
                icon: Icons.car_repair_outlined,
              ),
              const SizedBox(height: 20),

              // Mensaje de Garantía Trust & Safety
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SmartColors.smartLightGreen.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartColors.smartGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_clock_outlined, color: SmartColors.smartGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los datos son verificados periódicamente por la administración del transportista escolar y auditados por el sistema SmartRoute.',
                        style: TextStyle(fontSize: 11, color: SmartColors.smartGreen, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción según el rol
              if (widget.isOwnerView) ...[
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _toggleCertification,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isVerified ? Icons.remove_moderator : Icons.verified),
                  label: Text(
                    _isVerified
                        ? 'Suspender Sello de Confianza'
                        : 'Aprobar y Emitir Sello Trust & Safety',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerified ? SmartColors.smartRed : SmartColors.smartGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SmartColors.smartGray,
                  side: const BorderSide(color: SmartColors.smartBorder),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCheckItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusText;
  final bool isValid;
  final IconData icon;

  const _DocumentCheckItem({
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.isValid,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SmartColors.smartBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isValid ? SmartColors.smartLightGreen : SmartColors.smartLightYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isValid ? SmartColors.smartGreen : SmartColors.smartYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SmartColors.smartText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isValid ? SmartColors.smartLightGreen : SmartColors.smartLightYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isValid ? Icons.check_circle : Icons.warning_amber,
                            color: isValid ? SmartColors.smartGreen : SmartColors.smartYellow,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isValid ? SmartColors.smartGreen : SmartColors.smartYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: SmartColors.smartGray, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
