import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class RealFaceDetectionResult {
  final bool hasFace;
  final bool isNoseAligned;
  final double confidence;
  final double faceX;
  final double faceY;
  final double faceWidth;
  final double faceHeight;
  final String status;

  const RealFaceDetectionResult({
    required this.hasFace,
    this.isNoseAligned = false,
    required this.confidence,
    required this.faceX,
    required this.faceY,
    required this.faceWidth,
    required this.faceHeight,
    required this.status,
  });

  factory RealFaceDetectionResult.noFace([String reason = "NO_FACE"]) {
    return RealFaceDetectionResult(
      hasFace: false,
      isNoseAligned: false,
      confidence: 0.0,
      faceX: 0.5,
      faceY: 0.5,
      faceWidth: 0.45,
      faceHeight: 0.55,
      status: reason,
    );
  }
}

@JS('__smartroute_analyze_face')
external JSObject? _jsAnalyzeFace(web.HTMLVideoElement? video);

extension type _JSAnalysisResult(JSObject _) implements JSObject {
  external bool? get hasFace;
  external bool? get isNoseAligned;
  external num? get confidence;
  external num? get faceX;
  external num? get faceY;
  external num? get faceWidth;
  external num? get faceHeight;
  external String? get status;
}

/// Gestor real de Cámara Web para Flutter Web usando package:web y HTML5 MediaDevices
/// Dispara el diálogo nativo del navegador solicitando permisos de cámara:
/// "¿Quieres permitir el uso de la cámara? [Permitir] [Bloquear]"
class RealCameraManager {
  static int _viewIdCounter = 0;
  web.HTMLVideoElement? _videoElement;
  web.MediaStream? _mediaStream;
  String? _viewType;
  bool _isInitialized = false;

  String get viewType => _viewType ?? 'camera-video-view';
  bool get isInitialized => _isInitialized;

  Future<bool> requestCameraPermissionAndInit() async {
    try {
      final mediaDevices = web.window.navigator.mediaDevices;

      // Solicita perfil adaptativo optimizado (720p 16:9 30fps ideal como la cámara del usuario)
      web.MediaStream? stream;
      try {
        final videoConstraints = {
          'width': {'ideal': 1280, 'min': 320}.jsify(),
          'height': {'ideal': 720, 'min': 240}.jsify(),
          'frameRate': {'ideal': 30, 'min': 15}.jsify(),
          'facingMode': 'user'.toJS,
        }.jsify();

        final constraints = web.MediaStreamConstraints(
          video: videoConstraints!,
          audio: false.toJS,
        );
        final streamPromise = mediaDevices.getUserMedia(constraints);
        stream = await streamPromise.toDart;
      } catch (_) {
        // Fallback inmediato si el hardware no soporta las restricciones ideales
        final fallbackConstraints = web.MediaStreamConstraints(
          video: true.toJS,
          audio: false.toJS,
        );
        final streamPromise = mediaDevices.getUserMedia(fallbackConstraints);
        stream = await streamPromise.toDart;
      }

      _mediaStream = stream;

      _viewIdCounter++;
      _viewType = 'real-camera-view-$_viewIdCounter';

      _videoElement = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true;

      _videoElement!.setAttribute('playsinline', 'true');
      _videoElement!.style.width = '100%';
      _videoElement!.style.height = '100%';
      _videoElement!.style.objectFit = 'cover';
      _videoElement!.style.transform = 'scaleX(-1)'; // Efecto espejo para selfie/cámara frontal
      _videoElement!.srcObject = stream;

      // Registrar la fábrica de vistas HTML en Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) => _videoElement!,
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint("Permiso de cámara denegado o error de hardware: $e");
      _isInitialized = false;
      return false;
    }
  }

  /// Analiza los fotogramas del video en tiempo real para determinar si HAY UN ROSTRO REAL
  RealFaceDetectionResult analyzeCurrentFrame() {
    if (!_isInitialized || _videoElement == null) {
      return RealFaceDetectionResult.noFace("CÁMARA_NO_INICIALIZADA");
    }

    try {
      final rawJs = _jsAnalyzeFace(_videoElement);
      if (rawJs == null) {
        return RealFaceDetectionResult.noFace("DETECTOR_NO_DISPONIBLE");
      }

      final res = _JSAnalysisResult(rawJs);
      final hasFace = res.hasFace ?? false;
      final isNose = res.isNoseAligned ?? false;
      final conf = (res.confidence ?? 0.0).toDouble();
      final fx = (res.faceX ?? 0.5).toDouble();
      final fy = (res.faceY ?? 0.5).toDouble();
      final fw = (res.faceWidth ?? 0.45).toDouble();
      final fh = (res.faceHeight ?? 0.55).toDouble();
      final st = res.status ?? "UNKNOWN";

      return RealFaceDetectionResult(
        hasFace: hasFace,
        isNoseAligned: isNose,
        confidence: conf,
        faceX: fx,
        faceY: fy,
        faceWidth: fw,
        faceHeight: fh,
        status: st,
      );
    } catch (e) {
      return RealFaceDetectionResult.noFace("ERROR_ANALISIS: $e");
    }
  }

  Widget buildPreviewWidget({Widget? fallback}) {
    if (!_isInitialized || _viewType == null) {
      return fallback ?? const SizedBox();
    }
    return HtmlElementView(viewType: _viewType!);
  }

  void stop() {
    try {
      if (_mediaStream != null) {
        final tracks = _mediaStream!.getTracks().toDart;
        for (final track in tracks) {
          track.stop();
        }
      }
      _videoElement?.pause();
      _videoElement?.srcObject = null;
      _mediaStream = null;
      _isInitialized = false;
    } catch (_) {}
  }
}
