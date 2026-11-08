import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';

import '../../../support/fake_care_repository.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  late FakePetRepository pets;
  late FakeCareRepository care;
  late GetPetProfile getPetProfile;

  setUp(() {
    pets = FakePetRepository();
    care = FakeCareRepository();
    pets.store['pet-1'] = buildPet(name: 'Caramelo');
    getPetProfile = GetPetProfile(pets, care);
  });

  FeedingRecord feeding(String id, DateTime at, {String petId = 'pet-1'}) =>
      FeedingRecord(id: id, petId: petId, occurredAt: at);

  group('GetPetProfile', () {
    test('a pet with no care history has an empty summary', () async {
      final profile = (await getPetProfile('pet-1')).valueOrNull!;

      expect(profile.pet.name, 'Caramelo');
      expect(profile.care.records, isEmpty);
      expect(profile.care.lastFeeding, isNull);
      expect(profile.care.lastBath, isNull);
    });

    test('the last feeding is the greatest occurredAt (RN-08)', () async {
      care.store.addAll([
        feeding('a', DateTime.utc(2025, 3, 10)),
        feeding('b', DateTime.utc(2025, 3, 12)),
        feeding('c', DateTime.utc(2025, 3, 11)),
      ]);

      final profile = (await getPetProfile('pet-1')).valueOrNull!;

      expect(profile.care.lastFeeding, DateTime.utc(2025, 3, 12));
      expect(profile.care.recordsOf(CareType.feeding), hasLength(3));
    });

    test('only the care records of that pet are included', () async {
      care.store.addAll([
        feeding('mine', DateTime.utc(2025, 3, 10)),
        feeding('other', DateTime.utc(2025, 3, 12), petId: 'pet-2'),
      ]);

      final profile = (await getPetProfile('pet-1')).valueOrNull!;

      expect(profile.care.records.map((r) => r.id), ['mine']);
    });

    test('fails with NotFoundFailure for an unknown id', () async {
      final result = await getPetProfile('ghost');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('propagates pet storage failures', () async {
      pets.failWith = const StorageFailure();

      expect(
          (await getPetProfile('pet-1')).failureOrNull, isA<StorageFailure>());
    });

    test('propagates care storage failures', () async {
      care.failWith = const StorageFailure('sem cuidados');

      final result = await getPetProfile('pet-1');

      expect(result.failureOrNull!.message, 'sem cuidados');
    });
  });
}
