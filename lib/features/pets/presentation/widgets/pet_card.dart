import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet.dart';
import '../../domain/enums/pet_species.dart';
import '../labels/pet_labels.dart';

/// Cartão de um animal na lista: foto, nome, espécie e só os dados conhecidos.
class PetCard extends StatelessWidget {
  const PetCard({required this.pet, this.photoFile, this.onTap, super.key});

  final Pet pet;
  final File? photoFile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = pet.detailsLine;
    final region = pet.regionLine;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PetAvatar(file: photoFile, radius: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.displayName, style: textTheme.titleMedium),
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
                            child: Text(region, style: textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.marrom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selo com o rótulo da espécie. O texto, e não só a cor, diferencia cão e gato.
class SpeciesPill extends StatelessWidget {
  const SpeciesPill({required this.species, super.key});

  final PetSpecies species;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.areia,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          species.label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Foto redonda do animal, com anel claro e sombra; sem foto, mostra uma patinha.
class PetAvatar extends StatelessWidget {
  const PetAvatar({this.file, this.radius = 28, super.key});

  final File? file;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = file;
    final hasPhoto = photo != null && photo.existsSync();
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.sombra,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius + 3,
        backgroundColor: AppColors.branco,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.areia,
          backgroundImage: hasPhoto ? FileImage(photo) : null,
          child: hasPhoto
              ? null
              : Icon(Icons.pets, color: AppColors.marrom, size: radius * 0.9),
        ),
      ),
    );
  }
}
