# 04 · Padrões de projeto

Cada padrão aparece **onde resolve um problema real** do app. A tabela-resumo está no [plano §7](plano-do-projeto.md#7-padrões-de-projeto-adotados); aqui estão intenção, estrutura e código.

## Mapa rápido

| # | Padrão | Tipo | Onde |
|---|--------|------|------|
| 1 | Repository | Arquitetural | `PetRepository`, `CareRepository` |
| 2 | MVVM + Observer | Arquitetural / comportamental | ViewModels + `Provider` |
| 3 | Dependency Injection + Composition Root | Estrutural | `core/di/app_providers.dart` |
| 4 | Singleton | Criacional | `AppDatabase` |
| 5 | Factory Method | Criacional | `CareRecordMapper.fromMap`, `Enum.fromName` |
| 6 | Data Mapper / Adapter | Estrutural | `PetMapper`, `CareRecordMapper` |
| 7 | Strategy / Specification | Comportamental | `PetFilter` |
| 8 | Facade | Estrutural | `ImageStorageService` |
| 9 | Value Object | Domínio | `PetLocation`, `CareSummary` |
| 10 | Null Object | Comportamental | `unknown` / `TriState.unknown` |
| 11 | Polimorfismo (sealed class) | OO | `CareRecord` e subtipos |
| 12 | Use Case (Interactor) | Arquitetural | `RegisterPet`, `AddCareRecord`… |
| 13 | Result type | Tratamento de erro | `Result<T>` |

---

## 1. Repository
**Intenção:** esconder *como* os dados são guardados atrás de uma coleção de objetos de domínio.
**Problema:** sem isso, widgets chamariam SQL; trocar o armazenamento exigiria reescrever telas.

```dart
// domain — a interface não conhece SQLite
abstract interface class PetRepository {
  Future<Result<Pet>> add(Pet pet);
  Future<Result<Pet>> update(Pet pet);
  Future<Result<void>> delete(String id);
  Future<Result<Pet>> findById(String id);
  Future<Result<List<Pet>>> findAll();
}
// data — implementação concreta
final class PetRepositoryImpl implements PetRepository { /* usa PetLocalDataSource */ }
```
**Ganho:** testes usam um `FakePetRepository` em memória; um futuro backend entra aqui.

## 2. MVVM + Observer
**Intenção:** separar o *estado de apresentação* da árvore de widgets; a UI observa e reage.
`ChangeNotifier` é o *Subject*; `Consumer`/`context.watch` são os *Observers*.

```dart
class PetListViewModel extends ChangeNotifier {
  ViewState<List<Pet>> _state = const Loading();
  ViewState<List<Pet>> get state => _state;

  Future<void> load() async {
    _state = const Loading(); notifyListeners();
    final r = await _getPets(_filter);
    _state = switch (r) {
      Ok(:final value) when value.isEmpty => const Empty(),
      Ok(:final value) => Loaded(value),
      Err(:final failure) => Failed(failure),
    };
    notifyListeners();
  }
}
```

## 3. Dependency Injection + Composition Root
**Intenção:** objetos recebem suas dependências em vez de criá-las. Um único lugar (`buildAppProviders`) monta o grafo.
**Ganho:** nenhuma classe usa `PetRepositoryImpl()` diretamente; testes passam *fakes* no construtor.

## 4. Singleton
**Intenção:** garantir **uma** conexão SQLite.
**Cuidado:** não é um `static` global acessado de qualquer lugar — é criado uma vez em `main()` e **injetado**, o que preserva a testabilidade.

```dart
final class AppDatabase {
  AppDatabase._(this.db);
  final Database db;
  static AppDatabase? _instance;

  static Future<AppDatabase> open({String? path}) async =>
      _instance ??= AppDatabase._(await _openDatabase(path));
}
```

## 5. Factory Method
**Intenção:** decidir qual subtipo criar sem que o chamador conheça as classes concretas.

```dart
CareRecord careRecordFromMap(Map<String, Object?> m) =>
  switch (CareType.fromName(m['type'] as String?)) {
    CareType.feeding    => FeedingRecord.fromMap(m),
    CareType.bath       => BathRecord.fromMap(m),
    CareType.medication => MedicationRecord.fromMap(m),
    CareType.health     => HealthRecord.fromMap(m),
  };
```
`fromName` dos enums é outra fábrica: converte texto em enum com **valor padrão `unknown`** (nunca lança).

## 6. Data Mapper / Adapter
**Intenção:** traduzir entre o modelo de domínio e o formato do banco (`Map<String, Object?>`).
**Ganho:** o domínio não conhece nomes de colunas, nem `TEXT` ISO-8601, nem `0/1` para booleanos.

## 7. Strategy / Specification
**Intenção:** encapsular critérios de seleção como objetos intercambiáveis e combináveis.

```dart
abstract interface class PetFilter { bool matches(Pet pet); }

final class SpeciesFilter implements PetFilter {
  const SpeciesFilter(this.species);
  final PetSpecies? species;            // null = Todos
  @override bool matches(Pet p) => species == null || p.species == species;
}

final class CompositePetFilter implements PetFilter {
  const CompositePetFilter(this.filters);
  final List<PetFilter> filters;
  @override bool matches(Pet p) => filters.every((f) => f.matches(p));
}
```
**Ganho:** mapa e lista usam a mesma regra; cada filtro é testável isoladamente; novo filtro = nova classe (aberto/fechado).

## 8. Facade
**Intenção:** uma interface simples sobre subsistemas complexos.
`ImageStorageService.pick(source)` esconde `image_picker`, `path_provider`, geração de UUID, cópia e redução da imagem. A UI só vê `Future<Result<String?>>`.

## 9. Value Object
**Intenção:** objeto definido por seus valores, imutável e sempre válido.

```dart
final class PetLocation {
  const PetLocation({required this.latitude, required this.longitude, this.reference})
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);
  final double latitude, longitude;
  final String? reference;
  @override bool operator ==(Object o) => o is PetLocation &&
      o.latitude == latitude && o.longitude == longitude && o.reference == reference;
  @override int get hashCode => Object.hash(latitude, longitude, reference);
}
```

## 10. Null Object
**Intenção:** em vez de `null`, um objeto "neutro" com comportamento previsível.
`TriState.unknown`, `PetSex.unknown`… evitam `if (x == null)` espalhado: a UI sempre tem um valor para exibir ("Não sei").

## 11. Polimorfismo com `sealed class`
**Intenção:** hierarquia fechada; o compilador exige tratar todos os subtipos.

```dart
String describe(CareRecord r) => switch (r) {
  FeedingRecord()   => 'Alimentação',
  BathRecord()      => 'Banho',
  MedicationRecord(:final medicationName) => 'Medicamento: $medicationName',
  HealthRecord(:final kind)               => 'Saúde (${kind.name})',
};   // adicionar um subtipo novo quebra a compilação aqui — de propósito
```

## 12. Use Case (Interactor)
**Intenção:** uma classe por *intenção do usuário*, onde vivem as regras.

```dart
final class AddCareRecord {
  AddCareRecord(this._repo, this._now);
  final CareRepository _repo;
  final DateTime Function() _now;

  Future<Result<CareRecord>> call(CareRecord r) async {
    if (r.occurredAt.isAfter(_now())) {
      return const Err(ValidationFailure('A data não pode ser futura', field: 'occurredAt'));
    }
    if (r is MedicationRecord && r.medicationName.trim().isEmpty) {
      return const Err(ValidationFailure('Informe o nome do medicamento', field: 'medicationName'));
    }
    return _repo.add(r);
  }
}
```

## 13. Result type
**Intenção:** tornar o erro parte do tipo de retorno. Substitui `try/catch` espalhado e garante, via `switch` exaustivo, que a UI trate o caso de falha.

---

## Padrões considerados e **não** adotados

| Padrão / ferramenta | Motivo |
|---------------------|--------|
| Bloc / Riverpod | `Provider` + `ChangeNotifier` cobre 5 ViewModels; menos código e curva menor. Ver [ADR-002](09-decisoes-arquitetura-adr.md). |
| `get_it` (Service Locator) | Esconde dependências; `Provider` já injeta. |
| Builder | `copyWith` resolve a construção incremental. |
| Abstract Factory | Não há famílias de objetos relacionados. |
| `freezed` / geração de código | Menos "mágica" e menos dependências; o ganho não compensa neste tamanho. |
| Observer manual (`Stream`) | `ChangeNotifier` basta; `Stream` fica como evolução. |
