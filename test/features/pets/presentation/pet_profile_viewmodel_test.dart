import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/state/view_state.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_profile_viewmodel.dart';

import '../../../support/fake_image_picker.dart';
import '../../../support/fake_care_repository.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  late FakePetRepository repository;
  late TestImageStorage images;

  setUp(() async {
    repository = FakePetRepository();
    images = await TestImageStorage.create();
  });

  tearDown(() => images.dispose());

  PetProfileViewModel buildVm([String id = 'pet-1']) => PetProfileViewModel(
        petId: id,
        getPetProfile: GetPetProfile(repository, FakeCareRepository()),
        deletePet: DeletePet(repository),
        imageStorage: images.service,
      );

  Future<String> savePhoto() async {
    await images.queuePhoto();
    final name = (await images.service.pick(ImageOrigin.camera)).valueOrNull!;
    return name;
  }

  group('load', () {
    test('starts loading', () {
      expect(buildVm().state, isA<Loading<PetProfile>>());
    });

    test('shows the profile of the pet', () async {
      repository.store['pet-1'] = buildPet(name: 'Caramelo');
      final vm = buildVm();

      await vm.load();

      final state = vm.state as Loaded<PetProfile>;
      expect(state.data.pet.name, 'Caramelo');
    });

    test('an unknown pet becomes a Failed state', () async {
      final vm = buildVm('ghost');

      await vm.load();

      expect((vm.state as Failed<PetProfile>).failure, isA<NotFoundFailure>());
    });

    test('reloading keeps the profile on screen and picks up changes',
        () async {
      repository.store['pet-1'] = buildPet(name: 'Rex');
      final vm = buildVm();
      await vm.load();
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.state is Loading<PetProfile>));
      repository.store['pet-1'] = buildPet(name: 'Thor');

      await vm.load();

      expect(seen, isNot(contains(true)));
      expect((vm.state as Loaded<PetProfile>).data.pet.name, 'Thor');
    });
  });

  group('delete', () {
    test('removes the pet and its photo file (RF-16)', () async {
      final photo = await savePhoto();
      repository.store['pet-1'] =
          buildPet(name: 'Rex').copyWith(photoFileName: photo);
      final vm = buildVm();
      await vm.load();

      final ok = await vm.delete();

      expect(ok, isTrue);
      expect(vm.deleted, isTrue);
      expect(repository.store, isEmpty);
      expect(images.service.fileFor(photo).existsSync(), isFalse);
    });

    test('removes a pet that has no photo', () async {
      repository.store['pet-1'] = buildPet();
      final vm = buildVm();
      await vm.load();

      expect(await vm.delete(), isTrue);
      expect(repository.store, isEmpty);
    });

    test('keeps the pet and the photo when the removal fails', () async {
      final photo = await savePhoto();
      repository.store['pet-1'] = buildPet().copyWith(photoFileName: photo);
      final vm = buildVm();
      await vm.load();
      repository.failWith = const StorageFailure();

      final ok = await vm.delete();

      expect(ok, isFalse);
      expect(vm.deleted, isFalse);
      expect(vm.deleteError, 'Não foi possível salvar. Tente novamente.');
      expect(vm.isDeleting, isFalse);
      expect(repository.store, isNotEmpty);
      expect(images.service.fileFor(photo).existsSync(), isTrue);
    });

    test('two simultaneous removals run only once', () async {
      repository.store['pet-1'] = buildPet();
      final vm = buildVm();
      await vm.load();

      final results = await Future.wait([vm.delete(), vm.delete()]);

      expect(results, [true, false]);
    });

    test('cannot remove before the profile is loaded', () async {
      repository.store['pet-1'] = buildPet();
      final vm = buildVm();

      expect(await vm.delete(), isFalse);
      expect(repository.store, isNotEmpty);
    });
  });
}
