import 'package:flutter/material.dart';

/// Pergunta antes de abrir o cadastro, para evitar cadastros por toque acidental
/// (RF-03). Devolve `true` ao confirmar e `false` ao cancelar.
class ConfirmRegisterSheet extends StatelessWidget {
  const ConfirmRegisterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cadastrar animal aqui?', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Vamos marcar este ponto como a localização aproximada do '
              'animal. Você poderá ajustá-lo antes de salvar.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cadastrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
