import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/presentation/widgets/pet_card.dart';

import '../../../support/pet_builder.dart';

Widget host(PetCard card) => MaterialApp(home: Scaffold(body: card));

void main() {
  testWidgets('shows name, species, known details and the region',
      (tester) async {
    final pet = buildPet(
      name: 'Caramelo',
      sex: PetSex.male,
      reference: 'Praça da Matriz',
    ).copyWith(ageGroup: PetAgeGroup.adult);

    await tester.pumpWidget(host(PetCard(pet: pet)));

    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Cachorro'), findsOneWidget);
    expect(find.text('Macho · Adulto'), findsOneWidget);
    expect(find.text('Praça da Matriz'), findsOneWidget);
  });

  testWidgets('omits unknown details and uses the default name',
      (tester) async {
    final pet = buildPet(species: PetSpecies.cat);

    await tester.pumpWidget(host(PetCard(pet: pet)));

    expect(find.text('Gato sem nome'), findsOneWidget);
    expect(find.text('Gato'), findsOneWidget);
    expect(find.textContaining('Não sei'), findsNothing);
  });

  testWidgets('shows a paw placeholder when there is no photo', (tester) async {
    await tester.pumpWidget(host(PetCard(pet: buildPet())));

    expect(find.byIcon(Icons.pets), findsOneWidget);
  });

  testWidgets('calls onTap when pressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(PetCard(pet: buildPet(name: 'Rex'), onTap: () => taps++)),
    );

    await tester.tap(find.text('Rex'));

    expect(taps, 1);
  });
}
