import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/map/presentation/widgets/pet_summary_sheet.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';

import '../../../support/pet_builder.dart';

Widget host(PetSummarySheet sheet) => MaterialApp(home: Scaffold(body: sheet));

void main() {
  testWidgets('shows name, species, known details and the region (RF-04)',
      (tester) async {
    final pet = buildPet(
      name: 'Caramelo',
      sex: PetSex.male,
      reference: 'Praça da Matriz',
    ).copyWith(ageGroup: PetAgeGroup.adult);

    await tester.pumpWidget(host(PetSummarySheet(pet: pet)));

    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Cachorro'), findsOneWidget);
    expect(find.text('Macho · Adulto'), findsOneWidget);
    expect(find.text('Praça da Matriz'), findsOneWidget);
  });

  testWidgets('omits unknown details', (tester) async {
    await tester.pumpWidget(host(PetSummarySheet(pet: buildPet())));

    expect(find.text('Cachorro sem nome'), findsOneWidget);
    expect(find.textContaining('Não sei'), findsNothing);
  });

  testWidgets('has no profile button until the profile screen exists',
      (tester) async {
    await tester.pumpWidget(host(PetSummarySheet(pet: buildPet())));

    expect(find.text('Ver perfil'), findsNothing);
  });

  testWidgets('shows a profile button that calls back when provided',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(host(PetSummarySheet(
      pet: buildPet(),
      onOpenProfile: () => opened++,
    )));

    await tester.tap(find.text('Ver perfil'));

    expect(opened, 1);
  });
}
