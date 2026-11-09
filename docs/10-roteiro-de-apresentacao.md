# 10 · Roteiro de apresentação

Roteiro para ~10 minutos. Adapte os tempos ao que o professor pedir.

## 1. Estrutura (slides sugeridos)

| # | Slide | Tempo | O que dizer |
|---|-------|:----:|-------------|
| 1 | **Mapa do Pet** | 0:30 | Nome, equipe, "Adote um pet, mude uma vida!" |
| 2 | O problema | 1:00 | Quem cuida de animais de rua guarda tudo de cabeça: onde ficam, como são, quando comeram. Informação se perde e o cuidado se duplica ou se esquece. |
| 3 | A solução | 1:00 | Marcar o animal no mapa, manter um perfil e um **histórico de cuidados que só cresce**. Tudo no aparelho, sem login e sem pedir o GPS. |
| 4 | Demonstração | 3:00 | Ver o passo a passo da seção 2. |
| 5 | Arquitetura | 1:30 | Clean Architecture enxuta + MVVM, por funcionalidade. O domínio é Dart puro; a tela nunca fala com o SQLite. Mostrar o diagrama de camadas ([02](02-arquitetura.md)). |
| 6 | Padrões de projeto | 1:00 | Repository, MVVM/Observer, Injeção de Dependência, Singleton, Factory Method, Mapper, Strategy/Specification, Facade, Value Object, Null Object, sealed class, Use Case, Result ([04](04-padroes-de-projeto.md)). |
| 7 | Qualidade | 1:00 | Testes escritos primeiro (TDD), cobertura acima de 90 %, acessibilidade medida, banco com migrações versionadas. |
| 8 | Aprendizados e próximos passos | 0:30 | O que faríamos depois: sincronização, mapa offline, escala de voluntários. |
| 9 | Perguntas | — | Ver a seção 3. |

## 2. Roteiro da demonstração

Prepare o app com **dois animais já cadastrados** (um cão e um gato) para o mapa não abrir vazio.

1. **Mapa.** Abra o app: ele já abre no mapa, com marcadores de formas diferentes para cão e gato. Troque o filtro para *Gatos* e volte para *Todos*.
2. **Cadastro pelo toque.** Toque num lugar livre → *"Cadastrar animal aqui?"* → **Cadastrar**. Mostre que **só a espécie é obrigatória**: escolha *Gato* e salve. O marcador aparece.
3. **Ajuste do ponto.** Abra outro cadastro e toque no mini-mapa para mover o pino (a localização é aproximada e editável).
4. **Lista.** Aba *Animais*: busque por uma rua sem acento (ex.: "praca") e filtre por espécie.
5. **Perfil.** Toque no animal: identificação, características, informações médicas e a mensagem de adoção no fim.
6. **Cuidados.** *Adicionar registro* → *Alimentação* → salvar. Mostre o destaque **Última alimentação**. Registre outra com data de ontem e mostre que o destaque **não muda** (vale o registro mais recente, não o último lançado).
7. **Medicamento.** Tente salvar sem o nome (o app explica o erro) e depois com o nome.
8. **Edição sem perder histórico.** *Atualizar informações* → marque a vacinação antirrábica → salvar. Os cuidados continuam lá.
9. **Persistência.** Feche o app por completo e reabra: tudo continua.
10. **Remoção.** *Remover animal* → confirmação ("não pode ser desfeita") → o animal e o histórico somem.

> Se estiver sem internet, o mapa avisa que o fundo não carregou, mas os animais continuam aparecendo.

## 3. Perguntas que podem aparecer

| Pergunta | Resposta curta |
|----------|----------------|
| Por que não pede a localização do usuário? | Privacidade: o app só guarda o ponto **aproximado do animal**, escolhido no mapa. |
| Por que não tem login nem servidor? | Escopo do MVP. A arquitetura já separa dados da interface, então um backend entra no repositório sem reescrever as telas ([ADR](09-decisoes-arquitetura-adr.md)). |
| Por que o histórico não pode ser editado? | Para ter uma linha do tempo confiável. Só se acrescenta; o histórico só some se o animal for removido. |
| Como evitam registro duplicado? | O `id` nasce ao abrir o formulário e o botão trava ao salvar; salvar duas vezes grava uma vez. |
| Por que Provider e não Bloc/Riverpod? | Poucos ViewModels; menos código e curva menor (ADR-002). |
| Por que SQLite e não Hive? | Dados relacionais (animal → vários cuidados) com chave estrangeira e cascata (ADR-003). |
| O que mudaria com mais tempo? | Mapa offline, sincronização, escala de voluntários, agrupamento de marcadores. |

## 4. Checklist antes de apresentar

- [ ] App instalado e testado em **aparelho ou emulador** (a interface só foi validada por testes automatizados).
- [ ] Dois animais de exemplo já cadastrados.
- [ ] Internet disponível para o mapa carregar (ou aviso offline combinado).
- [ ] PDF/DOCX da documentação exportados (`docs/export/`, veja o [README de docs](README.md)).
- [ ] Diagramas UML abertos para consulta.
- [ ] Combinado quem fala de cada slide.
