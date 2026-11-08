import '../../../care/domain/entities/care_summary.dart';
import 'pet.dart';

/// Tudo o que o perfil mostra: o animal e o resumo dos seus cuidados.
///
/// O perfil é a única tela agregadora que junta `pets` e `care` (exceção
/// documentada na arquitetura); `pets` nunca depende de `care` em outro lugar.
final class PetProfile {
  const PetProfile({required this.pet, required this.care});

  final Pet pet;
  final CareSummary care;
}
