import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute_flutter/modulos/admin/utilidades/admin_validators.dart';

void main() {
  group('AdminRouteValidator - Pruebas de Caja Blanca (Camino Básico)', () {
    
    // Camino 1: Falla en la validación del nombre
    // Flujo: Nodo 1 -> Nodo 2 (Fin)
    test('Camino 1: Retorna error si el nombre es null o vacío', () {
      final resultNull = AdminRouteValidator.validateNewRouteData(
        name: null, 
        origin: 'Terminal A', 
        destination: 'Terminal B'
      );
      expect(resultNull, 'El nombre de la ruta es requerido');

      final resultEmpty = AdminRouteValidator.validateNewRouteData(
        name: '   ', 
        origin: 'Terminal A', 
        destination: 'Terminal B'
      );
      expect(resultEmpty, 'El nombre de la ruta es requerido');
    });

    // Camino 2: Nombre es válido, falla en la validación del origen
    // Flujo: Nodo 1 -> Nodo 3 -> Nodo 4 (Fin)
    test('Camino 2: Retorna error si el origen es null o vacío', () {
      final result = AdminRouteValidator.validateNewRouteData(
        name: 'Ruta Universitaria', 
        origin: '', 
        destination: 'Universidad'
      );
      expect(result, 'El origen de la ruta es requerido');
    });

    // Camino 3: Nombre y origen válidos, falla en la validación del destino
    // Flujo: Nodo 1 -> Nodo 3 -> Nodo 5 -> Nodo 6 (Fin)
    test('Camino 3: Retorna error si el destino es null o vacío', () {
      final result = AdminRouteValidator.validateNewRouteData(
        name: 'Ruta Universitaria', 
        origin: 'Estación Central', 
        destination: null
      );
      expect(result, 'El destino de la ruta es requerido');
    });

    // Camino 4: Todos los datos son correctos (Happy Path)
    // Flujo: Nodo 1 -> Nodo 3 -> Nodo 5 -> Nodo 7 (Fin exitoso)
    test('Camino 4: Retorna null cuando todos los campos son válidos', () {
      final result = AdminRouteValidator.validateNewRouteData(
        name: 'Ruta Universitaria', 
        origin: 'Estación Central', 
        destination: 'Universidad'
      );
      expect(result, isNull);
    });

  });
}
