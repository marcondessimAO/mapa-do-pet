# UML · Diagrama de classes — Domínio

Camada `domain` (Dart puro). Convenções: `<<entity>>` entidade imutável · `<<value object>>` igualdade por valor · `<<enumeration>>` enum · `<<interface>>` contrato.

## 1. Entidades e value objects

```mermaid
classDiagram
  direction LR

  class Pet {
    <<entity>>
    +String id
    +PetSpecies species
    +String? name
    +PetSex sex
    +PetAgeGroup ageGroup
    +PetSize size
    +String? photoFileName
    +String? appearance
    +TriState isDocile
    +TriState isNeutered
    +TriState isPregnant
    +TriState hasLitter
    +int? litterSize
    +TriState hasInjuries
    +String? injuryDescription
    +String? knownDiseases
    +TriState rabiesVaccination
    +String? otherHealthInfo
    +String? notes
    +PetLocation location
    +DateTime createdAt
    +DateTime updatedAt
    +displayName String
    +copyWith() Pet
  }

  class PetLocation {
    <<value object>>
    +double latitude
    +double longitude
    +String? reference
    +copyWith() PetLocation
  }

  class CareRecord {
    <<sealed>>
    +String id
    +String petId
    +DateTime occurredAt
    +bool hasTime
    +String? responsibleName
    +String? notes
    +CareType type
  }
  class FeedingRecord
  class BathRecord
  class MedicationRecord {
    +String medicationName
  }
  class HealthRecord {
    +HealthRecordKind kind
    +String description
  }

  class CareSummary {
    <<value object>>
    +DateTime? lastFeeding
    +DateTime? lastBath
    +List~CareRecord~ records
    +recordsOf(CareType) List~CareRecord~
    +from(List~CareRecord~)$ CareSummary
  }

  Pet "1" *-- "1" PetLocation : location
  Pet "1" o-- "0..*" CareRecord : petId
  CareRecord <|-- FeedingRecord
  CareRecord <|-- BathRecord
  CareRecord <|-- MedicationRecord
  CareRecord <|-- HealthRecord
  CareSummary ..> CareRecord : agrega
```

## 2. Enumerações

```mermaid
classDiagram
  class PetSpecies {
    <<enumeration>>
    dog
    cat
  }
  class PetSex {
    <<enumeration>>
    male
    female
    unknown
  }
  class PetAgeGroup {
    <<enumeration>>
    puppy
    young
    adult
    senior
    unknown
  }
  class PetSize {
    <<enumeration>>
    small
    medium
    large
    unknown
  }
  class TriState {
    <<enumeration>>
    yes
    no
    unknown
  }
  class CareType {
    <<enumeration>>
    feeding
    bath
    medication
    health
  }
  class HealthRecordKind {
    <<enumeration>>
    consultation
    procedure
    vaccine
    injuryTreatment
    general
  }
```

> `TriState` é reutilizado por: `isDocile`, `isNeutered`, `isPregnant`, `hasLitter`, `hasInjuries`, `rabiesVaccination` (DRY — ver [plano §8.1](../plano-do-projeto.md#81-enums-valores-em-lowercamelcase-convenção-do-dart)).

## 3. Filtros (Strategy / Specification)

```mermaid
classDiagram
  class PetFilter {
    <<interface>>
    +matches(Pet) bool
  }
  class SpeciesFilter {
    +PetSpecies? species
    +matches(Pet) bool
  }
  class TextSearchFilter {
    +String query
    +matches(Pet) bool
  }
  class CompositePetFilter {
    +List~PetFilter~ filters
    +matches(Pet) bool
  }
  PetFilter <|.. SpeciesFilter
  PetFilter <|.. TextSearchFilter
  PetFilter <|.. CompositePetFilter
  CompositePetFilter o-- PetFilter : combina (E)
```

## 4. Resultado e falhas

```mermaid
classDiagram
  class Result~T~ { <<sealed>> }
  class Ok~T~ { +T value }
  class Err~T~ { +Failure failure }
  class Failure {
    <<sealed>>
    +String message
  }
  class ValidationFailure { +String? field }
  class NotFoundFailure
  class StorageFailure
  class ImageFailure
  Result <|-- Ok
  Result <|-- Err
  Err --> Failure
  Failure <|-- ValidationFailure
  Failure <|-- NotFoundFailure
  Failure <|-- StorageFailure
  Failure <|-- ImageFailure
```

## 5. Invariantes do domínio

| Invariante | Onde é garantida | Regra |
|------------|------------------|-------|
| Coordenadas válidas | Construtor de `PetLocation` (`assert`) + `RegisterPet` | RN-04 |
| Espécie presente | Tipo não anulável `PetSpecies` | RN-01 |
| Gestante ≠ sim para macho | `PetValidator` | RN-02 |
| `litterSize` só com ninhada = sim, 1–20 | `PetValidator` | RN-03 |
| Data do cuidado não futura | `AddCareRecord` (relógio injetado) | RN-05 |
| Medicamento com nome | `AddCareRecord` | RN-06 |
| Última alimentação/banho = maior `occurredAt` | `CareSummary.from` | RN-08 |
