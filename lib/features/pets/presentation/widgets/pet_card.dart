import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';
import '../../domain/enums/pet_age_group.dart';
import '../../domain/enums/pet_sex.dart';
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
    final details = [
      if (pet.sex != PetSex.unknown) pet.sex.label,
      if (pet.ageGroup != PetAgeGroup.unknown) pet.ageGroup.label,
    ].join(' · ');
    final reference = pet.location.reference?.trim();

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
              _Avatar(file: photoFile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.displayName, style: textTheme.titleMedium),
                    Text(pet.species.label, style: textTheme.bodyMedium),
                    if (details.isNotEmpty)
                      Text(details, style: textTheme.bodyMedium),
                    if (reference != null && reference.isNotEmpty)
                      Text(reference, style: textTheme.bodyMedium),
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.file});

  final File? file;

  @override
  Widget build(BuildContext context) {
    final photo = file;
    final hasPhoto = photo != null && photo.existsSync();
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.branco,
      backgroundImage: hasPhoto ? FileImage(photo) : null,
      child: hasPhoto ? null : const Icon(Icons.pets, color: AppColors.marrom),
    );
  }
}
