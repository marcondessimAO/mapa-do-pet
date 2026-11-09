# 📚 Documentação — Mapa do Pet

Este diretório reúne toda a documentação técnica do projeto. A ordem abaixo é a sugerida para leitura.

| # | Documento | O que responde |
|---|-----------|----------------|
| — | [Plano do projeto](plano-do-projeto.md) | O quê e por quê: visão, escopo (MoSCoW), requisitos RF/RNF/RN, identidade visual, riscos |
| 01 | [Requisitos e casos de uso](01-requisitos-e-casos-de-uso.md) | Quem usa o app e o que faz; especificação dos casos de uso; rastreabilidade |
| 02 | [Arquitetura](02-arquitetura.md) | Como o código é organizado: camadas, dependências, DI, estado, erros, evolução |
| 03 | [Banco de dados](03-banco-de-dados.md) | Modelo ER, dicionário de dados, consultas, migrações |
| 04 | [Padrões de projeto](04-padroes-de-projeto.md) | Cada padrão: intenção, onde está, código de exemplo |
| 05 | [Interface e design](05-interface-e-design.md) | Tokens visuais, wireframes, textos, acessibilidade |
| 06 | [Estratégia de testes](06-estrategia-de-testes.md) | Pirâmide de testes, casos por requisito, cobertura |
| 07 | [Guia de contribuição](07-guia-de-contribuicao.md) | Git, commits, revisão, Definition of Done |
| 08 | [Plano de desenvolvimento](08-plano-de-desenvolvimento.md) | Backlog por fase, tarefas, ordem TDD e status |
| 09 | [Decisões de arquitetura (ADR)](09-decisoes-arquitetura-adr.md) | Por que cada escolha técnica foi feita |
| 10 | [Roteiro de apresentação](10-roteiro-de-apresentacao.md) | Slides, demonstração passo a passo e perguntas prováveis |

## 🧩 Diagramas UML (`uml/`)

| Diagrama | Arquivo |
|----------|---------|
| Casos de uso | [01-requisitos-e-casos-de-uso.md](01-requisitos-e-casos-de-uso.md#2-diagrama-de-casos-de-uso) |
| Classes — domínio | [uml/classes-dominio.md](uml/classes-dominio.md) |
| Classes — camadas (use cases, repositórios, ViewModels) | [uml/classes-camadas.md](uml/classes-camadas.md) |
| Sequência (6 fluxos) | [uml/sequencia.md](uml/sequencia.md) |
| Atividades e estados | [uml/atividades-e-estados.md](uml/atividades-e-estados.md) |
| Componentes, pacotes e implantação | [uml/componentes-e-pacotes.md](uml/componentes-e-pacotes.md) |
| Entidade-relacionamento | [03-banco-de-dados.md](03-banco-de-dados.md#1-modelo-entidade-relacionamento) |

> **Como visualizar os diagramas:** todos são escritos em [Mermaid](https://mermaid.js.org/). Eles renderizam automaticamente no GitHub/GitLab e no VS Code com a extensão *Markdown Preview Mermaid Support*. Para exportar como imagem (PDF/Word do trabalho), cole o código em <https://mermaid.live> e baixe PNG/SVG.

## 🏷️ Convenções dos documentos

- Idioma: português do Brasil. Identificadores de código em inglês.
- IDs de rastreabilidade: `O` objetivos · `RF` funcionais · `RNF` não funcionais · `RN` regras de negócio · `UC` casos de uso · `ADR` decisões · `T` tarefas do plano de desenvolvimento.
- Quando um documento contradisser o código, **o documento deve ser corrigido no mesmo PR** (ver [guia de contribuição](07-guia-de-contribuicao.md)).
