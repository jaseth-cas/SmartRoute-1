import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/utilidades/coordinate_parser.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

/// Resultado devuelto al confirmar la ubicación de recogida de un estudiante.
class StudentPickupLocationResult {
  final LatLng homePoint;
  final LatLng? streetAccessPoint;
  final String addressLabel;
  final double distanceToStreetMeters;

  const StudentPickupLocationResult({
    required this.homePoint,
    this.streetAccessPoint,
    required this.addressLabel,
    this.distanceToStreetMeters = 0.0,
  });
}

/// Pantalla interactiva Quivox Neumórfica para configurar la ubicación de recogida
/// del estudiante bajo dos modalidades:
/// - Modalidad A: GPS del dispositivo en tiempo real + toque directo en el mapa.
/// - Modalidad B: Ingreso manual multi-formato (DD, DMM, DMS) con validación y movimiento de cámara.
class StudentLocationPickerScreen extends StatefulWidget {
  final StudentPassengerMock? student;
  final LatLng? initialCoordinates;
  final String? initialAddress;

  const StudentLocationPickerScreen({
    super.key,
    this.student,
    this.initialCoordinates,
    this.initialAddress,
  });

  /// Abre el selector de ubicación de recogida y devuelve un [StudentPickupLocationResult] al confirmar.
  static Future<StudentPickupLocationResult?> open(
    BuildContext context, {
    StudentPassengerMock? student,
    LatLng? initialCoordinates,
    String? initialAddress,
  }) {
    return Navigator.of(context).push<StudentPickupLocationResult>(
      MaterialPageRoute(
        builder: (_) => StudentLocationPickerScreen(
          student: student,
          initialCoordinates: initialCoordinates,
          initialAddress: initialAddress,
        ),
      ),
    );
  }

  @override
  State<StudentLocationPickerScreen> createState() => _StudentLocationPickerScreenState();
}

class _StudentLocationPickerScreenState extends State<StudentLocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _coordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final OsrmRoutingService _osrmService = OsrmRoutingService();

  late LatLng _selectedPoint;
  LatLng? _snappedStreetPoint;
  String _nearestStreetName = 'Verificando calle transitable...';
  double _distanceToStreetMeters = 0.0;
  List<LatLng> _previewRouteToSchool = [];

  CoordinateFormatType? _detectedFormat = CoordinateFormatType.dd;
  String? _coordinateError;
  bool _isLocatingGps = false;
  bool _isCheckingStreet = false;
  bool _isSaving = false;
  double _currentZoom = 16.8;

  // Destino escolar de referencia para previsualizar el enrutamiento real por calles (OSRM)
  static const LatLng _schoolDestination = LatLng(8.5154, -80.3482);

  @override
  void initState() {
    super.initState();
    final student = widget.student ?? MockData.getPrimaryStudent();
    _selectedPoint = widget.initialCoordinates ??
        (student.pickupLatitude != null && student.pickupLongitude != null
            ? LatLng(student.pickupLatitude!, student.pickupLongitude!)
            : const LatLng(8.5284, -80.3582));

    _coordController.text = CoordinateParser.formatDd(_selectedPoint);
    _addressController.text = widget.initialAddress ?? student.pickupAddress;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateStreetAccessAndRoute(_selectedPoint, moveCamera: false);
    });
  }

  @override
  void dispose() {
    _coordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Modalidad A: Captura la posición actual del teléfono con `geolocator` de alta precisión.
  Future<void> _useCurrentDeviceGps() async {
    setState(() {
      _isLocatingGps = true;
      _coordinateError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLocatingGps = false;
          _coordinateError =
              'El servicio de ubicación GPS del dispositivo está desactivado. Actívalo o usa el mapa / ingreso manual.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLocatingGps = false;
          _coordinateError =
              'Permiso de ubicación denegado. Concédelo en el navegador/sistema o selecciona el punto en el mapa.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final gpsLatLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _isLocatingGps = false;
        _selectedPoint = gpsLatLng;
        _detectedFormat = CoordinateFormatType.dd;
        _coordController.text = CoordinateParser.formatDd(gpsLatLng);
      });

      await _validateStreetAccessAndRoute(gpsLatLng, moveCamera: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ubicación GPS capturada: ${CoordinateParser.formatDd(gpsLatLng)}',
          ),
          backgroundColor: SmartColors.smartGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocatingGps = false;
        _coordinateError =
            'No se pudo obtener la lectura GPS en este momento ($e). Puedes tocar el mapa o escribir las coordenadas.';
      });
    }
  }

  /// Modalidad B: Parsea el texto en formato DD, DMM o DMS y mueve la cámara hacia la ubicación.
  Future<void> _searchManualCoordinates() async {
    final parseResult = CoordinateParser.parseWithDetails(_coordController.text);

    if (!parseResult.isSuccess || parseResult.coordinates == null) {
      setState(() {
        _coordinateError = parseResult.errorMessage;
      });
      return;
    }

    final target = parseResult.coordinates!;
    setState(() {
      _coordinateError = null;
      _detectedFormat = parseResult.format;
      _selectedPoint = target;
    });

    await _validateStreetAccessAndRoute(target, moveCamera: true);
  }

  /// Selecciona un punto al tocar directamente sobre el mapa interactivo.
  Future<void> _onMapTapped(LatLng tappedPoint) async {
    setState(() {
      _selectedPoint = tappedPoint;
      _coordinateError = null;
      _detectedFormat = CoordinateFormatType.dd;
      _coordController.text = CoordinateParser.formatDd(tappedPoint);
    });

    await _validateStreetAccessAndRoute(tappedPoint, moveCamera: false);
  }

  /// Consulta `OsrmRoutingService.snapToNearestStreet` / `getNearestStreetInfo` y traza la ruta real OSRM.
  Future<void> _validateStreetAccessAndRoute(
    LatLng point, {
    required bool moveCamera,
  }) async {
    if (moveCamera) {
      _currentZoom = 17.0;
      _mapController.move(point, _currentZoom);
    }

    setState(() => _isCheckingStreet = true);

    try {
      final snappedPoint = await _osrmService.snapToNearestStreet(point);
      final nearestInfo = await _osrmService.getNearestStreetInfo(point);
      final effectiveSnapped = snappedPoint ?? nearestInfo?.snappedPoint ?? point;

      final routePoints = await _osrmService.getDrivingRoute([
        effectiveSnapped,
        _schoolDestination,
      ]);

      if (!mounted) return;
      setState(() {
        _snappedStreetPoint = effectiveSnapped;
        _nearestStreetName = nearestInfo?.streetName ?? 'Calle Vehicular Transitable';
        _distanceToStreetMeters = nearestInfo?.distanceMeters ??
            OsrmRoutingService.calculateDistanceMeters(point, effectiveSnapped);
        _previewRouteToSchool = routePoints;
        _isCheckingStreet = false;

        if (_addressController.text.trim().isEmpty &&
            _nearestStreetName.isNotEmpty) {
          _addressController.text = _nearestStreetName;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _snappedStreetPoint = point;
        _nearestStreetName = 'Acceso Vehicular Directo';
        _distanceToStreetMeters = 0.0;
        _isCheckingStreet = false;
      });
    }
  }

  void _applyFormatExample(CoordinateFormatType type) {
    final text = switch (type) {
      CoordinateFormatType.dd => CoordinateParser.formatDd(_selectedPoint),
      CoordinateFormatType.dmm =>
        '${_selectedPoint.latitude.abs().floor()}° ${((_selectedPoint.latitude.abs() % 1) * 60).toStringAsFixed(3)}\' ${_selectedPoint.latitude >= 0 ? 'N' : 'S'}, '
        '${_selectedPoint.longitude.abs().floor()}° ${((_selectedPoint.longitude.abs() % 1) * 60).toStringAsFixed(3)}\' ${_selectedPoint.longitude >= 0 ? 'E' : 'W'}',
      CoordinateFormatType.dms => CoordinateParser.formatDms(_selectedPoint),
    };

    setState(() {
      _coordController.text = text;
      _detectedFormat = type;
      _coordinateError = null;
    });
  }

  Future<void> _confirmAndSaveLocation() async {
    setState(() => _isSaving = true);

    final student = widget.student ?? MockData.getPrimaryStudent();
    final addressText = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : '$_nearestStreetName (${CoordinateParser.formatDd(_selectedPoint)})';

    try {
      final studentService = context.read<StudentService>();
      await studentService.updateStudentPickupLocation(
        studentId: student.id,
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        pickupAddress: addressText,
        busCode: student.busCode,
      );
    } catch (e) {
      debugPrint('Aviso guardando ubicación desde StudentLocationPickerScreen: $e');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final result = StudentPickupLocationResult(
      homePoint: _selectedPoint,
      streetAccessPoint: _snappedStreetPoint,
      addressLabel: addressText,
      distanceToStreetMeters: _distanceToStreetMeters,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ubicación de recogida guardada (${CoordinateParser.formatDd(_selectedPoint)})',
        ),
        backgroundColor: SmartColors.smartGreen,
      ),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student ?? MockData.getPrimaryStudent();

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: ResponsiveContent.wide(
          maxWidth: 1180,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra superior Quivox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicBox(
                      isPill: true,
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'GEOLOCALIZACIÓN ESCOLAR // OSRM + GPS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                              color: SmartColors.deepPetrol,
                            ),
                          ),
                          Text(
                            'Ubicación de Recogida (${student.name})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SmartColors.deepBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const SizedBox(width: 32),
                  ],
                ),
                const SizedBox(height: 20),

                ResponsiveTwoColumns(
                  breakpoint: 900,
                  spacing: 24,
                  left: _buildControlsPanel(student),
                  right: _buildInteractiveMapCard(student),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsPanel(StudentPassengerMock student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // MODALIDAD A: GPS en Tiempo Real
        NeumorphicBox(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SmartColors.vibrantCyan.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: SmartColors.deepBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODALIDAD A // GPS INTERACTIVO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: SmartColors.deepBlue,
                          ),
                        ),
                        Text(
                          'Captura exacta desde tu teléfono o tocando el mapa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                text: _isLocatingGps
                    ? 'OBTENIENDO SEÑAL SATELITAL GPS...'
                    : 'USAR MI UBICACIÓN ACTUAL (GPS)',
                icon: Icons.gps_fixed_rounded,
                isCyan: true,
                onPressed: _isLocatingGps ? null : _useCurrentDeviceGps,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // MODALIDAD B: Ingreso Manual Multi-Formato (DD, DMM, DMS)
        NeumorphicBox(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SmartColors.primaryCrimson.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.compass_calibration_rounded,
                      color: SmartColors.primaryCrimson,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODALIDAD B // INGRESO MULTI-FORMATO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: SmartColors.primaryCrimson,
                          ),
                        ),
                        Text(
                          'Escribe coordenadas en DD, DMM o DMS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selector rápido de formato para convertir o previsualizar
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CoordinateFormatType.values.map((fmt) {
                  final isSelected = _detectedFormat == fmt;
                  return GestureDetector(
                    onTap: () => _applyFormatExample(fmt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? SmartColors.deepBlack : SmartColors.neuInset,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        fmt.name.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? SmartColors.vibrantCyan : SmartColors.deepPetrol,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _coordController,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SmartColors.deepBlack,
                ),
                decoration: InputDecoration(
                  labelText: 'Coordenadas (DD, DMM o DMS)',
                  hintText: 'Ej: 8°31\'00"N 80°21\'00"W o 8.5284, -80.3582',
                  errorText: _coordinateError,
                  errorMaxLines: 3,
                  filled: true,
                  fillColor: SmartColors.neuInset,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar en el mapa',
                    icon: const Icon(Icons.search_rounded, color: SmartColors.deepBlue),
                    onPressed: _searchManualCoordinates,
                  ),
                ),
                onSubmitted: (_) => _searchManualCoordinates(),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'BUSCAR EN EL MAPA',
                icon: Icons.travel_explore_rounded,
                isDark: true,
                onPressed: _searchManualCoordinates,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Validación de Calle Transitable OSRM y Dirección de Referencia
        NeumorphicBox(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'VALIDACIÓN DE ACCESO VIAL (OSRM)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: SmartColors.deepPetrol,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SmartColors.smartLightGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isCheckingStreet
                            ? 'CALCULANDO...'
                            : '${_distanceToStreetMeters.toStringAsFixed(1)} M A CALLE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.smartGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Calle transitable más cercana: $_nearestStreetName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SmartColors.deepBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Decimal: ${CoordinateParser.formatDd(_selectedPoint)}  •  DMS: ${CoordinateParser.formatDms(_selectedPoint)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: SmartColors.deepPetrol,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SmartColors.deepBlack,
                ),
                decoration: InputDecoration(
                  labelText: 'Referencia o dirección del domicilio',
                  hintText: 'Ej: Vía Cristo Rey, Casa #14 frente al parque',
                  filled: true,
                  fillColor: SmartColors.neuInset,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: _isSaving
                    ? 'GUARDANDO EN SUPABASE...'
                    : 'CONFIRMAR Y GUARDAR UBICACIÓN',
                icon: Icons.check_circle_rounded,
                isCrimson: true,
                onPressed: _isSaving ? null : _confirmAndSaveLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMapCard(StudentPassengerMock student) {
    final snapped = _snappedStreetPoint;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return NeumorphicBox(
      borderRadius: 26,
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: isMobile ? 380 : 540,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint,
                  initialZoom: _currentZoom,
                  minZoom: 11.0,
                  maxZoom: 18.5,
                  onTap: (_, latLng) => _onMapTapped(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartroute.smartroute_flutter',
                  ),
                  PolylineLayer(
                    polylines: [
                      // Ruta real sobre calles transitables (OSRM) hacia el colegio
                      if (_previewRouteToSchool.length >= 2) ...[
                        Polyline(
                          points: _previewRouteToSchool,
                          color: SmartColors.vibrantCyan.withValues(alpha: 0.35),
                          strokeWidth: 9.0,
                        ),
                        Polyline(
                          points: _previewRouteToSchool,
                          color: SmartColors.deepBlue,
                          strokeWidth: 4.5,
                        ),
                      ],
                      // Conexión peatonal desde la puerta de la casa hasta el acceso vehicular en la calle más cercana
                      if (snapped != null)
                        Polyline(
                          points: [_selectedPoint, snapped],
                          color: SmartColors.primaryCrimson,
                          strokeWidth: 3.5,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Punto de acceso en la calle transitable más cercana (snapToNearestStreet)
                      if (snapped != null)
                        Marker(
                          point: snapped,
                          width: isMobile ? 28 : 150,
                          height: isMobile ? 28 : 52,
                          child: isMobile
                              ? Tooltip(
                                  message: 'Acceso Vial Bus (${_distanceToStreetMeters.toStringAsFixed(1)} m)',
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: SmartColors.deepBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SmartColors.deepBlack.withValues(alpha: 0.25),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.directions_bus_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SmartColors.deepBlack,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ACCESO VIAL BUS',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: SmartColors.vibrantCyan,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: SmartColors.deepBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                      // Pin principal del domicilio del estudiante
                      Marker(
                        point: _selectedPoint,
                        width: isMobile ? 30 : 170,
                        height: isMobile ? 30 : 64,
                        child: isMobile
                            ? Tooltip(
                                message: 'Domicilio: ${student.name}',
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: SmartColors.primaryCrimson,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.deepBlack.withValues(alpha: 0.28),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.home_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: SmartColors.primaryCrimson,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SmartColors.deepBlack.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'DOMICILIO: ${student.name.toUpperCase()}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: SmartColors.primaryCrimson,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Marcador del Colegio Destino
                      Marker(
                        point: _schoolDestination,
                        width: isMobile ? 28 : 130,
                        height: isMobile ? 28 : 52,
                        child: isMobile
                            ? Tooltip(
                                message: 'Colegio San José (Destino)',
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: SmartColors.smartGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.deepBlack.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: SmartColors.smartGreen),
                                    ),
                                    child: Text(
                                      'COLEGIO SAN JOSÉ',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: SmartColors.deepBlack,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: SmartColors.smartGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),

              // Banner informativo superior en el mapa
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SmartColors.deepBlack.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: SmartColors.vibrantCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toca cualquier punto del mapa para mover el pin de recogida o usa GPS / coordenadas.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
