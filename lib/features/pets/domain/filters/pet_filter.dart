import '../../../../core/utils/text_normalizer.dart';
import '../entities/pet.dart';
import '../enums/pet_species.dart';

/// Critério de seleção de animais (Strategy / Specification).
/// Reutilizado pelo mapa e pela lista; combinável com [CompositePetFilter].
abstract interface class PetFilter {
  bool matches(Pet pet);
}

/// Filtra por espécie; `null` significa "Todos".
final class SpeciesFilter implements PetFilter {
  const SpeciesFilter(this.species);

  final PetSpecies? species;

  @override
  bool matches(Pet pet) => species == null || pet.species == species;
}

/// Busca por nome ou região, ignorando maiúsculas e acentos. Texto em branco
/// aceita todos.
final class TextSearchFilter implements PetFilter {
  const TextSearchFilter(this.query);

  final String query;

  @override
  bool matches(Pet pet) {
    final needle = TextNormalizer.normalize(query);
    if (needle.isEmpty) return true;
    final haystack = TextNormalizer.normalize(
        '${pet.name ?? ''} ${pet.location.reference ?? ''}');
    return haystack.contains(needle);
  }
}

/// Todos os filtros precisam aceitar (E lógico). Lista vazia aceita tudo.
final class CompositePetFilter implements PetFilter {
  const CompositePetFilter(this.filters);

  final List<PetFilter> filters;

  @override
  bool matches(Pet pet) => filters.every((filter) => filter.matches(pet));
}
