import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';

import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  late FakePetRepository repository;

  setUp(() {
    repository = FakePetRepository();
    repository.store['pet-1'] = buildPet(name: 'Caramelo');
  });

  group('GetPetProfile', () {
    test('returns the pet with an empty care summary', () async {
      final result = await GetPetProfile(repository)('pet-1');

      final profile = result.valueOrNull!;
      expect(profile.pet.name, 'Caramelo');
      expect(profile.care.records, isEmpty);
      expect(profile.care.lastFeeding, isNull);
      expect(profile.care.lastBath, isNull);
    });

    test('fails with NotFoundFailure for an unknown id', () async {
      final result = await GetPetProfile(repository)('ghost');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('propagates storage failures', () async {
      repository.failWith = const StorageFailure();

      final result = await GetPetProfile(repository)('pet-1');

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });
}
