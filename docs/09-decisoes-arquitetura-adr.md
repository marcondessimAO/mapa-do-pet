# 09 · Registro de decisões de arquitetura (ADR)

Formato: **Contexto → Decisão → Consequências → Alternativas**. Status: `Aceita` salvo indicação.

---

## ADR-001 · Clean Architecture enxuta + MVVM, organizada por funcionalidade
**Contexto.** O planner original agrupava arquivos por tipo (`models/`, `screens/`…), o que espalha cada funcionalidade por várias pastas e não impede telas de acessarem o banco.
**Decisão.** Pastas por funcionalidade (`features/pets`, `features/care`…) e, dentro, camadas `domain / data / presentation`. Dependências apontam para o domínio.
**Consequências.** (+) Regra verificável por `grep`; (+) divisão de trabalho com poucos conflitos; (−) mais arquivos e algum boilerplate (interfaces, mappers).
**Alternativas.** Layer-first (simples, mas acoplado); MVC puro (mistura estado e UI).

## ADR-002 · `Provider` + `ChangeNotifier` para estado e injeção
**Contexto.** São poucos ViewModels e a equipe está aprendendo Flutter.
**Decisão.** `provider` para DI e observação; sem Bloc/Riverpod.
**Consequências.** (+) Pouco código, curva pequena, recomendado na documentação oficial; (−) menos ferramentas de depuração que Bloc; atualização entre telas é manual (`load()` ao voltar).
**Alternativas.** Riverpod (mais seguro em tempo de compilação, maior curva); Bloc (verboso para este escopo).

## ADR-003 · Persistência local com `sqflite` (SQLite)
**Contexto.** Sem backend; dados relacionais (animal → N registros); requisito do enunciado.
**Decisão.** SQLite via `sqflite`, com chaves estrangeiras, `CHECK`s e migrações versionadas.
**Consequências.** (+) Integridade referencial e consultas por índice; (−) não funciona em Flutter Web; testes de dados exigem `sqflite_common_ffi`.
**Alternativas.** Hive/Isar (NoSQL, sem integridade relacional nativa); `drift` (ótimo, mas gera código e adiciona camada a aprender).

## ADR-004 · Tabela única `care_records` com discriminador `type`
**Contexto.** Alimentação, banho, medicamento e saúde têm quase os mesmos campos.
**Decisão.** *Single-table inheritance*: uma tabela, coluna `type`, colunas específicas anuláveis protegidas por `CHECK`. No domínio, `sealed class CareRecord` com 4 subtipos.
**Consequências.** (+) Um `SELECT` traz todo o histórico; (+) menos duplicação; (−) colunas nulas por linha.
**Alternativas.** Uma tabela por tipo (mais "pura", 4× o código de acesso).

## ADR-005 · OpenStreetMap com `flutter_map`
**Contexto.** Mapa sem chave de API paga e sem GPS.
**Decisão.** `flutter_map` + tiles OSM, atribuição visível e `userAgentPackageName`; URL de tiles em `AppConstants` para trocar de provedor.
**Consequências.** (+) Gratuito, sem conta; (−) servidor público tem política de uso justo e exige internet; mapa offline fica fora do MVP.
**Alternativas.** Google Maps (exige chave e faturamento).

## ADR-006 · `Result<T>` em vez de exceções entre camadas
**Contexto.** Exceções não aparecem na assinatura e costumam vazar para a UI.
**Decisão.** `sealed class Result<T>` (`Ok`/`Err`) com `Failure` tipada; exceções só dentro da camada `data`.
**Consequências.** (+) `switch` exaustivo garante tratamento; (−) um pouco mais verboso.
**Alternativas.** `try/catch` espalhado; pacote `fpdart` (dependência extra).

## ADR-007 · IDs UUID v4 gerados no cliente
**Contexto.** É preciso evitar duplicidade por toques repetidos (RN-09) e preparar sincronização futura.
**Decisão.** `id` criado ao abrir o formulário; `INSERT OR IGNORE`.
**Consequências.** (+) Idempotência e ausência de colisões entre aparelhos; (−) strings maiores que inteiros.
**Alternativas.** `AUTOINCREMENT` (colide na sincronização).

## ADR-008 · Fotos guardadas como arquivo; o banco guarda só o nome
**Contexto.** Imagens em BLOB incham o banco; caminhos absolutos mudam no iOS entre atualizações.
**Decisão.** Copiar para `<documentos>/pet_photos/<uuid>.jpg`; persistir apenas `photo_file_name`.
**Consequências.** (+) Banco leve e portátil; (−) é preciso limpar arquivos órfãos ao trocar/remover.

## ADR-009 · `TriState` único para campos sim/não/desconhecido
**Contexto.** Seis campos usavam o mesmo conjunto de valores; o original tinha um enum só para vacinação.
**Decisão.** Um enum `TriState { yes, no, unknown }` reutilizado.
**Consequências.** (+) DRY e componente de UI único; (−) valores semânticos específicos exigem validação no domínio (ex.: gestante × macho).

## ADR-010 · Busca textual em Dart, não em SQL
**Contexto.** `LIKE` do SQLite não ignora acentos nem maiúsculas fora de ASCII.
**Decisão.** Carregar a lista e filtrar com texto normalizado (`TextSearchFilter`).
**Consequências.** (+) Busca correta em português; (−) não escala a dezenas de milhares de linhas — aceitável para o MVP local; revisitar se houver backend.

## ADR-011 · A raiz de DI declara cada dependência antes de quem a lê
**Contexto.** `buildAppProviders` é uma lista de `Provider`s criados de forma preguiçosa. `GetPetProfile` lê o `CareRepository`, mas este estava declarado **depois**; o `Provider` só enxerga o que vem acima na lista. O erro (`ProviderNotFoundError`) só aparecia na primeira vez que alguém abria um perfil, e passou despercebido por 369 testes que montavam os providers à mão.
**Decisão.** Manter a ordem **infraestrutura → repositórios → use cases → ViewModels** e cobrir a raiz com um teste (`test/core/di/app_providers_test.dart`) que resolve todos os use cases a partir de `buildAppProviders`.
**Consequências.** (+) Um erro de ordem passa a falhar em teste, não no aparelho; (−) a ordem da lista é uma regra implícita — o comentário no código e o teste a documentam. **Alternativa possível (não adotada):** `Provider` com `lazy: false`, que faria o erro aparecer já na abertura do app, mas sem explicitar a ordem.

## ADR-012 · Cartão flutuante e modo de posicionamento no mapa
**Contexto.** Depois de rodar o app no emulador, o resumo do animal abria numa folha modal que cobria o mapa (o usuário perdia de vista onde o animal estava) e o cadastro dependia de descobrir que se pode tocar num lugar livre.
**Decisão.** (1) O resumo vira um **cartão flutuante** sobre o mapa, enquanto a câmera voa até o animal; (2) o botão **Adicionar animal** abre um **modo de posicionamento**: um alfinete fixo no centro e o usuário arrasta o mapa até o local antes de **Confirmar local**. O toque em área livre com confirmação continua existindo.
**Consequências.** (+) O mapa continua visível; o cadastro fica descobrível e o ponto, mais preciso; (−) a tela do mapa ganha estado (`Livre`/`Selecionado`/`Posicionando`, ver [UML §4.4](uml/atividades-e-estados.md)) e mais testes. **Alternativa:** manter a folha modal e só restilizar — descartada por esconder o mapa.
