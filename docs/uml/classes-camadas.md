# UML · Diagrama de classes — Camadas

Mostra como casos de uso, repositórios, fontes de dados e ViewModels se ligam. Entidades: ver [classes-dominio.md](classes-dominio.md).

## 1. Feature `pets`

```mermaid
classDiagram
  direction TB

  %% Presentation
  class PetListViewModel {
    <<ChangeNotifier>>
    +ViewState state
    +PetSpecies? species
    +String query
    +load()
    +setSpecies(PetSpecies?)
    +setQuery(String)
  }
  class PetFormViewModel {
    <<ChangeNotifier>>
    +bool isSaving
    +Map errors
    +setSpecies(PetSpecies)
    +setLocation(LatLng)
    +pickPhoto(source)
    +save() Future
  }
  class PetProfileViewModel {
    <<ChangeNotifier>>
    +ViewState state
    +load()
    +delete() Future
  }

  %% Domain
  class GetPets { +call(PetFilter) Future~Result~List~Pet~~~ }
  class RegisterPet { +call(Pet) Future~Result~Pet~~ }
  class UpdatePet { +call(Pet) Future~Result~Pet~~ }
  class DeletePet { +call(String id) Future~Result~void~~ }
  class GetPetProfile { +call(String id) Future~Result~PetProfile~~ }
  class PetRepository {
    <<interface>>
    +add(Pet) Future~Result~Pet~~
    +update(Pet) Future~Result~Pet~~
    +delete(String) Future~Result~void~~
    +findById(String) Future~Result~Pet~~
    +findAll() Future~Result~List~Pet~~~
  }

  %% Data
  class PetRepositoryImpl
  class PetLocalDataSource {
    +insert(Map)
    +update(Map)
    +delete(String)
    +query() List~Map~
  }
  class PetMapper {
    +toMap(Pet) Map$
    +fromMap(Map) Pet$
  }
  class AppDatabase {
    <<singleton>>
    +open()$ AppDatabase
    +Database db
  }

  PetListViewModel ..> GetPets
  PetFormViewModel ..> RegisterPet
  PetFormViewModel ..> UpdatePet
  PetProfileViewModel ..> GetPetProfile
  PetProfileViewModel ..> DeletePet
  GetPets ..> PetRepository
  RegisterPet ..> PetRepository
  UpdatePet ..> PetRepository
  DeletePet ..> PetRepository
  GetPetProfile ..> PetRepository
  GetPetProfile ..> CareRepository
  PetRepository <|.. PetRepositoryImpl
  PetRepositoryImpl --> PetLocalDataSource
  PetRepositoryImpl ..> PetMapper
  PetLocalDataSource --> AppDatabase
```

## 2. Feature `care`

```mermaid
classDiagram
  direction TB
  class CareViewModel {
    <<ChangeNotifier>>
    +bool isSaving
    +add(CareRecord) Future
  }
  class AddCareRecord {
    +call(CareRecord) Future~Result~CareRecord~~
  }
  class GetCareSummary {
    +call(String petId) Future~Result~CareSummary~~
  }
  class CareRepository {
    <<interface>>
    +add(CareRecord) Future~Result~CareRecord~~
    +listByPet(String) Future~Result~List~CareRecord~~~
  }
  class CareRepositoryImpl
  class CareLocalDataSource
  class CareRecordMapper {
    +toMap(CareRecord) Map$
    +fromMap(Map) CareRecord$
  }

  CareViewModel ..> AddCareRecord
  AddCareRecord ..> CareRepository
  GetCareSummary ..> CareRepository
  CareRepository <|.. CareRepositoryImpl
  CareRepositoryImpl --> CareLocalDataSource
  CareRepositoryImpl ..> CareRecordMapper
```

> `CareRecordMapper.fromMap` é um **Factory Method**: lê a coluna `type` e devolve `FeedingRecord`, `BathRecord`, `MedicationRecord` ou `HealthRecord`.

## 3. Serviços compartilhados (`core`)

```mermaid
classDiagram
  class ImageStorageService {
    <<facade>>
    +pick(ImageSource) Future~Result~String~~
    +delete(String fileName) Future
    +resolve(String fileName) Future~File~
  }
  class AppLogger { +error(Object, StackTrace?)$ }
  class AppConstants {
    +LatLng defaultMapCenter$
    +String tileUrlTemplate$
    +String userAgentPackageName$
  }
  ImageStorageService ..> ImagePicker : usa
  ImageStorageService ..> PathProvider : usa
```

## 4. Regra de dependência (resumo)

| De → Para | Permitido? |
|-----------|:---------:|
| ViewModel → Use Case | ✅ |
| Use Case → Interface de repositório | ✅ |
| Repositório (impl) → Interface (domain) | ✅ |
| ViewModel → Repositório (impl) | ❌ |
| Domain → `sqflite` / `flutter` | ❌ |
| Page → `AppDatabase` | ❌ |
