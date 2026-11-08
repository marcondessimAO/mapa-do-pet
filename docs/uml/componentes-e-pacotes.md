# UML · Componentes, pacotes e implantação

## 1. Diagrama de pacotes

Setas = "depende de". Nenhuma seta sai de `domain` para fora dele ou de `core/error`.

```mermaid
flowchart TB
  subgraph APP["lib/"]
    MAIN["main.dart · app.dart"]
    subgraph CORE["core/"]
      DI["di"]
      CDB["database"]
      CERR["error"]
      CTH["theme"]
      CCT["constants"]
      CSV["services"]
      CUT["utils"]
      CWG["widgets"]
    end
    subgraph F["features/"]
      subgraph PETS["pets/"]
        PD["domain"]
        PDA["data"]
        PP["presentation"]
      end
      subgraph CARE["care/"]
        CD["domain"]
        CDA["data"]
        CP["presentation"]
      end
      MAPF["map/presentation"]
      INFOF["info/presentation"]
      SHELL["shell/presentation"]
    end
  end

  MAIN --> DI
  MAIN --> SHELL
  SHELL --> MAPF
  SHELL --> PP
  SHELL --> INFOF
  PP --> PD
  PP --> CP
  CP --> CD
  MAPF --> PD
  PDA --> PD
  PDA --> CDB
  CDA --> CD
  CDA --> CDB
  PD --> CERR
  CD --> CERR
  CD --> PD
  DI --> PDA
  DI --> CDA
  PP --> CTH
  PP --> CWG
```

## 2. Diagrama de componentes

```mermaid
flowchart LR
  subgraph UI["Camada de apresentação"]
    PAGES["Pages / Widgets"]
    VMS["ViewModels"]
  end
  subgraph BIZ["Camada de domínio"]
    USECASES["Use Cases"]
    CONTRACTS["Interfaces de repositório"]
  end
  subgraph INF["Camada de dados / infraestrutura"]
    REPOS["Repositórios"]
    SQLITE["sqflite"]
    IMG["image_picker + path_provider"]
    MAPLIB["flutter_map"]
  end

  PAGES -- "usa" --> VMS
  VMS -- "chama" --> USECASES
  USECASES -- "depende de" --> CONTRACTS
  REPOS -. "realiza" .-> CONTRACTS
  REPOS -- "usa" --> SQLITE
  VMS -- "usa (Facade)" --> IMG
  PAGES -- "renderiza" --> MAPLIB
```

| Componente | Tipo | Provê | Requer |
|------------|------|-------|--------|
| `flutter_map` + `latlong2` | Biblioteca | Mapa interativo e coordenadas | Internet (tiles) |
| `sqflite` | Plugin nativo | Persistência SQLite | — |
| `image_picker` | Plugin nativo | Câmera/galeria | Permissões sob demanda |
| `path_provider` | Plugin nativo | Pasta de documentos | — |
| `provider` | Biblioteca | DI e observação de estado | — |
| `uuid` | Biblioteca | IDs | — |

## 3. Diagrama de implantação

```mermaid
flowchart TB
  subgraph PHONE["Smartphone Android / iOS"]
    subgraph PROC["Processo do app (Flutter engine + Dart VM)"]
      ART["mapa_do_pet (código Dart)"]
    end
    subgraph STORE["Armazenamento privado do app"]
      F1[("mapa_do_pet.db")]
      F2[["pet_photos/*.jpg"]]
    end
    OSF["Câmera / Galeria"]
  end
  CLOUD(["tile.openstreetmap.org (HTTPS)"])

  ART --> F1
  ART --> F2
  ART --> OSF
  ART -->|"somente leitura de tiles"| CLOUD
```

Não há servidor próprio, banco remoto nem contas de usuário no MVP.
