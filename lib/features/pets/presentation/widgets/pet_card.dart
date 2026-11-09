import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';
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
      color: AppColors.areia,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PetAvatar(file: photoFile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.displayName, style: textTheme.titleMedium),
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
        ),
      ),
    );
  }
}

/// Foto redonda do animal; sem foto, mostra uma patinha.
class PetAvatar extends StatelessWidget {
  const PetAvatar({this.file, this.radius = 28, super.key});

  final File? file;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = file;
    final hasPhoto = photo != null && photo.existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.branco,
      backgroundImage: hasPhoto ? FileImage(photo) : null,
      child: hasPhoto ? null : const Icon(Icons.pets, color: AppColors.marrom),
    );
  }
}
