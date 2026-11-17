import 'package:latlong2/latlong.dart';

/// Formato detectado al parsear una cadena de coordenadas geográficas.
enum CoordinateFormatType {
  /// Grados Decimales (ej. `8.5167, -80.3500` o `8.5167 N, 80.3500 W`)
  dd('Grados Decimales (DD)'),

  /// Grados y Minutos Decimales (ej. `8° 31.000' N, 80° 21.000' W`)
  dmm('Grados y Minutos Decimales (DMM)'),

  /// Grados, Minutos y Segundos (ej. `8°31'00"N 80°21'00"W`)
  dms('Grados, Minutos y Segundos (DMS)');

  final String label;
  const CoordinateFormatType(this.label);
}

/// Resultado estructurado del análisis de coordenadas manuales.
class CoordinateParseResult {
  final LatLng? coordinates;
  final CoordinateFormatType? format;
  final String? errorMessage;

  const CoordinateParseResult.success({
    required LatLng this.coordinates,
    required CoordinateFormatType this.format,
  }) : errorMessage = null;

  const CoordinateParseResult.failure(String this.errorMessage)
      : coordinates = null,
        format = null;

  bool get isSuccess => coordinates != null && errorMessage == null;
}

/// Parser y validador multi-formato de coordenadas geográficas (DD, DMM y DMS).
class CoordinateParser {
  /// Analiza una cadena de texto en formato DD, DMM o DMS y retorna un [CoordinateParseResult].
  static CoordinateParseResult parseWithDetails(String? rawInput) {
    if (rawInput == null || rawInput.trim().isEmpty) {
      return const CoordinateParseResult.failure(
        'Ingresa las coordenadas del domicilio (ej. 8.5284, -80.3582 o 8°31\'00"N 80°21\'00"W).',
      );
    }

    final normalized = _normalizeSymbols(rawInput.trim());

    // 1. Intentar formato DMS: Grados, Minutos y Segundos
    // Ejemplos: 8°31'00"N 80°21'00"W | 8° 31' 15.4" N, 80° 21' 08.2" O
    final dmsResult = _tryParseDms(normalized);
    if (dmsResult != null) {
      return dmsResult;
    }

    // 2. Intentar formato DMM: Grados y Minutos Decimales
    // Ejemplos: 8° 31.000' N, 80° 21.000' W | 8°31.5'N 80°21.2'O
    final dmmResult = _tryParseDmm(normalized);
    if (dmmResult != null) {
      return dmmResult;
    }

    // 3. Intentar formato DD: Grados Decimales
    // Ejemplos: 8.5167, -80.3500 | 8.5167 N, 80.3500 W | 8.5167 -80.3500
    final ddResult = _tryParseDd(normalized);
    if (ddResult != null) {
      return ddResult;
    }

    return const CoordinateParseResult.failure(
      'Formato de coordenadas no reconocido. Usa DD (8.5167, -80.3500), '
      'DMM (8° 31.000\' N, 80° 21.000\' W) o DMS (8°31\'00"N 80°21\'00"W).',
    );
  }

  /// Retorna directamente el [LatLng] decimal si la entrada es válida, o `null` si falla.
  static LatLng? parse(String? rawInput) {
    return parseWithDetails(rawInput).coordinates;
  }

  /// Validador directo para `TextFormField`. Retorna `null` si es válido o el mensaje en español.
  static String? validate(String? rawInput) {
    final result = parseWithDetails(rawInput);
    return result.isSuccess ? null : result.errorMessage;
  }

  /// Normaliza comillas tipográficas y símbolos equivalentes para facilitar el parseo.
  static String _normalizeSymbols(String input) {
    return input
        .replaceAll('º', '°')
        .replaceAll('˚', '°')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('′', "'")
        .replaceAll('´', "'")
        .replaceAll('”', '"')
        .replaceAll('“', '"')
        .replaceAll('″', '"')
        .replaceAll("''", '"')
        .replaceAll(';', ',');
  }

  static final RegExp _dmsPartRegex = RegExp(
    r'([+-]?\d+(?:\.\d+)?)\s*°\s*(\d+(?:\.\d+)?)\s*\x27\s*(\d+(?:\.\d+)?)\s*"\s*([NSEWO])?',
    caseSensitive: false,
  );

  static CoordinateParseResult? _tryParseDms(String input) {
    final matches = _dmsPartRegex.allMatches(input).toList();
    if (matches.length != 2) return null;

    final first = _convertDmsMatch(matches[0], isSecondComponent: false);
    if (first.error != null) return CoordinateParseResult.failure(first.error!);

    final second = _convertDmsMatch(matches[1], isSecondComponent: true);
    if (second.error != null) return CoordinateParseResult.failure(second.error!);

    return _buildValidatedPair(
      firstValue: first.value!,
      firstHemi: first.hemisphere,
      secondValue: second.value!,
      secondHemi: second.hemisphere,
      format: CoordinateFormatType.dms,
    );
  }

  static ({double? value, String? hemisphere, String? error}) _convertDmsMatch(
    RegExpMatch match, {
    required bool isSecondComponent,
  }) {
    final rawDeg = double.tryParse(match.group(1)!);
    final rawMin = double.tryParse(match.group(2)!);
    final rawSec = double.tryParse(match.group(3)!);
    final hemi = match.group(4)?.toUpperCase();

    if (rawDeg == null || rawMin == null || rawSec == null) {
      return (value: null, hemisphere: null, error: 'Valores numéricos inválidos en formato DMS.');
    }
    if (rawMin < 0 || rawMin >= 60) {
      return (
        value: null,
        hemisphere: null,
        error: 'Los minutos en DMS deben estar entre 0 y 59.99 (recibido: $rawMin\').',
      );
    }
    if (rawSec < 0 || rawSec >= 60) {
      return (
        value: null,
        hemisphere: null,
        error: 'Los segundos en DMS deben estar entre 0 y 59.99 (recibido: $rawSec").',
      );
    }

    final signFromNumber = match.group(1)!.trim().startsWith('-') ? -1.0 : 1.0;
    final absDeg = rawDeg.abs();
    final decimalAbs = absDeg + (rawMin / 60.0) + (rawSec / 3600.0);

    double sign = signFromNumber;
    if (hemi != null) {
      if (hemi == 'S' || hemi == 'W' || hemi == 'O') {
        sign = -1.0;
      } else if (hemi == 'N' || hemi == 'E') {
        sign = 1.0;
      }
    }

    return (value: sign * decimalAbs, hemisphere: hemi, error: null);
  }

  static final RegExp _dmmPartRegex = RegExp(
    r'([+-]?\d+(?:\.\d+)?)\s*°\s*(\d+(?:\.\d+)?)\s*\x27(?!\s*\d)\s*([NSEWO])?',
    caseSensitive: false,
  );

  static CoordinateParseResult? _tryParseDmm(String input) {
    if (input.contains('"')) return null;
    final matches = _dmmPartRegex.allMatches(input).toList();
    if (matches.length != 2) return null;

    final first = _convertDmmMatch(matches[0]);
    if (first.error != null) return CoordinateParseResult.failure(first.error!);

    final second = _convertDmmMatch(matches[1]);
    if (second.error != null) return CoordinateParseResult.failure(second.error!);

    return _buildValidatedPair(
      firstValue: first.value!,
      firstHemi: first.hemisphere,
      secondValue: second.value!,
      secondHemi: second.hemisphere,
      format: CoordinateFormatType.dmm,
    );
  }

  static ({double? value, String? hemisphere, String? error}) _convertDmmMatch(RegExpMatch match) {
    final rawDeg = double.tryParse(match.group(1)!);
    final rawMin = double.tryParse(match.group(2)!);
    final hemi = match.group(3)?.toUpperCase();

    if (rawDeg == null || rawMin == null) {
      return (value: null, hemisphere: null, error: 'Valores numéricos inválidos en formato DMM.');
    }
    if (rawMin < 0 || rawMin >= 60) {
      return (
        value: null,
        hemisphere: null,
        error: 'Los minutos en DMM deben estar entre 0 y 59.999 (recibido: $rawMin\').',
      );
    }

    final signFromNumber = match.group(1)!.trim().startsWith('-') ? -1.0 : 1.0;
    final absDeg = rawDeg.abs();
    final decimalAbs = absDeg + (rawMin / 60.0);

    double sign = signFromNumber;
    if (hemi != null) {
      if (hemi == 'S' || hemi == 'W' || hemi == 'O') {
        sign = -1.0;
      } else if (hemi == 'N' || hemi == 'E') {
        sign = 1.0;
      }
    }

    return (value: sign * decimalAbs, hemisphere: hemi, error: null);
  }

  static final RegExp _ddFullRegex = RegExp(
    r'^\s*([NS])?\s*([+-]?\d+(?:\.\d+)?)\s*°?\s*([NS])?\s*(?:,|\s+)\s*([EWO])?\s*([+-]?\d+(?:\.\d+)?)\s*°?\s*([EWO])?\s*$',
    caseSensitive: false,
  );

  static CoordinateParseResult? _tryParseDd(String input) {
    if (input.contains("'") || input.contains('"')) return null;

    final match = _ddFullRegex.firstMatch(input);
    if (match == null) return null;

    final latHemi = (match.group(1) ?? match.group(3))?.toUpperCase();
    final rawLatStr = match.group(2)!;
    final lonHemi = (match.group(4) ?? match.group(6))?.toUpperCase();
    final rawLonStr = match.group(5)!;

    final rawLat = double.tryParse(rawLatStr);
    final rawLon = double.tryParse(rawLonStr);
    if (rawLat == null || rawLon == null) return null;

    double lat = rawLat;
    if (latHemi != null) {
      lat = (latHemi == 'S' ? -1.0 : 1.0) * rawLat.abs();
    }

    double lon = rawLon;
    if (lonHemi != null) {
      lon = ((lonHemi == 'W' || lonHemi == 'O') ? -1.0 : 1.0) * rawLon.abs();
    }

    return _buildValidatedPair(
      firstValue: lat,
      firstHemi: latHemi,
      secondValue: lon,
      secondHemi: lonHemi,
      format: CoordinateFormatType.dd,
    );
  }

  static CoordinateParseResult _buildValidatedPair({
    required double firstValue,
    required String? firstHemi,
    required double secondValue,
    required String? secondHemi,
    required CoordinateFormatType format,
  }) {
    // Verificar que los hemisferios no estén invertidos o repetidos
    if (firstHemi != null && (firstHemi == 'E' || firstHemi == 'W' || firstHemi == 'O')) {
      return const CoordinateParseResult.failure(
        'El primer valor corresponde a la latitud y debe usar hemisferio N o S.',
      );
    }
    if (secondHemi != null && (secondHemi == 'N' || secondHemi == 'S')) {
      return const CoordinateParseResult.failure(
        'El segundo valor corresponde a la longitud y debe usar hemisferio E, W u O.',
      );
    }

    if (firstValue < -90.0 || firstValue > 90.0) {
      return CoordinateParseResult.failure(
        'Latitud fuera de rango (${firstValue.toStringAsFixed(4)}°). Debe estar entre -90° y 90°.',
      );
    }
    if (secondValue < -180.0 || secondValue > 180.0) {
      return CoordinateParseResult.failure(
        'Longitud fuera de rango (${secondValue.toStringAsFixed(4)}°). Debe estar entre -180° y 180°.',
      );
    }

    return CoordinateParseResult.success(
      coordinates: LatLng(
        double.parse(firstValue.toStringAsFixed(6)),
        double.parse(secondValue.toStringAsFixed(6)),
      ),
      format: format,
    );
  }

  /// Formatea un [LatLng] en cadena Grados Decimales (DD) estándar.
  static String formatDd(LatLng point, {int decimals = 5}) {
    return '${point.latitude.toStringAsFixed(decimals)}, ${point.longitude.toStringAsFixed(decimals)}';
  }

  /// Formatea un [LatLng] en cadena Grados, Minutos y Segundos (DMS).
  static String formatDms(LatLng point) {
    final latStr = _toDmsComponent(point.latitude, isLatitude: true);
    final lngStr = _toDmsComponent(point.longitude, isLatitude: false);
    return '$latStr $lngStr';
  }

  static String _toDmsComponent(double value, {required bool isLatitude}) {
    final hemi = isLatitude ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    final absVal = value.abs();
    final degrees = absVal.floor();
    final minFull = (absVal - degrees) * 60.0;
    final minutes = minFull.floor();
    final seconds = (minFull - minutes) * 60.0;
    return '$degrees°${minutes.toString().padLeft(2, '0')}\'${seconds.toStringAsFixed(1).padLeft(4, '0')}"$hemi';
  }
}
