import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/state/view_state.dart';
import 'package:mapa_do_pet/core/utils/clock.dart';
import 'package:mapa_do_pet/features/care/data/datasources/care_local_datasource.dart';
import 'package:mapa_do_pet/features/care/data/repositories/care_repository_impl.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/presentation/viewmodels/care_viewmodel.dart';
import 'package:mapa_do_pet/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:mapa_do_pet/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_form_viewmodel.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_list_viewmodel.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_profile_viewmodel.dart';

import '../support/fake_image_picker.dart';
import '../support/test_database.dart';

/// O app "montado" sobre um arquivo SQLite real: as mesmas classes do
/// composition root, sem widgets. Reabrir o arquivo simula fechar e reabrir o app.
class _App {
  _App._(this.db, this.images)
      : _pets = PetRepositoryImpl(PetLocalDataSource(db)) {
    final care = CareRepositoryImpl(CareLocalDataSource(db), systemNow);
    registerPet = RegisterPet(_pets);
    updatePet = UpdatePet(_pets, systemNow);
    deletePet = DeletePet(_pets);
    getPets = GetPets(_pets);
    getPetProfile = GetPetProfile(_pets, care);
    addCareRecord = AddCareRecord(care, systemNow);
  }

  static Future<_App> open(String path, TestImageStorage images) async =>
      _App._(await openTestDatabase(path: path), images);

  final AppDatabase db;
  final TestImageStorage images;
  final PetRepositoryImpl _pets;
  late final RegisterPet registerPet;
  late final UpdatePet updatePet;
  late final DeletePet deletePet;
  late final GetPets getPets;
  late final GetPetProfile getPetProfile;
  late final AddCareRecord addCareRecord;

  PetProfileViewModel profileOf(String petId) => PetProfileViewModel(
        petId: petId,
        getPetProfile: getPetProfile,
        deletePet: deletePet,
        imageStorage: images.service,
      );

  Future<int> count(String table) async {
    final rows = await db.db.rawQuery('SELECT COUNT(*) AS n FROM $table');
    return rows.first['n']! as int;
  }
}

void main() {
  late Directory dir;
  late String dbPath;
  late TestImageStorage images;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mapa_do_pet_flow_');
    dbPath = '${dir.path}${Platform.pathSeparator}app.db';
    images = await TestImageStorage.create();
  });

  tearDown(() async {
    await images.dispose();
    await dir.delete(recursive: true);
  });

  PetProfile loadedProfile(PetProfileViewModel vm) =>
      (vm.state as Loaded<PetProfile>).data;

  test('register, list, record care, edit, restart and remove', () async {
    var app = await _App.open(dbPath, images);

    // 1) Cadastrar pelo toque no mapa: só a espécie é obrigatória; com foto.
    final form = PetFormViewModel(
      registerPet: app.registerPet,
      imageStorage: images.service,
      location: const PetLocation(latitude: -15.79, longitude: -47.88),
      now: systemNow,
    )
      ..setSpecies(PetSpecies.cat)
      ..setName('Mimi')
      ..setReference('Praça da Matriz');
    await images.queuePhoto();
    await form.pickPhoto(ImageOrigin.camera);
    expect(await form.save(), isTrue);
    final petId = form.id;
    final photo = form.photoFileName!;

    // 2) Aparece na lista e é achado pela busca e pelo filtro.
    final list = PetListViewModel(app.getPets);
    await list.load();
    expect(list.totalCount, 1);
    list.setSpecies(PetSpecies.dog);
    expect(list.state, isA<Empty<List<Pet>>>());
    list.setSpecies(PetSpecies.cat);
    list.setQuery('praca'); // sem acento, pela região
    expect((list.state as Loaded<List<Pet>>).data.single.displayName, 'Mimi');

    // 3) Sem cuidados: nada de "alimentado hoje" por suposição.
    final profile = app.profileOf(petId);
    await profile.load();
    expect(loadedProfile(profile).care.lastFeeding, isNull);

    // 4) Registra duas alimentações, a segunda retroativa (fora de ordem).
    final today = CareViewModel(
      petId: petId,
      type: CareType.feeding,
      addCareRecord: app.addCareRecord,
      now: systemNow,
    );
    expect(await today.save(), isTrue);
    final earlier = CareViewModel(
      petId: petId,
      type: CareType.feeding,
      addCareRecord: app.addCareRecord,
      now: systemNow,
    )..setDate(DateTime.now().subtract(const Duration(days: 2)));
    expect(await earlier.save(), isTrue);

    await profile.load();
    final care = loadedProfile(profile).care;
    expect(care.recordsOf(CareType.feeding), hasLength(2));
    expect(care.lastFeeding, today.savedRecord!.occurredAt); // a mais recente

    // 5) Editar o animal preserva o histórico de cuidados (RN-07).
    final edit = PetFormViewModel.edit(
      updatePet: app.updatePet,
      imageStorage: images.service,
      pet: loadedProfile(profile).pet,
      now: systemNow,
    )..setName('Mimi II');
    expect(await edit.save(), isTrue);
    expect(await app.count('care_records'), 2);

    // 6) "Fechar e reabrir o app": tudo continua lá.
    await app.db.close();
    app = await _App.open(dbPath, images);
    final reopened = app.profileOf(petId);
    await reopened.load();
    final restored = loadedProfile(reopened);
    expect(restored.pet.name, 'Mimi II');
    expect(restored.pet.photoFileName, photo);
    expect(images.service.fileFor(photo).existsSync(), isTrue);
    expect(restored.care.recordsOf(CareType.feeding), hasLength(2));
    expect(restored.care.lastFeeding, today.savedRecord!.occurredAt);

    // 7) Remover apaga o animal, o histórico (cascata) e a foto.
    expect(await reopened.delete(), isTrue);
    await app.db.close();
    app = await _App.open(dbPath, images);
    expect(await app.count('pets'), 0);
    expect(await app.count('care_records'), 0);
    expect(images.service.fileFor(photo).existsSync(), isFalse);
    await app.db.close();
  });

  test('saving the same form twice keeps a single pet after a restart',
      () async {
    var app = await _App.open(dbPath, images);
    final form = PetFormViewModel(
      registerPet: app.registerPet,
      imageStorage: images.service,
      location: const PetLocation(latitude: 1, longitude: 2),
      now: systemNow,
    )..setSpecies(PetSpecies.dog);

    await Future.wait([form.save(), form.save()]);
    await form.save();

    await app.db.close();
    app = await _App.open(dbPath, images);
    expect(await app.count('pets'), 1);
    await app.db.close();
  });

  test('the app never asks for or stores the volunteer location', () async {
    final app = await _App.open(dbPath, images);
    final columns = await app.db.db.rawQuery('PRAGMA table_info(pets)');
    final names = columns.map((c) => c['name']! as String).toSet();

    // Só a localização APROXIMADA do animal; nada de posição do usuário.
    expect(names, containsAll(['latitude', 'longitude', 'location_reference']));
    expect(
      names.where((n) => n.contains('user') || n.contains('volunteer')),
      isEmpty,
    );
    await app.db.close();
  });
}
