import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loader animado de tránsito escolar rediseñado con el estilo visual
/// cartoon de alta fidelidad:
/// - Autobús escolar Toyota HiAce ("COLEGIAL") orientado hacia la izquierda con líneas de contorno negras.
/// - Poste de luz a la izquierda con cono de iluminación cálido hacia la carretera.
/// - Líneas de velocidad y viento en la parte trasera.
/// - Nubes de polvo / humo de escape detrás de las ruedas traseras.
/// - Ruedas gruesas con rotación continua y suspensión activa.
/// - Carretera con líneas discontinuas en movimiento.
class BusTransitLoader extends StatefulWidget {
  final double width;
  final double height;

  const BusTransitLoader({
    super.key,
    this.width = double.infinity,
    this.height = 155,
  });

  @override
  State<BusTransitLoader> createState() => _BusTransitLoaderState();
}

class _BusTransitLoaderState extends State<BusTransitLoader>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _wheelsController;
  late final AnimationController _roadController;

  @override
  void initState() {
    super.initState();

    // 1. Rebote de suspensión y ondulación de polvo/viento (1.0s)
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // 2. Rotación continua de ruedas (0.6s)
    _wheelsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // 3. Desplazamiento de carretera (1.2s)
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _wheelsController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _motionController,
            _wheelsController,
            _roadController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _CartoonHiAceScenePainter(
                motionProgress: _motionController.value,
                wheelRotation: _wheelsController.value * math.pi * 2,
                roadProgress: _roadController.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartoonHiAceScenePainter extends CustomPainter {
  final double motionProgress;
  final double wheelRotation;
  final double roadProgress;

  _CartoonHiAceScenePainter({
    required this.motionProgress,
    required this.wheelRotation,
    required this.roadProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Escala adaptativa para responder tanto en móviles como en web
    final baseWidth = 440.0;
    final scale = (size.width / baseWidth).clamp(0.72, 1.15);

    final roadY = size.height - (18.0 * scale);
    final roadHeight = 12.0 * scale;

    // ----------------------------------------------------
    // 1. CARRETERA (Asfalto y marcas viales)
    // ----------------------------------------------------
    _drawRoad(canvas, size, roadY, roadHeight, scale);

    // ----------------------------------------------------
    // 2. POSTE DE LUZ Y CONO DE ILUMINACIÓN (Izquierda)
    // ----------------------------------------------------
    final lampX = size.width * 0.18;
    _drawStreetLamp(canvas, lampX, roadY, scale);

    // ----------------------------------------------------
    // 3. AUTOBÚS COLEGIAL TOYOTA HIACE (Centrado / orientado a la izquierda)
    // ----------------------------------------------------
    final vanWidth = 145.0 * scale;
    final vanHeight = 72.0 * scale;
    // Ubicar la van de manera que el frente quede dentro del haz de luz
    final vanLeft = math.max(lampX + (36.0 * scale), size.width * 0.40 - (vanWidth / 2));
    final vanBaseY = roadY - (6.0 * scale);

    // Oscilación vertical física de suspensión (rebote)
    final suspensionOffset = math.sin(motionProgress * math.pi * 2) * (2.2 * scale);

    // Guardar para aplicar la suspensión a la carrocería y detalles
    canvas.save();
    canvas.translate(0, suspensionOffset);

    // Líneas de velocidad y viento (detrás de la van, a la derecha)
    _drawSpeedLines(canvas, vanLeft + vanWidth, vanBaseY - vanHeight, scale);

    // Nubes de polvo / humo de escape bajo la rueda trasera
    _drawDustPuffs(canvas, vanLeft + vanWidth - (12 * scale), roadY - (4 * scale), scale);

    // Carrocería principal de la van escolar
    _drawVanBody(canvas, vanLeft, vanBaseY, vanWidth, vanHeight, scale);

    canvas.restore();

    // ----------------------------------------------------
    // 4. RUEDAS CHUNKY (Apoyadas firmemente sobre la carretera)
    // ----------------------------------------------------
    final frontWheelCenter = Offset(vanLeft + (32.0 * scale), roadY - (8.5 * scale));
    final rearWheelCenter = Offset(vanLeft + vanWidth - (30.0 * scale), roadY - (8.5 * scale));
    final wheelRadius = 14.5 * scale;

    _drawChunkyWheel(canvas, frontWheelCenter, wheelRadius, wheelRotation);
    _drawChunkyWheel(canvas, rearWheelCenter, wheelRadius, wheelRotation);
  }

  /// Dibuja la calzada de asfalto y las líneas divisorias en movimiento
  void _drawRoad(Canvas canvas, Size size, double roadY, double roadHeight, double scale) {
    final asphaltPaint = Paint()
      ..color = const Color(0xFF3F4855)
      ..style = PaintingStyle.fill;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.4 * scale
      ..style = PaintingStyle.stroke;

    final roadRect = Rect.fromLTWH(0, roadY, size.width, roadHeight);
    canvas.drawRect(roadRect, asphaltPaint);
    canvas.drawLine(Offset(0, roadY), Offset(size.width, roadY), roadBorderPaint);
    canvas.drawLine(Offset(0, roadY + roadHeight), Offset(size.width, roadY + roadHeight), roadBorderPaint);

    // Líneas blancas discontinuas (como el bus va hacia la izquierda, el suelo se desplaza a la derecha)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    final dashLength = 16.0 * scale;
    final dashGap = 26.0 * scale;
    final period = dashLength + dashGap;
    final moveOffset = roadProgress * period;

    for (double x = -period; x < size.width + period; x += period) {
      final startX = x + moveOffset;
      final endX = startX + dashLength;
      if (endX > 0 && startX < size.width) {
        canvas.drawLine(
          Offset(math.max(0, startX), roadY + (roadHeight / 2)),
          Offset(math.min(size.width, endX), roadY + (roadHeight / 2)),
          dashPaint,
        );
      }
    }
  }

  /// Dibuja el poste de luz curvado a la izquierda con el cono de luz amarillo
  void _drawStreetLamp(Canvas canvas, double lampX, double roadY, double scale) {
    final lampHeight = 84.0 * scale;
    final poleBaseY = roadY;
    final poleTopY = poleBaseY - lampHeight;
    final lampHeadX = lampX + (26.0 * scale);
    final lampHeadY = poleTopY + (12.0 * scale);

    // 1. Cono de iluminación cálido (Triángulo amarillo suave hacia la carretera)
    final lightConePath = Path()
      ..moveTo(lampHeadX, lampHeadY + (3 * scale))
      ..lineTo(lampX - (6.0 * scale), roadY)
      ..lineTo(lampHeadX + (54.0 * scale), roadY)
      ..close();

    final lightConePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFDE047).withValues(alpha: 0.58),
          const Color(0xFFFEF08A).withValues(alpha: 0.28),
          const Color(0xFFFEF08A).withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(lampX - 10, lampHeadY, 70 * scale, lampHeight));

    canvas.drawPath(lightConePath, lightConePaint);

    // 2. Base del poste de luz
    final basePaint = Paint()..color = const Color(0xFF334155);
    final baseOutline = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.2 * scale
      ..style = PaintingStyle.stroke;

    final baseRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(lampX, poleBaseY - (4 * scale)), width: 14 * scale, height: 8 * scale),
      topLeft: Radius.circular(3 * scale),
      topRight: Radius.circular(3 * scale),
    );
    canvas.drawRRect(baseRect, basePaint);
    canvas.drawRRect(baseRect, baseOutline);

    // 3. Poste de luz curvado
    final polePath = Path()
      ..moveTo(lampX, poleBaseY - (8 * scale))
      ..lineTo(lampX, poleTopY + (20 * scale))
      ..quadraticBezierTo(lampX, poleTopY, lampHeadX - (4 * scale), poleTopY + (4 * scale));

    final poleOutline = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 3.6 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final poleFill = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(polePath, poleOutline);
    canvas.drawPath(polePath, poleFill);

    // 4. Campana / Pantalla de la lámpara
    final lampCapPath = Path()
      ..moveTo(lampHeadX - (10 * scale), lampHeadY)
      ..quadraticBezierTo(lampHeadX, lampHeadY - (8 * scale), lampHeadX + (10 * scale), lampHeadY)
      ..close();

    canvas.drawPath(lampCapPath, Paint()..color = const Color(0xFF334155));
    canvas.drawPath(lampCapPath, baseOutline);

    // Foco emisor brillante
    final bulbPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lampHeadX, lampHeadY + (1.5 * scale)), width: 14 * scale, height: 4 * scale),
        Radius.circular(2 * scale),
      ),
      bulbPaint,
    );
  }

  /// Dibuja la carrocería del autobús colegial Toyota HiAce orientado a la izquierda
  void _drawVanBody(Canvas canvas, double left, double baseY, double w, double h, double scale) {
    final top = baseY - h;

    final strokePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.6 * scale
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final bodyFillPaint = Paint()
      ..color = const Color(0xFFF59E0B) // Amarillo escolar cálido
      ..style = PaintingStyle.fill;

    // ----------------------------------------------------
    // Silueta exterior del autobús colegial (Frente a la izquierda)
    // ----------------------------------------------------
    final body = Path();
    // Inicia en la esquina inferior delantera (parachoques)
    body.moveTo(left, baseY);
    // Frente vertical del parachoques y parrilla
    body.lineTo(left, top + (40 * scale));
    // Frente inclinado / Capó corto característico del HiAce
    body.lineTo(left + (12 * scale), top + (34 * scale));
    // Parabrisas aerodinámico inclinado hacia atrás (sube a la derecha)
    body.lineTo(left + (26 * scale), top);
    // Techo horizontal
    body.lineTo(left + w - (8 * scale), top);
    // Esquina superior trasera redondeada
    body.quadraticBezierTo(left + w, top, left + w, top + (8 * scale));
    // Panel trasero vertical
    body.lineTo(left + w, baseY - (6 * scale));
    // Esquina inferior trasera
    body.lineTo(left + w - (8 * scale), baseY);

    // Arco de rueda trasera
    final rearArchCenterX = left + w - (30 * scale);
    body.lineTo(rearArchCenterX + (18 * scale), baseY);
    body.arcToPoint(
      Offset(rearArchCenterX - (18 * scale), baseY),
      radius: Radius.circular(18 * scale),
      clockwise: false,
    );

    // Falda inferior entre ruedas
    final frontArchCenterX = left + (32 * scale);
    body.lineTo(frontArchCenterX + (18 * scale), baseY);

    // Arco de rueda delantera
    body.arcToPoint(
      Offset(frontArchCenterX - (18 * scale), baseY),
      radius: Radius.circular(18 * scale),
      clockwise: false,
    );

    // Parte inferior delantera
    body.lineTo(left, baseY);
    body.close();

    // Relleno y contorno negro
    canvas.drawPath(body, bodyFillPaint);
    canvas.drawPath(body, strokePaint);

    // ----------------------------------------------------
    // Ventanas tintadas oscuras (Windshield, conductor, pasajeros)
    // ----------------------------------------------------
    final windowPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final windowStroke = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.2 * scale
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // 1. Parabrisas frontal inclinado (izquierda)
    final frontWindshield = Path()
      ..moveTo(left + (14 * scale), top + (32 * scale))
      ..lineTo(left + (26 * scale), top + (5 * scale))
      ..lineTo(left + (40 * scale), top + (5 * scale))
      ..lineTo(left + (40 * scale), top + (32 * scale))
      ..close();
    canvas.drawPath(frontWindshield, windowPaint);
    canvas.drawPath(frontWindshield, windowStroke);

    // 2. Ventana de puerta del conductor
    final driverWin = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + (44 * scale), top + (5 * scale), 20 * scale, 27 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(driverWin, windowPaint);
    canvas.drawRRect(driverWin, windowStroke);

    // Manija de la puerta delantera
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + (48 * scale), top + (36 * scale), 8 * scale, 3 * scale),
      Radius.circular(1.5 * scale),
    );
    canvas.drawRRect(handleRect, Paint()..color = const Color(0xFF18181B));

    // 3. Ventana panorámica de pasajeros
    final passengerWin = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + (68 * scale), top + (5 * scale), 58 * scale, 27 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(passengerWin, windowPaint);
    canvas.drawRRect(passengerWin, windowStroke);

    // ----------------------------------------------------
    // Letrero Negro "COLEGIAL"
    // ----------------------------------------------------
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'COLEGIAL',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF18181B),
          fontSize: 10.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(left + (69 * scale), top + (38 * scale)));

    // ----------------------------------------------------
    // Frente: Parrilla frontal y Faro delantero
    // ----------------------------------------------------
    // Parrilla gris oscura en el parachoques delantero
    final grilleRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, top + (44 * scale), 8 * scale, 16 * scale),
      topRight: Radius.circular(2 * scale),
      bottomRight: Radius.circular(2 * scale),
    );
    canvas.drawRRect(grilleRect, Paint()..color = const Color(0xFF334155));
    canvas.drawRRect(grilleRect, windowStroke);

    // Faro frontal cuadrado/blanco brillante
    final headlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + (1 * scale), top + (36 * scale), 9 * scale, 9 * scale),
      Radius.circular(2 * scale),
    );
    canvas.drawRRect(headlightRect, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawRRect(headlightRect, windowStroke);

    // ----------------------------------------------------
    // Parte Trasera: Luz de freno vertical roja
    // ----------------------------------------------------
    final tailLightRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left + w - (4 * scale), top + (36 * scale), 4 * scale, 14 * scale),
      topLeft: Radius.circular(1.5 * scale),
      bottomLeft: Radius.circular(1.5 * scale),
    );
    canvas.drawRRect(tailLightRect, Paint()..color = const Color(0xFFEF4444));
    canvas.drawRRect(tailLightRect, windowStroke);
  }

  /// Dibuja líneas de viento y velocidad detrás del autobús
  void _drawSpeedLines(Canvas canvas, double rightX, double topY, double scale) {
    final speedLinePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    // Vibración sutil de las líneas de velocidad
    final wave = math.sin(motionProgress * math.pi * 4) * (2.0 * scale);

    // Línea 1 (Superior)
    canvas.drawLine(
      Offset(rightX + (8 * scale) + wave, topY + (14 * scale)),
      Offset(rightX + (26 * scale) + wave, topY + (14 * scale)),
      speedLinePaint,
    );
    // Línea 2 (Central - más larga)
    canvas.drawLine(
      Offset(rightX + (14 * scale) - wave, topY + (24 * scale)),
      Offset(rightX + (38 * scale) - wave, topY + (24 * scale)),
      speedLinePaint,
    );
    // Línea 3 (Inferior)
    canvas.drawLine(
      Offset(rightX + (6 * scale) + wave, topY + (34 * scale)),
      Offset(rightX + (22 * scale) + wave, topY + (34 * scale)),
      speedLinePaint,
    );
  }

  /// Dibuja las nubes de humo/polvo detrás de la rueda trasera
  void _drawDustPuffs(Canvas canvas, double startX, double baseY, double scale) {
    final dustPaint = Paint()
      ..color = const Color(0xFFE4D5C7)
      ..style = PaintingStyle.fill;

    final dustOutline = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 1.8 * scale
      ..style = PaintingStyle.stroke;

    final puffWobble = math.sin(motionProgress * math.pi * 3) * (1.2 * scale);

    void drawPuff(double x, double y, double radius) {
      canvas.drawCircle(Offset(x, y), radius, dustPaint);
      canvas.drawCircle(Offset(x, y), radius, dustOutline);
    }

    drawPuff(startX + (4 * scale), baseY - (4 * scale) + puffWobble, 7.5 * scale);
    drawPuff(startX + (14 * scale), baseY - (7 * scale) - puffWobble, 9.5 * scale);
    drawPuff(startX + (22 * scale), baseY - (3 * scale) + puffWobble, 6.0 * scale);
    drawPuff(startX - (3 * scale), baseY - (3 * scale), 5.0 * scale);
  }

  /// Dibuja las ruedas con borde negro y rotación continua
  void _drawChunkyWheel(Canvas canvas, Offset center, double radius, double rotation) {
    // 1. Neumático grueso negro
    final tirePaint = Paint()..color = const Color(0xFF18181B);
    canvas.drawCircle(center, radius, tirePaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, outlinePaint);

    // 2. Rin interior oscuro
    final rimPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawCircle(center, radius * 0.60, rimPaint);

    // 3. Tapa central y radios giratorios
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final spokePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 2;
      canvas.drawLine(
        Offset(math.cos(angle) * (radius * 0.2), math.sin(angle) * (radius * 0.2)),
        Offset(math.cos(angle) * (radius * 0.58), math.sin(angle) * (radius * 0.58)),
        spokePaint,
      );
    }

    // Centro
    canvas.drawCircle(Offset.zero, radius * 0.22, Paint()..color = const Color(0xFF18181B));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CartoonHiAceScenePainter oldDelegate) {
    return oldDelegate.motionProgress != motionProgress ||
        oldDelegate.wheelRotation != wheelRotation ||
        oldDelegate.roadProgress != roadProgress;
  }
}
