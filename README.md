# Análise de Fenótipos em Saúde com R

## Descrição do Projeto

Este projeto busca aplicar aprendizado e realizar testes com foco em análises abrangentes de dados fenotípicos na área de saúde, utilizando a linguagem R. O foco está na exploração de características físicas, biomarcadores e medidas clínicas para identificar padrões e associações relevantes.

## Objetivos

- **Análise Exploratória**: Investigar distribuições e correlações entre variáveis fenotípicas
- **Clustering Fenotípico**: Identificar grupos de indivíduos com perfis fenotípicos similares
- **Análise de Componentes Principais**: Reduzir dimensionalidade e identificar fatores principais
- **Modelagem Preditiva**: Desenvolver modelos para predição de características de saúde
- **Visualização Interativa**: Dashboard para exploração dinâmica dos dados

## Estrutura do Projeto

```
r_project/
├── data/                    # Dados brutos e processados
│   ├── raw/                # Dados originais
│   └── processed/          # Dados limpos e transformados
├── scripts/                # Scripts de análise
│   ├── 01_data_generation.R    # Geração de dados sintéticos
│   ├── 02_data_cleaning.R      # Limpeza e preparação
│   ├── 03_exploratory_analysis.R  # Análise exploratória
│   ├── 04_statistical_analysis.R  # Análises estatísticas
│   └── 05_modeling.R           # Modelagem preditiva
├── functions/              # Funções customizadas
├── outputs/                # Resultados e visualizações
│   ├── figures/           # Gráficos e plots
│   └── tables/            # Tabelas de resultados
├── shiny_app/             # Aplicação Shiny
├── tests/                 # Testes unitários
└── docs/                  # Documentação
```

## Variáveis Fenotípicas Analisadas

### Medidas Antropométricas
- Altura, peso, IMC
- Circunferência da cintura e quadril
- Percentual de gordura corporal

### Biomarcadores
- Glicose, colesterol total, HDL, LDL
- Triglicerídeos, pressão arterial
- Proteína C-reativa, hemoglobina

### Características Demográficas
- Idade, sexo, etnia
- Histórico familiar de doenças
- Estilo de vida (exercício, tabagismo)

## Tecnologias Utilizadas

- **R**: Linguagem principal
- **tidyverse**: Manipulação e visualização de dados
- **shiny**: Dashboard interativo
- **plotly**: Visualizações interativas
- **cluster**: Análises de agrupamento
- **randomForest**: Modelagem preditiva
- **corrplot**: Visualização de correlações

## Como Usar

1. **Instalação de Dependências**:
   ```r
   source("setup.R")
   ```

2. **Geração de Dados**:
   ```r
   source("scripts/01_data_generation.R")
   ```

3. **Análises Completas**:
   ```r
   source("scripts/run_all_analyses.R")
   ```

4. **Dashboard Interativo**:
   ```r
   shiny::runApp("shiny_app/")
   ```

## Resultados Esperados

- Identificação de clusters fenotípicos distintos
- Correlações entre biomarcadores e características antropométricas
- Modelos preditivos para risco de doenças
- Visualizações interativas para exploração de dados

## Contribuições

Este projeto serve como base para análises fenotípicas em pesquisas de saúde e pode ser adaptado para diferentes datasets e objetivos específicos.

## Licença

MIT License - veja LICENSE.md para detalhes.
