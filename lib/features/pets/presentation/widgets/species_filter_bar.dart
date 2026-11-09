import 'package:flutter/material.dart';

import '../../domain/enums/pet_species.dart';
import '../labels/pet_labels.dart';

/// Filtro Todos · Cachorros · Gatos (`null` = Todos). Usado na lista e no mapa.
class SpeciesFilterBar extends StatelessWidget {
  const SpeciesFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final PetSpecies? selected;
  final ValueChanged<PetSpecies?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PetSpecies?>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment<PetSpecies?>(value: null, label: Text('Todos')),
          for (final species in PetSpecies.values)
            ButtonSegment<PetSpecies?>(
              value: species,
              label: Text(species.pluralLabel),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
