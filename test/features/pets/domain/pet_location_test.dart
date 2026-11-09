import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';

void main() {
  group('PetLocation', () {
    test('accepts coordinates on the valid boundaries', () {
      expect(() => const PetLocation(latitude: -90, longitude: -180),
          returnsNormally);
      expect(() => const PetLocation(latitude: 90, longitude: 180),
          returnsNormally);
    });

    test('rejects latitude outside -90..90', () {
      expect(() => PetLocation(latitude: 91, longitude: 0),
          throwsA(isA<AssertionError>()));
      expect(() => PetLocation(latitude: -91, longitude: 0),
          throwsA(isA<AssertionError>()));
    });

    test('rejects longitude outside -180..180', () {
      expect(() => PetLocation(latitude: 0, longitude: 181),
          throwsA(isA<AssertionError>()));
    });

    test('isValid mirrors the constructor rules without throwing', () {
      expect(PetLocation.isValid(0, 0), isTrue);
      expect(PetLocation.isValid(91, 0), isFalse);
      expect(PetLocation.isValid(0, -181), isFalse);
    });

    test('normalized wraps longitudes that go around the world', () {
      final east = PetLocation.normalized(latitude: 10, longitude: 190);
      final west = PetLocation.normalized(latitude: 10, longitude: -190);
      final full = PetLocation.normalized(latitude: 10, longitude: 365);

      expect(east.longitude, closeTo(-170, 1e-9));
      expect(west.longitude, closeTo(170, 1e-9));
      expect(full.longitude, closeTo(5, 1e-9));
    });

    test('normalized keeps valid points and the reference unchanged', () {
      final point = PetLocation.normalized(
        latitude: -15.79,
        longitude: -47.88,
        reference: 'Praça',
      );

      expect(point.latitude, -15.79);
      expect(point.longitude, -47.88);
      expect(point.reference, 'Praça');
    });

    test('normalized clamps latitude to the poles', () {
      expect(PetLocation.normalized(latitude: 95, longitude: 0).latitude, 90);
      expect(PetLocation.normalized(latitude: -95, longitude: 0).latitude, -90);
    });

    test('has value equality', () {
      const a = PetLocation(latitude: 1, longitude: 2, reference: 'Praça');
      const b = PetLocation(latitude: 1, longitude: 2, reference: 'Praça');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(latitude: 3), isNot(a));
    });
  });
}
