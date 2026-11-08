# UML · Atividades e estados

## 1. Diagrama de atividades — cadastrar animal

```mermaid
flowchart TD
  A([Início]) --> B["Toca em área livre do mapa"]
  B --> C{"Confirma<br/>Cadastrar aqui?"}
  C -- Não --> Z([Fim - nada alterado])
  C -- Sim --> D["Abre formulário com coordenadas e novo id"]
  D --> E["Escolhe espécie"]
  E --> F{"Quer ajustar<br/>o local?"}
  F -- Sim --> G["Reposiciona o ponto no mini-mapa"] --> H
  F -- Não --> H{"Quer adicionar<br/>foto?"}
  H -- Sim --> I["Câmera ou galeria"] --> J
  H -- Não --> J["Preenche campos opcionais"]
  J --> K["Toca em Finalizar cadastro"]
  K --> L{"Espécie<br/>escolhida?"}
  L -- Não --> M["Destaca o campo e mostra erro"] --> E
  L -- Sim --> N{"Regras RN-02,<br/>RN-03, RN-04 ok?"}
  N -- Não --> M
  N -- Sim --> O["Botão desabilitado e grava no SQLite"]
  O --> P{"Gravou?"}
  P -- Não --> Q["Mantém formulário e mostra erro"] --> K
  P -- Sim --> R["Mostra confirmação e volta ao mapa"]
  R --> S([Fim - marcador visível])
```

## 2. Diagrama de atividades — registrar cuidado

```mermaid
flowchart TD
  A([Início]) --> B["Abre perfil do animal"]
  B --> C["Adicionar registro e escolhe tipo"]
  C --> D["Sugere data e hora atuais e gera id"]
  D --> E["Ajusta data, responsável e observação"]
  E --> F{"Tipo é<br/>medicamento?"}
  F -- Sim --> G["Informa nome do medicamento"] --> H
  F -- Não --> H{"Tipo é saúde?"}
  H -- Sim --> I["Escolhe o tipo de ocorrência"] --> J
  H -- Não --> J["Toca em Salvar"]
  J --> K{"Data futura?"}
  K -- Sim --> L["Erro: data não pode ser futura"] --> E
  K -- Não --> M{"Medicamento<br/>sem nome?"}
  M -- Sim --> N["Erro: informe o medicamento"] --> G
  M -- Não --> O["INSERT OR IGNORE - histórico anterior intacto"]
  O --> P["Recalcula última alimentação e banho"]
  P --> Q([Fim])
```

## 3. Navegação entre telas

```mermaid
flowchart LR
  subgraph SHELL["HomeShell (NavigationBar)"]
    MAP["Mapa"]
    LIST["Animais"]
    INFO["Informações"]
  end
  MAP -->|"toque em área livre + confirmar"| REG["Cadastro de animal"]
  MAP -->|"toque no marcador"| SUM["Resumo (bottom sheet)"]
  SUM -->|"Ver perfil"| PROF
  LIST -->|"toque no cartão"| PROF["Perfil do animal"]
  REG -->|"salvar"| MAP
  PROF -->|"Atualizar informações"| EDIT["Edição do animal"]
  EDIT -->|"salvar"| PROF
  PROF -->|"Adicionar registro"| CARE["Folha de registro de cuidado"]
  CARE -->|"salvar"| PROF
  PROF -->|"Remover animal + confirmar"| LIST
  MAP --- LIST
  LIST --- INFO
```

## 4. Máquinas de estados

### 4.1 Estado de carregamento de uma tela (`ViewState`)

```mermaid
stateDiagram-v2
  [*] --> Loading : load()
  Loading --> Loaded : Ok com itens
  Loading --> Empty : Ok sem itens
  Loading --> Failed : Err
  Loaded --> Loading : recarregar
  Empty --> Loading : recarregar
  Failed --> Loading : tentar novamente
```

### 4.2 Salvamento de formulário (anti-duplicidade, RN-09)

```mermaid
stateDiagram-v2
  [*] --> Editando
  Editando --> Validando : save()
  Validando --> Editando : inválido (mostra erros)
  Validando --> Salvando : válido (isSaving = true)
  Salvando --> Salvo : Ok
  Salvando --> Editando : Err (mantém dados)
  Salvando --> Salvando : save() repetido é ignorado
  Salvo --> [*]
```

### 4.3 Ciclo de vida de um animal

```mermaid
stateDiagram-v2
  [*] --> Cadastrado : RegisterPet
  Cadastrado --> Cadastrado : UpdatePet (histórico preservado)
  Cadastrado --> Cadastrado : AddCareRecord (append-only)
  Cadastrado --> Removido : DeletePet (cascata nos registros)
  Removido --> [*]
```

> Não existe estado "adotado": todos os animais são considerados disponíveis para adoção (plano §1.4).
