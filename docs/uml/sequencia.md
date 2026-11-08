# UML · Diagramas de sequência

## 1. Inicialização do app

```mermaid
sequenceDiagram
  autonumber
  participant M as main()
  participant DB as AppDatabase
  participant SQ as SQLite
  participant A as MapaDoPetApp
  participant P as MultiProvider

  M->>DB: open()
  DB->>SQ: openDatabase(version, onConfigure, onCreate, onUpgrade)
  SQ-->>DB: PRAGMA foreign_keys = ON e migrações aplicadas
  DB-->>M: AppDatabase
  M->>A: runApp(database)
  A->>P: buildAppProviders(database)
  P-->>A: repositórios, use cases e ViewModels prontos
  A-->>M: HomeShell na aba Mapa
```

## 2. Cadastrar animal pelo mapa (UC-03)

```mermaid
sequenceDiagram
  autonumber
  actor V as Voluntário
  participant MP as MapPage
  participant CS as ConfirmRegisterSheet
  participant RP as PetRegistrationPage
  participant VM as PetFormViewModel
  participant UC as RegisterPet
  participant R as PetRepository
  participant DS as PetLocalDataSource
  participant DB as SQLite
  participant MV as MapViewModel

  V->>MP: toca em área livre do mapa
  MP->>CS: mostra "Cadastrar animal aqui?"
  V->>CS: confirma
  CS->>RP: abre formulário com LatLng
  RP->>VM: cria (id = UUID, localização inicial)
  V->>RP: escolhe espécie e preenche campos
  V->>RP: toca em "Finalizar cadastro"
  RP->>VM: save()
  alt já está salvando
    VM-->>RP: ignora (RN-09)
  else
    VM->>VM: isSaving = true
    VM->>UC: call(pet)
    UC->>UC: valida RN-01 a RN-04, RN-13
    alt inválido
      UC-->>VM: Err(ValidationFailure)
      VM-->>RP: mostra erro no campo
    else válido
      UC->>R: add(pet)
      R->>DS: insert(PetMapper.toMap(pet))
      DS->>DB: INSERT OR IGNORE INTO pets
      DB-->>DS: ok
      DS-->>R: ok
      R-->>UC: Ok(pet)
      UC-->>VM: Ok(pet)
      VM-->>RP: sucesso
      RP->>MP: pop(pet)
      MP->>MV: load()
      MV-->>MP: novo marcador exibido
    end
    VM->>VM: isSaving = false
  end
```

## 3. Registrar cuidado e recalcular o destaque (UC-09)

```mermaid
sequenceDiagram
  autonumber
  actor V as Voluntário
  participant PP as PetProfilePage
  participant SH as CareRecordFormSheet
  participant CV as CareViewModel
  participant UC as AddCareRecord
  participant CR as CareRepository
  participant PV as PetProfileViewModel
  participant GS as GetCareSummary

  V->>PP: toca em "Adicionar registro" e escolhe o tipo
  PP->>SH: abre folha (id = UUID, data atual)
  V->>SH: ajusta data, responsável, observação
  V->>SH: toca em "Salvar"
  SH->>CV: add(record)
  CV->>UC: call(record)
  UC->>UC: data não futura (RN-05), medicamento com nome (RN-06)
  alt inválido
    UC-->>CV: Err(ValidationFailure)
    CV-->>SH: mostra mensagem
  else válido
    UC->>CR: add(record)
    CR-->>UC: Ok (INSERT OR IGNORE, idempotente)
    UC-->>CV: Ok
    CV-->>SH: fecha a folha
    SH->>PV: load()
    PV->>GS: call(petId)
    GS->>CR: listByPet(petId)
    CR-->>GS: registros
    GS-->>PV: CareSummary.from(registros)
    PV-->>PP: última alimentação/banho = maior occurredAt (RN-08)
  end
```

## 4. Atualizar animal preservando o histórico (UC-08)

```mermaid
sequenceDiagram
  autonumber
  actor V as Voluntário
  participant EP as PetEditPage
  participant VM as PetFormViewModel
  participant UC as UpdatePet
  participant PR as PetRepository
  participant IS as ImageStorageService

  V->>EP: toca em "Atualizar informações"
  EP->>VM: carrega pet atual
  V->>EP: altera dados e troca a foto
  EP->>VM: save()
  VM->>IS: pick(source) e copia a nova foto
  IS-->>VM: novo nome de arquivo
  VM->>UC: call(pet.copyWith(...))
  UC->>PR: update(pet com updatedAt = agora)
  Note over PR: UPDATE só na tabela pets. care_records NÃO é tocada (RN-07)
  PR-->>UC: Ok
  UC-->>VM: Ok
  VM->>IS: delete(fotoAntiga) após sucesso
  VM-->>EP: sucesso e volta ao perfil
```

## 5. Buscar e filtrar na lista (UC-06)

```mermaid
sequenceDiagram
  autonumber
  actor V as Voluntário
  participant LP as PetListPage
  participant VM as PetListViewModel
  participant UC as GetPets
  participant R as PetRepository

  V->>LP: digita "praça" e escolhe "Gatos"
  LP->>VM: setQuery("praça") e setSpecies(cat)
  VM->>UC: call(CompositePetFilter(SpeciesFilter, TextSearchFilter))
  UC->>R: findAll()
  R-->>UC: Ok(todos os pets)
  UC->>UC: aplica filtro (texto normalizado, sem acento)
  UC-->>VM: Ok(lista filtrada)
  alt lista vazia
    VM-->>LP: Empty
  else
    VM-->>LP: Loaded(lista)
  end
```

## 6. Escolher foto

```mermaid
sequenceDiagram
  autonumber
  actor V as Voluntário
  participant F as PetRegistrationPage
  participant VM as PetFormViewModel
  participant IS as ImageStorageService
  participant SO as Câmera / Galeria

  V->>F: toca em "Adicionar foto"
  F->>VM: pickPhoto(camera ou galeria)
  VM->>IS: pick(source)
  IS->>SO: solicita imagem (permissão sob demanda)
  alt usuário cancela ou nega
    SO-->>IS: nada
    IS-->>VM: Ok(null)
  else escolhe
    SO-->>IS: arquivo temporário
    IS->>IS: copia para pet_photos/uuid.jpg
    IS-->>VM: Ok(nome do arquivo)
    VM-->>F: pré-visualização
  end
```
