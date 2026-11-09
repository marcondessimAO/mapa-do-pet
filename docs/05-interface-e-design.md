# 05 · Interface e design

> Estado: reflete o app **depois do redesign** (Fase 7). Os wireframes são de baixa
> fidelidade; as capturas reais do app no emulador estão em
> [`screenshots/`](screenshots/) e na seção "Telas" do [README](../README.md).

## 1. Tokens visuais

### Cores (somente a paleta oficial + papéis derivados)

| Token | Hex | Uso |
|-------|-----|-----|
| `caramelo` | `#B97942` | Primária: botões, seleção, marcador de cão, foco, botão "Adicionar animal" |
| `areia` | `#E7C49F` | Seleção (filtro, aba), pílulas, avatar sem foto, halo do marcador |
| `branco` | `#FFFDF9` | Fundo principal e painéis flutuantes |
| `marrom` | `#49382D` | Texto, ícones, marcador de gato |
| `areiaClara` *(derivada)* | `#F5E6D5` | Fundo de cartões, campos de texto e do filtro não selecionado (areia 40 % sobre branco) |
| `sombra` *(derivada)* | marrom 18 % | Sombra suave dos elementos que flutuam sobre o mapa |
| *outras derivadas* | opacidades das 4 cores | `contorno` (marrom 40 %), `desabilitado` (marrom 38 %), `selecao` (caramelo ~33 %) |
| `erro` | `#B3261E` | **Única exceção funcional**: mensagens de erro e ação destrutiva |

A paleta oficial **não mudou** no redesign: `areiaClara` e `sombra` são só diluições
das cores existentes.

**Contraste** (medido; ver seção 7): Marrom/Branco 10,95:1 · Marrom/Areia 6,78:1 ·
**Marrom/Areia clara 9,10:1** · Erro/Branco 6,43:1 · Branco/Caramelo 3,52:1 (só texto
grande ou negrito) · Marrom/Caramelo 3,11:1 (só ícones e texto grande).

Regra: **nunca** Caramelo como cor de texto corrido sobre Branco.

### Tipografia (Material 3, família padrão)

O tema (`AppTheme`) deixa os títulos mais firmes e compactos:

| Estilo | Peso / ajuste | Uso |
|--------|---------------|-----|
| `headlineMedium` | w800, espaçamento −0,5 | Título grande da lista ("Animais") |
| `headlineSmall` | w800, −0,3 | Título de página (Informações, perfil) |
| `titleLarge` | w800, −0,2 | Marca "Mapa do Pet", título de seção, nome no cartão de resumo |
| `titleMedium` / `titleSmall` | w700 | Nome no cartão da lista, instruções |
| `labelLarge` | w700 | Botões |
| `bodyLarge` / `bodyMedium` | padrão | Texto corrido |

Rótulo dos botões: **16 sp, negrito (w700)**; o botão flutuante "Adicionar animal" usa
16 sp w800. É o que permite branco sobre Caramelo (3,52:1) por ser texto grande.

### Forma, elevação e espaçamento

| Elemento | Raio (`AppRadius`) |
|----------|:------------------:|
| Chips / pílulas pequenas | 14 |
| Campos de texto e botões | 16 |
| Cartões e painéis flutuantes | 22 |
| Cartão de resumo do animal | 24 |
| Folhas modais e diálogos | 28 |
| Pílulas totais (filtro, contador, indicador da aba) | 999 |

- Escala de **4 dp** (4·8·12·16·24). Margem de tela 16 dp; painéis sobre o mapa a 12 dp da borda.
- **Elevação**: elementos que flutuam sobre o mapa usam `Material.elevation` 4–6 com a cor `sombra`
  (sombra marrom suave, nunca preta).
- Campos de texto e cartões são **preenchidos** (`areiaClara`), sem contorno; o foco vira
  borda Caramelo de 2 dp, o erro borda `erro`.
- Alvo de toque mínimo **48×48 dp**.

### Navegação e transições
- Barra de navegação branca (72 dp, elevação 8) com indicador em **pílula Areia** e rótulo
  em negrito na aba ativa.
- Trocar de aba faz um **fade de 220 ms**; o `IndexedStack` continua preservando o estado
  (zoom e posição do mapa não se perdem).
- Rotas: transição `FadeForwards` no Android e a padrão do iOS.

## 2. Componentes reutilizáveis

| Componente | Local | Função |
|------------|-------|--------|
| `AppTheme` / `AppRadius` / `AppColors` | `core/theme` | Tema Material 3, raios e paleta |
| `PetMarker` | `map/presentation/widgets` | Alfinete cão/gato com ponta, sombra, animação de entrada e estado `selected` |
| `PetSummarySheet` | idem | Cartão flutuante de resumo ao tocar num alfinete (foto, nome, espécie, detalhes, "Ver perfil", fechar) |
| `ConfirmRegisterSheet` | idem | "Cadastrar animal aqui?" (toque num lugar livre) |
| `PetCard` | `pets/presentation/widgets` | Cartão da lista (avatar, nome, pílula da espécie, detalhes, referência, seta) |
| `PetAvatar` | idem | Foto redonda com anel claro e sombra; sem foto, patinha |
| `SpeciesPill` | idem | Selo com o rótulo da espécie |
| `SpeciesFilterBar` | idem | Todos · Cachorros · Gatos (pílula; usado no mapa e na lista) |
| `TriStateSelector` | idem | Sim / Não / Não sei (`SegmentedButton`) |
| `ProfileSection` / `InfoRow` | idem | Seção do perfil em **cartão** + linha rótulo/valor |
| `AdoptionBanner` | idem | Mensagem fixa de adoção |
| `EmptyState`, `ErrorView` | `core/widgets` | Estados padrão |
| `LastCareHighlight` | `care/presentation/widgets` | "Última alimentação: 12/03 às 08:30" |

Componentes **internos** da tela do mapa (`map_page.dart`): painel flutuante, cabeçalho
(marca + contador + filtro), botões redondos de zoom, barra de confirmação do local e o
alfinete central do modo "Adicionar animal".

## 3. Wireframes (baixa fidelidade)

### Mapa
```
┌────────────────────────────────┐
│ ╭────────────────────────────╮ │
│ │ 🐾 Mapa do Pet   [2 no mapa]│ │  cabeçalho flutuante
│ │ ( Todos )(Cachorros)(Gatos) │ │
│ ╰────────────────────────────╯ │
│      🗺️  (OpenStreetMap)       │
│    📍 (alfinete)         (+)   │
│                    📍    (−)   │
│                          (◎)   │  zoom e "mostrar todos"
│            [ ＋ Adicionar animal ]│  botão principal
│ ╭────────────────────────────╮ │
│ │ Tem um animal por aqui?    │ │  dica (some ao arrastar o mapa)
│ │ Toque em um lugar livre... │ │
│ ╰────────────────────────────╯ │
│ © OpenStreetMap contributors   │
├────────────────────────────────┤
│  (Mapa)    Animais   Informações│
└────────────────────────────────┘
```

### Mapa — animal selecionado
```
│        ⭕📍 (cresce + halo)      │  a câmera voa até o animal
│ ╭────────────────────────────╮ │
│ │ (foto) Caramelo         ✕  │ │
│ │        [Cachorro]          │ │
│ │        Macho               │ │
│ │        📍 Praça da Matriz  │ │
│ │ [      Ver perfil  →      ]│ │
│ ╰────────────────────────────╯ │
```

### Mapa — modo "Adicionar animal"
```
│ (cabeçalho)                    │
│                                │
│              📍                │  alfinete fixo no centro
│                                │  (a ponta marca o local)
│ ╭────────────────────────────╮ │
│ │ Arraste o mapa até onde o  │ │
│ │ animal costuma ficar.      │ │
│ │ O alfinete no centro marca │ │
│ │ o local aproximado.        │ │
│ │ [Cancelar] [Confirmar local]│ │
│ ╰────────────────────────────╯ │
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
│ 2 animais esperando um lar     │
│ ╭────────────────────────────╮ │
│ │ 🔍 Buscar por nome ou região│ │
│ ╰────────────────────────────╯ │
│ ( Todos )(Cachorros)(Gatos)    │
│ ╭────────────────────────────╮ │
│ │ (foto) Caramelo          ›  │ │  cartões entram em sequência
│ │        [Cachorro]           │ │  (puxe para atualizar)
│ │        Macho                │ │
│ │        📍 Praça da Matriz   │ │
│ ╰────────────────────────────╯ │
├────────────────────────────────┤
│   Mapa   (Animais)  Informações│
└────────────────────────────────┘
```

### Perfil
```
┌────────────────────────────────┐
│ ←  Perfil do animal      ⋮     │
│        (foto grande)           │
│          Caramelo              │
│ ╭─ Identificação ────────────╮ │
│ │ Espécie · Sexo · Idade ... │ │  cada seção é um cartão
│ ╰────────────────────────────╯ │
│ ╭─ Características ──────────╮ │
│ ╰────────────────────────────╯ │
│ ╭─ Informações médicas ──────╮ │
│ │ Antirrábica: Não sei       │ │
│ ╰────────────────────────────╯ │
│ ── Cuidados ──                 │
│ ┌ Última alimentação ┐┌ Último banho ┐
│ │ 12/03 às 08:30     ││ 02/03        │
│ └────────────────────┘└──────────────┘
│ Alimentação ▸ lista · Banho ▸ lista │
│ Medicamentos ▸ lista · Saúde ▸ lista│
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
│ Informações                    │
│ ╭────────────────────────────╮ │
│ │ (🐾)  Como funciona o app?  │ │  faixa de destaque (gradiente areia)
│ ╰────────────────────────────╯ │
│ [Toque no mapa][Preencha os dados][Acompanhe os cuidados]
│ ╭────────────────────────────╮ │
│ │ Cadastre um animal de rua  │ │
│ │ que precisa de cuidados... │ │
│ ╰────────────────────────────╯ │
│ ╭────────────────────────────╮ │
│ │ ♥ Adote um pet, mude uma vida!│ │  faixa Caramelo
│ ╰────────────────────────────╯ │
└────────────────────────────────┘
```

## 4. Textos (microcopy)

| Situação | Texto |
|----------|-------|
| Dica no mapa | "Tem um animal por aqui? Toque em um lugar livre do mapa para cadastrar um novo animal." |
| Contador do mapa | "1 no mapa" · "N no mapa" (oculto sem animais) |
| Botão principal do mapa | "Adicionar animal" |
| Modo de posicionamento | "Arraste o mapa até onde o animal costuma ficar." · "O alfinete no centro marca o local aproximado." · [Cancelar] [Confirmar local] |
| Dicas dos botões do mapa | "Aproximar o mapa" · "Afastar o mapa" · "Mostrar todos os animais" · "Fechar" |
| Confirmação (toque no mapa) | "Cadastrar animal aqui?" · [Cancelar] [Cadastrar] |
| Espécie ausente | "Escolha se é cachorro ou gato." |
| Salvo | "Animal cadastrado!" |
| Falha ao salvar | "Não foi possível salvar. Tente novamente." |
| Subtítulo da lista | "1 animal esperando um lar" · "N animais esperando um lar" |
| Lista vazia | "Nenhum animal cadastrado ainda. Toque no mapa para começar." |
| Busca sem resultado | "Nada encontrado para “{busca}”." |
| Sem internet no mapa | "Sem internet: o fundo do mapa não carregou, mas seus animais continuam aqui." |
| Remover | "Remover {nome} e todo o histórico de cuidados? Esta ação não pode ser desfeita." |
| Adoção | "Disponível para adoção! Adote um pet, mude uma vida! Todos os animais cadastrados aqui no aplicativo estão em situação de rua e disponíveis para adoção." |
| Passos (Informações) | "Toque no mapa" · "Preencha os dados" · "Acompanhe os cuidados" |
| Nome padrão | "Cachorro sem nome" / "Gato sem nome" |

## 5. Acessibilidade — checklist

- [x] Alvos de toque ≥ 48 dp (testado nas 7 telas).
- [x] `Semantics(label: ...)` em marcadores ("Cachorro Caramelo, Praça da Matriz") e `tooltip` nos botões só com ícone.
- [x] Cão × gato por **forma** do marcador (e pelo rótulo da pílula), não só por cor.
- [x] Interface utilizável com fonte a 200 % (testado, sem estouro).
- [x] Campos com rótulo visível (não só *hint*).
- [x] Erros descritos em texto, não só em vermelho.
- [x] Marcador selecionado anunciado como `selected` para leitores de tela.
- [ ] Ordem de foco coerente com **TalkBack** em aparelho (não verificado).
- [x] Contraste conferido conforme a seção 7.

## 6. Marcadores do mapa

O marcador é um **alfinete**: cabeça circular (o SVG da espécie) + ponta que cai
**exatamente** no local do animal (`Marker(alignment: Alignment.topCenter)`).

| Espécie | Forma da cabeça | Cor | Arquivo |
|---------|-----------------|-----|---------|
| Cão | Patinha arredondada | Caramelo | `assets/markers/dog.svg` |
| Gato | Patinha com cabeça de orelhas pontudas | Marrom | `assets/markers/cat.svg` |

| Parte | Medida / comportamento |
|-------|------------------------|
| Widget inteiro | 52 × 66 dp (cabeça de 44 dp + ponta) |
| Contorno da cabeça | Branco, 2 dp, para destacar sobre qualquer fundo |
| Ponta e sombra | Triângulo arredondado na cor da espécie + sombra oval no chão |
| Entrada | Cresce de 0 a 100 % em 420 ms (`easeOutBack`) |
| **Selecionado** | Escala 1,2× (220 ms) + halo Areia; desenhado **por cima** dos outros |

## 7. Verificação de acessibilidade (medida)

**Contraste da paleta** (fórmula WCAG; verificado em `test/core/theme/contrast_test.dart`):

| Par | Razão | Uso permitido |
|-----|:-----:|---------------|
| Marrom / Branco | 10,95:1 | Qualquer texto (AAA) |
| Marrom / Areia clara | 9,10:1 | Qualquer texto (AAA) — cartões, campos, filtro |
| Marrom / Areia | 6,78:1 | Qualquer texto (AA) |
| Erro / Branco | 6,43:1 | Texto de erro (AA) |
| Branco / Caramelo | 3,52:1 | Só texto **grande ou negrito** (rótulo de botão ≥ 16 sp, w700) |
| Marrom / Caramelo | 3,11:1 | Ícones e texto grande |

Por isso o Caramelo **nunca** é cor de texto corrido; o tema fixa o rótulo dos botões em 16 sp negrito.

**Testes automatizados** (`test/accessibility/accessibility_test.dart`), em celular de 360 dp:

| Verificação | Telas cobertas | Resultado |
|-------------|----------------|-----------|
| Fonte a **200 %** sem estouro de layout | Mapa, Animais, Informações, Navegação, Perfil, Cadastro, Registro de cuidado | Passa |
| Alvos de toque ≥ 48 dp (`androidTapTargetGuideline`) | as 7 telas | Passa |
| Controles com rótulo (`labeledTapTargetGuideline`) | as 7 telas | Passa |
| Contraste do texto renderizado (`textContrastGuideline`) | Animais, Informações, Perfil | Passa |
| Mapa anunciado a leitores de tela | Mapa | Passa |

**Ainda não verificado:** uso real com **TalkBack/VoiceOver** em aparelho. Os testes acima medem regras, não a experiência de quem usa leitor de tela.

## 8. Interações do mapa

| Gesto / ação | Resultado |
|--------------|-----------|
| Tocar num **alfinete** | Seleciona (halo + escala), a câmera **voa** até o animal (500 ms, `easeInOutCubic`, zoom mínimo 16) e sobe o cartão de resumo |
| Tocar em **Ver perfil** | Abre o perfil; ao voltar, os alfinetes são recarregados |
| Tocar em **✕** ou **num lugar livre** com o cartão aberto | Só fecha o cartão (o toque não cadastra) |
| Tocar num lugar livre (sem cartão) | Pergunta "Cadastrar animal aqui?" |
| **Adicionar animal** | Entra no modo de posicionamento: alfinete fixo no centro; o usuário arrasta o mapa e toca **Confirmar local**; abre o formulário com o centro do mapa |
| Tocar no mapa durante o posicionamento | Nada (o mapa só é arrastado) |
| **Arrastar** o mapa | A dica some (o usuário já entendeu) |
| **+ / −** | Zoom ±1 com movimento suave (limites 3 a 18) |
| **Mostrar todos os animais** | Enquadra todos com movimento suave (com um só animal, vai até ele no zoom 16) |
| Trocar o filtro | Os alfinetes da outra espécie somem; o contador acompanha; se o animal selecionado sumir, o cartão some |

**Enquadramento inicial:** na primeira carga o mapa enquadra todos os animais (zoom máx. 17),
com margens `64 / 240 / 64 / 210` dp (esq./topo/dir./base) para os alfinetes não ficarem
**atrás** do cabeçalho nem dos botões. Sem animais, fica no centro padrão
(`AppConstants.defaultMapCenter`, ainda provisório). O app **nunca** usa a localização do usuário.

**Barra de status:** um degradê branco → transparente (28 dp + altura da barra) fica sob ela,
para o relógio e os ícones continuarem legíveis sobre o mapa.
