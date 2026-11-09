import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/presentation/labels/pet_labels.dart';
import '../../../pets/presentation/widgets/pet_card.dart';

/// Resumo de um animal ao tocar no marcador (RF-04). Aparece como um cartão
/// flutuante sobre o mapa, para o usuário continuar vendo onde o animal está.
class PetSummarySheet extends StatelessWidget {
  const PetSummarySheet({
    required this.pet,
    this.photoFile,
    this.onOpenProfile,
    this.onClose,
    super.key,
  });

  final Pet pet;
  final File? photoFile;

  /// Atalho para o perfil. `null` oculta o botão.
  final VoidCallback? onOpenProfile;

  /// Fecha o cartão. `null` oculta o botão de fechar.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = pet.detailsLine;
    final region = pet.regionLine;

    return Material(
      color: AppColors.branco,
      elevation: 6,
      shadowColor: AppColors.sombra,
      borderRadius: BorderRadius.circular(AppRadius.card + 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PetAvatar(file: photoFile, radius: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.displayName, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        SpeciesPill(species: pet.species),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(details, style: textTheme.bodyMedium),
                        ],
                        if (region != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 16, color: AppColors.marrom),
                              const SizedBox(width: 4),
                              Expanded(
                                child:
                                    Text(region, style: textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (onOpenProfile != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpenProfile,
                    icon: const Icon(Icons.arrow_forward),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Ver perfil'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
