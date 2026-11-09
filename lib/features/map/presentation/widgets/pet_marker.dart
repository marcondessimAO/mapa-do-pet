import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/enums/pet_species.dart';
import '../../../pets/presentation/labels/pet_labels.dart';

/// Marcador de um animal no mapa. Cão e gato se distinguem pela **forma** (não
/// só pela cor) e o marcador é descrito para leitores de tela.
class PetMarker extends StatelessWidget {
  const PetMarker({required this.pet, required this.onTap, super.key});

  /// Área de toque mínima recomendada (48 dp).
  static const double touchSize = 48;
  static const double _iconSize = 40;

  final Pet pet;
  final VoidCallback onTap;

  String get _asset => switch (pet.species) {
        PetSpecies.dog => 'assets/markers/dog.svg',
        PetSpecies.cat => 'assets/markers/cat.svg',
      };

  String get _description {
    final name = pet.name?.trim();
    final base = (name != null && name.isNotEmpty)
        ? '${pet.species.label} $name'
        : pet.displayName;
    final reference = pet.location.reference?.trim();
    return (reference != null && reference.isNotEmpty)
        ? '$base, $reference'
        : base;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _description,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: touchSize,
          height: touchSize,
          child: Center(
            child:
                SvgPicture.asset(_asset, width: _iconSize, height: _iconSize),
          ),
        ),
      ),
    );
  }
}
