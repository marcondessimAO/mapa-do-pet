import 'package:flutter/material.dart';

/// Bloco do perfil: título da seção e suas linhas de informação.
class ProfileSection extends StatelessWidget {
  const ProfileSection({required this.title, required this.rows, super.key});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

/// Uma linha "rótulo: valor". Valor ausente ou em branco vira "Não informado".
class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, this.value, super.key});

  static const String missing = 'Não informado';

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final text = value?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              (text == null || text.isEmpty) ? missing : text,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
