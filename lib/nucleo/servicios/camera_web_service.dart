// Exportador condicional para soporte de Cámara Real en Web y fallback en móvil/desktop
export 'camera_web_service_stub.dart'
    if (dart.library.html) 'camera_web_service_web.dart';
