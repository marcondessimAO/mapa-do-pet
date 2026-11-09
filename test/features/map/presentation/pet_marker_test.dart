import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/map/presentation/widgets/pet_marker.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';

import '../../../support/pet_builder.dart';

Widget host(PetMarker marker) =>
    MaterialApp(home: Scaffold(body: Center(child: marker)));

String assetOf(WidgetTester tester) {
  final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
  return (svg.bytesLoader as SvgAssetLoader).assetName;
}

void main() {
  testWidgets('a dog uses the dog marker and a cat uses the cat marker',
      (tester) async {
    await tester.pumpWidget(host(PetMarker(pet: buildPet(), onTap: () {})));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/markers/dog.svg');

    await tester.pumpWidget(host(PetMarker(
      pet: buildPet(species: PetSpecies.cat),
      onTap: () {},
    )));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/markers/cat.svg');
  });

  testWidgets('has a touch target of at least 48x48', (tester) async {
    await tester.pumpWidget(host(PetMarker(pet: buildPet(), onTap: () {})));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(PetMarker));

    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('describes the pet for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(PetMarker(
      pet: buildPet(name: 'Caramelo', reference: 'Praça da Matriz'),
      onTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Cachorro Caramelo, Praça da Matriz'),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('an unnamed pet is described by its default name',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(PetMarker(
      pet: buildPet(species: PetSpecies.cat),
      onTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Gato sem nome'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('calls onTap when pressed', (tester) async {
    var taps = 0;
    await tester
        .pumpWidget(host(PetMarker(pet: buildPet(), onTap: () => taps++)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PetMarker));

    expect(taps, 1);
  });
}
