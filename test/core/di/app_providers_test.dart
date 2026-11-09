import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/di/app_providers.dart';
import 'package:mapa_do_pet/features/care/domain/repositories/care_repository.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:provider/provider.dart';

import '../../support/fake_image_picker.dart';
import '../../support/test_database.dart';

/// Regressão: o composition root precisa declarar cada dependência ANTES de
/// quem a lê. `GetPetProfile` lê `CareRepository`; quando este vinha depois,
/// abrir o perfil de um animal quebrava no aparelho com ProviderNotFoundError
/// (a leitura é preguiçosa, então só falha na primeira vez que alguém pede).
void main() {
  testWidgets('todo use case do app pode ser resolvido a partir da raiz',
      (tester) async {
    final database = await tester.runAsync(openTestDatabase);
    late BuildContext context;

    await tester.pumpWidget(
      MultiProvider(
        providers: buildAppProviders(
          database: database!,
          imageStorage: widgetTestImageStorage(),
        ),
        child: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ),
    );

    expect(context.read<GetPetProfile>(), isNotNull);
    expect(context.read<CareRepository>(), isNotNull);
    expect(context.read<AddCareRecord>(), isNotNull);
    expect(context.read<RegisterPet>(), isNotNull);
    expect(context.read<UpdatePet>(), isNotNull);
    expect(context.read<DeletePet>(), isNotNull);
    expect(context.read<GetPets>(), isNotNull);

    await tester.runAsync(database.close);
  });
}
