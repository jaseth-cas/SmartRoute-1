import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

void main() {
  group('Validators - Pruebas de Caja Blanca', () {
    group('validateEmail', () {
      // Ruta 1: Nulo o vacío
      test('debe retornar error si el correo es null', () {
        // Input: null
        expect(Validators.validateEmail(null), 'El correo es requerido');
      });

      test('debe retornar error si el correo está vacío', () {
        // Input: ''
        expect(Validators.validateEmail(''), 'El correo es requerido');
      });

      test('debe retornar error si el correo tiene solo espacios', () {
        // Input: '   '
        expect(Validators.validateEmail('   '), 'El correo es requerido');
      });

      // Ruta 2: Formato inválido (falla RegExp)
      test('debe retornar error si no tiene arroba', () {
        // Input: 'correo_sin_arroba'
        expect(Validators.validateEmail('correo_sin_arroba'), 'Ingresa un correo electrónico válido');
      });

      test('debe retornar error si no tiene dominio/extensión', () {
        // Input: 'correo@sin_dominio'
        expect(Validators.validateEmail('correo@sin_dominio'), 'Ingresa un correo electrónico válido');
      });

      test('debe retornar error si la extensión es muy corta', () {
        // Input: 'correo@dominio.c'
        expect(Validators.validateEmail('correo@dominio.c'), 'Ingresa un correo electrónico válido');
      });

      // Ruta 3: Formato válido (Happy path)
      test('debe retornar null para un correo válido', () {
        // Input: 'usuario@ejemplo.com'
        expect(Validators.validateEmail('usuario@ejemplo.com'), isNull);
      });

      test('debe retornar null para un correo válido con espacios extra', () {
        // Input: ' usuario@ejemplo.com '
        expect(Validators.validateEmail(' usuario@ejemplo.com '), isNull);
      });
    });

    group('validatePassword', () {
      // Ruta 1: Nulo o vacío
      test('debe retornar error si la contraseña es null', () {
        // Input: null
        expect(Validators.validatePassword(null), 'La contraseña es requerida');
      });

      test('debe retornar error si la contraseña está vacía', () {
        // Input: ''
        expect(Validators.validatePassword(''), 'La contraseña es requerida');
      });

      test('debe retornar error si la contraseña tiene solo espacios', () {
        // Input: '   '
        expect(Validators.validatePassword('   '), 'La contraseña es requerida');
      });

      // Ruta 2: Longitud menor a 6 caracteres
      test('debe retornar error si la longitud es menor a 6', () {
        // Input: '12345'
        expect(Validators.validatePassword('12345'), 'La contraseña debe tener al menos 6 caracteres');
      });

      test('comportamiento actual: espacios cuentan para la longitud', () {
        // Input: ' 1234 ' -> El length de esto es 6, evalúa como válido por la forma en que está escrito.
        expect(Validators.validatePassword(' 1234 '), isNull);
      });

      // Ruta 3: Longitud válida (Happy path)
      test('debe retornar null si la longitud es exactamente 6 (límite)', () {
        // Input: '123456'
        expect(Validators.validatePassword('123456'), isNull);
      });

      test('debe retornar null si la contraseña es válida y larga', () {
        // Input: 'password123'
        expect(Validators.validatePassword('password123'), isNull);
      });
    });
  });
}
