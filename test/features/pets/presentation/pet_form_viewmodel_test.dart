import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_form_viewmodel.dart';

import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  final fixedNow = DateTime.utc(2025, 3, 12, 9);
  const location = PetLocation(latitude: -15.79, longitude: -47.88);

  late FakePetRepository repository;
  late TestImageStorage images;

  setUp(() async {
    repository = FakePetRepository();
    images = await TestImageStorage.create();
  });

  tearDown(() => images.dispose());

  PetFormViewModel buildVm() => PetFormViewModel(
        registerPet: RegisterPet(repository),
        imageStorage: images.service,
        location: location,
        now: () => fixedNow,
        newId: () => 'new-id',
      );

  group('initial state', () {
    test('has an id already, no species and nothing saved', () {
      final vm = buildVm();

      expect(vm.id, 'new-id');
      expect(vm.species, isNull);
      expect(vm.sex, PetSex.unknown);
      expect(vm.isDocile, TriState.unknown);
      expect(vm.isSaving, isFalse);
      expect(vm.savedPet, isNull);
      expect(vm.errors, isEmpty);
      expect(vm.showPregnantField, isTrue);
    });
  });

  group('save', () {
    test('refuses to save without a species (RN-01)', () async {
      final vm = buildVm();

      final ok = await vm.save();

      expect(ok, isFalse);
      expect(vm.errors['species'], 'Escolha se é cachorro ou gato.');
      expect(repository.addCalls, 0);
    });

    test('choosing a species clears its error', () async {
      final vm = buildVm();
      await vm.save();

      vm.setSpecies(PetSpecies.cat);

      expect(vm.errors['species'], isNull);
    });

    test('saves a pet that has only the species (RF-05)', () async {
      final vm = buildVm()..setSpecies(PetSpecies.cat);

      final ok = await vm.save();

      expect(ok, isTrue);
      final saved = vm.savedPet!;
      expect(saved.id, 'new-id');
      expect(saved.species, PetSpecies.cat);
      expect(saved.createdAt, fixedNow);
      expect(saved.updatedAt, fixedNow);
      expect(saved.location.latitude, -15.79);
      expect(repository.store.keys, ['new-id']);
    });

    test('turns blank text into null and trims the rest', () async {
      final vm = buildVm()
        ..setSpecies(PetSpecies.dog)
        ..setName('   ')
        ..setAppearance('  manchas brancas ')
        ..setReference('  Praça  ');

      await vm.save();

      final saved = vm.savedPet!;
      expect(saved.name, isNull);
      expect(saved.appearance, 'manchas brancas');
      expect(saved.location.reference, 'Praça');
    });

    test('two simultaneous saves create a single pet (RN-09)', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);

      final results = await Future.wait([vm.save(), vm.save()]);

      expect(results, [true, false]);
      expect(repository.addCalls, 1);
    });

    test('saving again after success does not add again', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);

      await vm.save();
      final again = await vm.save();

      expect(again, isTrue);
      expect(repository.addCalls, 1);
    });

    test('maps validation failures to their fields', () async {
      final vm = buildVm()
        ..setSpecies(PetSpecies.dog)
        ..setName('a' * 61);

      final ok = await vm.save();

      expect(ok, isFalse);
      expect(vm.errors['name'], isNotNull);
      expect(vm.isSaving, isFalse);
      expect(repository.addCalls, 0);
    });

    test('keeps the form and allows retry after a storage failure', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);
      repository.failWith = const StorageFailure();

      expect(await vm.save(), isFalse);
      expect(vm.generalError, 'Não foi possível salvar. Tente novamente.');
      expect(vm.isSaving, isFalse);
      expect(vm.species, PetSpecies.dog);

      repository.failWith = null;
      expect(await vm.save(), isTrue);
      expect(vm.generalError, isNull);
    });

    test('notifies listeners while saving', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.isSaving));

      await vm.save();

      expect(seen.first, isTrue);
      expect(seen.last, isFalse);
    });
  });

  group('editing an existing pet', () {
    final editedAt = DateTime.utc(2025, 6, 1, 10);

    Pet original() => buildPet(name: 'Rex', sex: PetSex.female).copyWith(
          rabiesVaccination: TriState.no,
          otherHealthInfo: 'Magro',
          photoFileName: 'orig.jpg',
          appearance: 'Caramelo',
        );

    PetFormViewModel buildEditVm() => PetFormViewModel.edit(
          updatePet: UpdatePet(repository, () => editedAt),
          imageStorage: images.service,
          pet: original(),
          now: () => editedAt,
        );

    Future<void> writeOriginalPhoto() async {
      final file = images.service.fileFor('orig.jpg');
      await file.create(recursive: true);
      await file.writeAsBytes([9]);
    }

    setUp(() => repository.store['pet-1'] = original());

    test('a new pet form is not in edit mode', () {
      expect(buildVm().isEditing, isFalse);
    });

    test('starts with the current values of the pet', () {
      final vm = buildEditVm();

      expect(vm.isEditing, isTrue);
      expect(vm.id, 'pet-1');
      expect(vm.species, PetSpecies.dog);
      expect(vm.sex, PetSex.female);
      expect(vm.name, 'Rex');
      expect(vm.appearance, 'Caramelo');
      expect(vm.rabiesVaccination, TriState.no);
      expect(vm.otherHealthInfo, 'Magro');
      expect(vm.photoFileName, 'orig.jpg');
      expect(vm.location.latitude, -15.79);
    });

    test('save updates the same pet and keeps createdAt (RN-07)', () async {
      final vm = buildEditVm()
        ..setName('Thor')
        ..setRabies(TriState.yes);

      final ok = await vm.save();

      expect(ok, isTrue);
      final saved = repository.store['pet-1']!;
      expect(saved.name, 'Thor');
      expect(saved.rabiesVaccination, TriState.yes);
      expect(saved.createdAt, DateTime.utc(2025, 3, 12));
      expect(saved.updatedAt, editedAt);
      expect(repository.addCalls, 0);
    });

    test('untouched fields are kept and a cleared name becomes null', () async {
      final vm = buildEditVm()..setName('');

      await vm.save();

      final saved = repository.store['pet-1']!;
      expect(saved.name, isNull);
      expect(saved.otherHealthInfo, 'Magro');
      expect(saved.appearance, 'Caramelo');
    });

    test('other health info can be edited', () async {
      final vm = buildEditVm()..setOtherHealthInfo('Vacinado em 2024');

      await vm.save();

      expect(repository.store['pet-1']!.otherHealthInfo, 'Vacinado em 2024');
    });

    test('an unknown pet fails with a general error', () async {
      repository.store.clear();
      final vm = buildEditVm();

      final ok = await vm.save();

      expect(ok, isFalse);
      expect(vm.generalError, 'Registro não encontrado.');
    });

    test('replacing the photo deletes the old file only after saving',
        () async {
      await writeOriginalPhoto();
      await images.queuePhoto();
      final vm = buildEditVm();

      await vm.pickPhoto(ImageOrigin.camera);
      expect(vm.photoFileName, 'photo-1.jpg');
      expect(images.service.fileFor('orig.jpg').existsSync(), isTrue);

      await vm.save();

      expect(images.service.fileFor('orig.jpg').existsSync(), isFalse);
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isTrue);
      expect(repository.store['pet-1']!.photoFileName, 'photo-1.jpg');
    });

    test('removing the photo clears it and deletes the file after saving',
        () async {
      await writeOriginalPhoto();
      final vm = buildEditVm();

      await vm.removePhoto();
      expect(images.service.fileFor('orig.jpg').existsSync(), isTrue);

      await vm.save();

      expect(images.service.fileFor('orig.jpg').existsSync(), isFalse);
      expect(repository.store['pet-1']!.photoFileName, isNull);
    });

    test('a failed save keeps both the old and the new photo', () async {
      await writeOriginalPhoto();
      await images.queuePhoto();
      final vm = buildEditVm();
      await vm.pickPhoto(ImageOrigin.camera);
      repository.failWith = const StorageFailure();

      final ok = await vm.save();

      expect(ok, isFalse);
      expect(images.service.fileFor('orig.jpg').existsSync(), isTrue);
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isTrue);
    });

    test('discarding the form deletes only the new photo', () async {
      await writeOriginalPhoto();
      await images.queuePhoto();
      final vm = buildEditVm();
      await vm.pickPhoto(ImageOrigin.camera);

      vm.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(images.service.fileFor('orig.jpg').existsSync(), isTrue);
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isFalse);
    });
  });

  group('location', () {
    test('starts at the point that was tapped on the map', () {
      final vm = buildVm();

      expect(vm.location.latitude, -15.79);
      expect(vm.location.longitude, -47.88);
    });

    test('setLocation moves the point and the saved pet uses it (RF-07)',
        () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setLocation(-15.80, -47.90);
      await vm.save();

      expect(notified, isTrue);
      expect(vm.savedPet!.location.latitude, -15.80);
      expect(vm.savedPet!.location.longitude, -47.90);
    });

    test('setLocation wraps a longitude beyond the date line', () {
      final vm = buildVm()..setLocation(10, 190);

      expect(vm.location.longitude, closeTo(-170, 1e-9));
    });

    test('setLocation ignores points that are not real numbers', () {
      final vm = buildVm()..setLocation(double.nan, 10);

      expect(vm.location.latitude, -15.79);
      expect(vm.location.longitude, -47.88);
    });

    test('the reference typed by the user survives moving the point', () async {
      final vm = buildVm()
        ..setSpecies(PetSpecies.dog)
        ..setReference('Praça')
        ..setLocation(-15.80, -47.90);

      await vm.save();

      expect(vm.savedPet!.location.reference, 'Praça');
    });
  });

  group('conditional fields', () {
    test('a male never keeps "pregnant = yes" (RN-02)', () {
      final vm = buildVm()
        ..setSex(PetSex.female)
        ..setPregnant(TriState.yes);

      vm.setSex(PetSex.male);

      expect(vm.isPregnant, TriState.unknown);
      expect(vm.showPregnantField, isFalse);
    });

    test('litter size is only kept when there is a litter (RN-03)', () async {
      final withLitter = buildVm()
        ..setSpecies(PetSpecies.cat)
        ..setHasLitter(TriState.yes)
        ..setLitterSize(3);
      await withLitter.save();
      expect(withLitter.savedPet!.litterSize, 3);

      final noLitter = buildVm()
        ..setSpecies(PetSpecies.cat)
        ..setLitterSize(3)
        ..setHasLitter(TriState.no);
      expect(noLitter.litterSize, isNull);
    });

    test('injury description only counts when there are injuries', () async {
      final without = buildVm()
        ..setSpecies(PetSpecies.dog)
        ..setInjuryDescription('corte');
      await without.save();
      expect(without.savedPet!.injuryDescription, isNull);

      final repository2 = FakePetRepository();
      final withInjury = PetFormViewModel(
        registerPet: RegisterPet(repository2),
        imageStorage: images.service,
        location: location,
        now: () => fixedNow,
        newId: () => 'other-id',
      )
        ..setSpecies(PetSpecies.dog)
        ..setHasInjuries(TriState.yes)
        ..setInjuryDescription('corte na orelha');
      await withInjury.save();
      expect(withInjury.savedPet!.injuryDescription, 'corte na orelha');
    });
  });

  group('photo', () {
    test('pickPhoto stores the saved file name (RF-06)', () async {
      await images.queuePhoto();
      final vm = buildVm();

      await vm.pickPhoto(ImageOrigin.camera);

      expect(vm.photoFileName, 'photo-1.jpg');
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isTrue);
    });

    test('choosing another photo deletes the previous one', () async {
      final vm = buildVm();
      await images.queuePhoto('a.jpg');
      await vm.pickPhoto(ImageOrigin.camera);
      await images.queuePhoto('b.jpg');
      await vm.pickPhoto(ImageOrigin.gallery);

      expect(vm.photoFileName, 'photo-2.jpg');
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isFalse);
      expect(images.service.fileFor('photo-2.jpg').existsSync(), isTrue);
    });

    test('cancelling the picker keeps the current photo', () async {
      final vm = buildVm();
      await images.queuePhoto();
      await vm.pickPhoto(ImageOrigin.camera);

      images.picker.nextPath = null;
      await vm.pickPhoto(ImageOrigin.gallery);

      expect(vm.photoFileName, 'photo-1.jpg');
    });

    test('a picker failure shows a message and keeps the form usable',
        () async {
      final vm = buildVm();
      images.picker.error = StateError('sem permissão');

      await vm.pickPhoto(ImageOrigin.camera);

      expect(vm.photoFileName, isNull);
      expect(vm.photoError, 'Não foi possível usar essa foto.');
    });

    test('removePhoto deletes the file and clears the name', () async {
      final vm = buildVm();
      await images.queuePhoto();
      await vm.pickPhoto(ImageOrigin.camera);

      await vm.removePhoto();

      expect(vm.photoFileName, isNull);
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isFalse);
    });

    test('an unsaved photo is deleted when the form is discarded', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);
      await images.queuePhoto();
      await vm.pickPhoto(ImageOrigin.camera);

      vm.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(images.service.fileFor('photo-1.jpg').existsSync(), isFalse);
    });

    test('a saved photo survives the form being closed', () async {
      final vm = buildVm()..setSpecies(PetSpecies.dog);
      await images.queuePhoto();
      await vm.pickPhoto(ImageOrigin.camera);
      await vm.save();

      vm.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(vm.savedPet!.photoFileName, 'photo-1.jpg');
      expect(images.service.fileFor('photo-1.jpg').existsSync(), isTrue);
    });
  });
}
