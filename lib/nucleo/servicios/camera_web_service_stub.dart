import 'package:flutter/widgets.dart';

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

// Implementación Stub para plataformas no-web
class RealCameraManager {
  String get viewType => 'camera-video-stub';
  bool get isInitialized => false;

  Future<bool> requestCameraPermissionAndInit() async {
    return false;
  }

  RealFaceDetectionResult analyzeCurrentFrame() {
    return RealFaceDetectionResult.noFace("STUB_NO_WEB");
  }

  Widget buildPreviewWidget({Widget? fallback}) {
    return fallback ?? const SizedBox();
  }

  void stop() {}
}
