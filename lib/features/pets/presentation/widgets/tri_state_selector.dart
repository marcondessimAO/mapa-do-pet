import 'package:flutter/material.dart';

import '../../domain/enums/tri_state.dart';
import '../labels/pet_labels.dart';

/// Pergunta sim / não / não sei. Reutilizado por dócil, castrado, gestante,
/// ninhada e ferimentos (um único componente para um único conceito).
class TriStateSelector extends StatelessWidget {
  const TriStateSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TriState value;
  final ValueChanged<TriState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TriState>(
            showSelectedIcon: false,
            segments: [
              for (final option in TriState.values)
                ButtonSegment<TriState>(
                    value: option, label: Text(option.label)),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ],
    );
  }
}
