import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';

void main() {
  group('Modelos de SmartRoute - Pruebas de Serialización y Estados', () {
    test('BusMock serializa y deserializa correctamente con Sello Trust & Safety', () {
      final map = {
        'id': 1,
        'codigo': 'BUS-01',
        'placa': 'TBX-492',
        'modelo': 'Toyota Coaster Escolar',
        'capacidad': 16,
        'asientos_ocupados': 14,
        'estado': 'En recorrido',
        'conductor_nombre': 'Carlos Gómez',
        'dueno_nombre': 'Transportes Escolar',
        'nombre_ruta': 'Ruta Escolar Norte',
        'velocidad_kmh': 42,
        'latitud_actual': 9.9340,
        'longitud_actual': -84.0780,
        'is_verified': true,
        'colegio_asignado': 'Colegio San José',
      };

      final bus = BusMock.fromMap(map);

      expect(bus.code, 'BUS-01');
      expect(bus.plate, 'TBX-492');
      expect(bus.capacity, 16);
      expect(bus.seatsOccupied, 14);
      expect(bus.status, 'En recorrido');
      expect(bus.currentSpeedKmH, 42);
      expect(bus.isVerified, true);
      expect(bus.latitude, 9.9340);
      expect(bus.longitude, -84.0780);

      final serialized = bus.toMap();
      expect(serialized['codigo'], 'BUS-01');
      expect(serialized['velocidad_kmh'], 42);
      expect(serialized['is_verified'], true);
    });

    test('StudentPassengerMock maneja correctamente cuotas y estados de pago', () {
      final map = {
        'id': 1,
        'nombre': 'Mateo Gómez',
        'padre_nombre': 'Carlos Gómez',
        'padre_telefono': '+57 300 123 4567',
        'colegio': 'Colegio San José',
        'direccion_recogida': 'Calle 45 # 12-30',
        'autobus_codigo': 'BUS-01',
        'orden': 1,
        'cuota_mensual': 65.0,
        'estado_pago': 'Al día',
      };

      final student = StudentPassengerMock.fromMap(map);

      expect(student.name, 'Mateo Gómez');
      expect(student.parentName, 'Carlos Gómez');
      expect(student.schoolName, 'Colegio San José');
      expect(student.monthlyFee, 65.0);
      expect(student.paymentStatus, 'Al día');
      expect(student.order, 1);
    });

    test('StudentPassengerMock procesa los 4 estados de abordaje y método biométrico', () {
      final baseMap = {
        'id': 1,
        'nombre': 'Mateo Gómez',
        'padre_nombre': 'Carlos Gómez',
        'padre_telefono': '+57 300 123 4567',
        'colegio': 'Colegio San José',
        'direccion_recogida': 'Calle 45 # 12-30',
        'autobus_codigo': 'BUS-01',
        'orden': 1,
        'cuota_mensual': 65.0,
        'estado_pago': 'Al día',
      };

      // 1. Waiting
      final waiting = StudentPassengerMock.fromMap(baseMap, {'estado': 'waiting'});
      expect(waiting.status, PassengerStatus.waiting);

      // 2. Onboard con Biometría Facial AI
      final onboard = StudentPassengerMock.fromMap(baseMap, {
        'estado': 'onboard',
        'hora_abordaje': '07:14 AM',
        'metodo_abordaje': 'Biometría Facial AI',
      });
      expect(onboard.status, PassengerStatus.onboard);
      expect(onboard.lastBoardingTime, '07:14 AM');
      expect(onboard.boardingMethod, 'Biometría Facial AI');

      // 3. Absent
      final absent = StudentPassengerMock.fromMap(baseMap, {'estado': 'absent'});
      expect(absent.status, PassengerStatus.absent);

      // 4. Delivered
      final delivered = StudentPassengerMock.fromMap(baseMap, {'estado': 'delivered'});
      expect(delivered.status, PassengerStatus.delivered);
    });

    test('FleetFinancialSummary calcula correctamente tasa de ocupación', () {
      const summary = FleetFinancialSummary(
        totalSeats: 40,
        occupiedSeats: 30,
        totalRevenue: 2600.0,
        pendingRevenue: 130.0,
        pendingPaymentsCount: 2,
        totalStudents: 30,
      );

      expect(summary.occupancyRate, 75.0);
      expect(summary.totalSeats, 40);
      expect(summary.occupiedSeats, 30);
    });
  });
}
