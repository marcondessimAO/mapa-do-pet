# 05 · Interface e design

## 1. Tokens visuais

### Cores (somente a paleta oficial + papéis derivados)

| Token | Hex | Uso |
|-------|-----|-----|
| `caramelo` | `#B97942` | Primária: botões, seleção, marcador de cão, foco |
| `areia` | `#E7C49F` | Cartões, chips, áreas de apoio |
| `branco` | `#FFFDF9` | Fundo principal |
| `marrom` | `#49382D` | Texto, ícones, marcador de gato |
| *derivadas* | tons/opacidades das 4 acima | `outline` (marrom 40 %), `surfaceVariant` (areia 40 %), `disabled` (marrom 38 %) |
| `erro` | `#B3261E` | **Única exceção funcional**: mensagens de erro e ação destrutiva |

**Contraste (aproximado — validar com ferramenta):**

| Par | Razão | Uso permitido |
|-----|-------|---------------|
| Marrom / Branco | ≈ 10:1 | Qualquer texto |
| Marrom / Areia | ≈ 6,8:1 | Qualquer texto |
| Branco / Caramelo | ≈ 3,5:1 | Apenas texto **grande ou negrito** (≥ 16 sp bold) |
| Marrom / Caramelo | ≈ 3,1:1 | Apenas ícones e texto grande |

Regra: **nunca** Caramelo como cor de texto corrido sobre Branco.

### Tipografia (Material 3, família padrão)

| Estilo | Tamanho | Uso |
|--------|:------:|-----|
| `headlineSmall` | 24 sp | Título de tela |
| `titleMedium` | 16 sp / w600 | Títulos de seção, rótulos de botão |
| `bodyLarge` | 16 sp | Texto principal |
| `bodyMedium` | 14 sp | Texto secundário |
| `labelLarge` | 14 sp / w600 | Chips, botões pequenos |

### Espaçamento e forma
Escala de **4 dp** (4·8·12·16·24·32). Margem de tela 16 dp. Raio de cartões 16 dp; botões e chips 12 dp. Alvo de toque mínimo **48×48 dp**.

## 2. Componentes reutilizáveis

| Componente | Local | Função |
|------------|-------|--------|
| `TriStateSelector` | `pets/presentation/widgets` | Sim / Não / Não sei (`SegmentedButton`) |
| `PetCard` | idem | Cartão da lista |
| `PetMarker` | `map/presentation/widgets` | Marcador SVG cão/gato com `Semantics` |
| `SpeciesFilterBar` | `core/widgets` | Todos · Cachorros · Gatos |
| `EmptyState`, `ErrorView`, `LoadingView` | `core/widgets` | Estados padrão |
| `LastCareHighlight` | `care/presentation/widgets` | "Última alimentação: 12/03 às 08:30" |
| `AdoptionBanner` | `pets/presentation/widgets` | Mensagem fixa de adoção |

## 3. Wireframes (baixa fidelidade)

### Mapa
```
┌────────────────────────────────┐
│ Mapa do Pet                    │
│ [ Todos ] [Cachorros] [ Gatos ]│
│┌──────────────────────────────┐│
││        🗺️  (OpenStreetMap)   ││
││     🐶            🐱         ││
││            🐶                ││
││                              ││
││ © OpenStreetMap contributors ││
│└──────────────────────────────┘│
│ Tem um animal por aqui? Toque  │
│ em um lugar livre do mapa.     │
├────────────────────────────────┤
│  [Mapa]   Animais   Informações│
└────────────────────────────────┘
```

### Cadastro
```
┌────────────────────────────────┐
│ ←  Novo animal                 │
│ ── Identificação ──            │
│ [ 📷 Adicionar foto ]          │
│ Espécie *  (🐶 Cachorro)(🐱 Gato)│
│ Nome  [____________]           │
│ Sexo  (Macho)(Fêmea)(Não sei)  │
│ Idade [Filhote ▾]  Porte [ ▾ ] │
│ ── Características ──          │
│ Aparência [ multilinha ]       │
│ Dócil?      (Sim)(Não)(Não sei)│
│ Castrado?   (Sim)(Não)(Não sei)│
│ Ferimentos? (Sim)(Não)(Não sei)│
│ ── Localização ──              │
│ [ mini-mapa com ponto ]        │
│ Referência [ Praça ... ]       │
│                                │
│ [      Finalizar cadastro     ]│
└────────────────────────────────┘
* obrigatório
```

### Lista
```
┌────────────────────────────────┐
│ Animais                        │
│ 🔍 Buscar por nome ou região   │
│ [ Todos ] [Cachorros] [ Gatos ]│
│ ┌────────────────────────────┐ │
│ │[foto] Caramelo      🐶     │ │
│ │       Macho · Adulto       │ │
│ │       Praça da Matriz      │ │
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │[foto] Gato sem nome 🐱     │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│   Mapa   [Animais]  Informações│
└────────────────────────────────┘
```

### Perfil
```
┌────────────────────────────────┐
│ ←  Caramelo             ⋮      │
│ [      foto grande       ]     │
│ Cachorro · Macho · Adulto      │
│ 📍 Praça da Matriz             │
│ ── Características ──          │
│ ── Informações médicas ──      │
│ Antirrábica: Não sei           │
│ ── Cuidados ──                 │
│ ┌ Última alimentação ┐┌ Último banho ┐
│ │ 12/03 às 08:30     ││ 02/03        │
│ └────────────────────┘└──────────────┘
│ Alimentação ▸ lista            │
│ Banho ▸ lista                  │
│ Medicamentos ▸ lista           │
│ Saúde ▸ lista                  │
│ [ + Adicionar registro ]       │
│ ┌ Disponível para adoção! ───┐ │
│ │ Adote um pet, mude uma vida!│ │
│ └─────────────────────────────┘│
│ [   Atualizar informações   ]  │
└────────────────────────────────┘
```

### Informações
```
┌────────────────────────────────┐
│ Como funciona o app?           │
│ Cadastre um animal de rua que  │
│ precisa de cuidados... (texto) │
│                                │
│   Adote um pet, mude uma vida! │
└────────────────────────────────┘
```

## 4. Textos (microcopy)

| Situação | Texto |
|----------|-------|
| Dica no mapa | "Tem um animal por aqui? Toque em um lugar livre do mapa para cadastrar um novo animal." |
| Confirmação | "Cadastrar animal aqui?" · [Cancelar] [Cadastrar] |
| Espécie ausente | "Escolha se é cachorro ou gato." |
| Salvo | "Animal cadastrado!" |
| Falha ao salvar | "Não foi possível salvar. Tente novamente." |
| Lista vazia | "Nenhum animal cadastrado ainda. Toque no mapa para começar." |
| Busca sem resultado | "Nada encontrado para “{busca}”." |
| Sem internet no mapa | "Sem internet: o fundo do mapa não carregou, mas seus animais continuam aqui." |
| Remover | "Remover {nome} e todo o histórico de cuidados? Esta ação não pode ser desfeita." |
| Adoção | "Disponível para adoção! Adote um pet, mude uma vida! Todos os animais cadastrados aqui no aplicativo estão em situação de rua e disponíveis para adoção." |
| Nome padrão | "Cachorro sem nome" / "Gato sem nome" |

## 5. Acessibilidade — checklist

- [ ] Alvos de toque ≥ 48 dp.
- [ ] `Semantics(label: ...)` em marcadores ("Cachorro, Praça da Matriz") e botões só com ícone.
- [ ] Cão × gato por **forma** do marcador, não só por cor.
- [ ] Interface utilizável com fonte a 200 % (sem texto cortado).
- [ ] Campos com rótulo visível (não só *hint*).
- [ ] Erros descritos em texto, não só em vermelho.
- [ ] Ordem de foco coerente (de cima para baixo).
- [ ] Contraste conferido conforme a tabela da seção 1.

## 6. Marcadores do mapa

| Espécie | Forma | Cor de preenchimento | Arquivo |
|---------|-------|----------------------|---------|
| Cão | Patinha arredondada | Caramelo | `assets/markers/dog.svg` |
| Gato | Patinha com cabeça de orelhas pontudas | Marrom | `assets/markers/cat.svg` |

Tamanho 40×40 dp, com contorno branco de 2 dp para destacar sobre qualquer fundo do mapa.
