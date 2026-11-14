// Exportador condicional para soporte de Cámara Real en Web y nativo en Android/móvil
export 'camera_web_service_stub.dart'
    if (dart.library.js_interop) 'camera_web_service_web.dart';
