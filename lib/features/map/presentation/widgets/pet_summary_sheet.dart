import 'dart:io';

import 'package:flutter/material.dart';

import '../../../pets/domain/entities/pet.dart';
import '../../../pets/presentation/labels/pet_labels.dart';
import '../../../pets/presentation/widgets/pet_card.dart';

/// Resumo de um animal ao tocar no marcador (RF-04).
class PetSummarySheet extends StatelessWidget {
  const PetSummarySheet({
    required this.pet,
    this.photoFile,
    this.onOpenProfile,
    super.key,
  });

  final Pet pet;
  final File? photoFile;

  /// Atalho para o perfil. `null` oculta o botão (o perfil chega na Fase 4).
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = pet.detailsLine;
    final region = pet.regionLine;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PetAvatar(file: photoFile, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.displayName, style: textTheme.titleLarge),
                      Text(pet.species.label, style: textTheme.bodyMedium),
                      if (details.isNotEmpty)
                        Text(details, style: textTheme.bodyMedium),
                      if (region != null)
                        Text(region, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (onOpenProfile != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpenProfile,
                  child: const Text('Ver perfil'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
