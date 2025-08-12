# Demo - Análise de Fenótipos em Saúde

## Visão Geral do Projeto

Este projeto básico com principal foco sendo o aprendizado e testes, pretende implementar um app para análise de dados fenotípicos na área de saúde usando R. O sistema inclui desde a geração de dados sintéticos até análises estatísticas avançadas e um dashboard interativo.

## Estrutura Completa Criada

```
r_project/
├── README.md                       # Documentação principal
├── setup.R                         # Configuração e instalação
├── CHANGELOG.md                    # Histórico de mudanças
├── LICENSE.md                      # Licença MIT
├── DEMO.md                         # Este arquivo de demonstração
│
├── data/                           # Diretório de dados
│   ├── raw/                        # Dados brutos
│   └── processed/                  # Dados processados
│
├── scripts/                        # Scripts de análise
│   ├── 01_data_generation.R        # Geração de dados sintéticos
│   ├── 02_data_cleaning.R          # Limpeza de dados
│   ├── 03_exploratory_analysis.R   # Análise exploratória
│   ├── 04_statistical_analysis.R   # PCA e clustering
│   ├── 05_modeling.R               # Modelagem preditiva
│   └── run_all_analyses.R          # Execução completa
│
├── functions/                      # Funções customizadas
│   └── phenotype_functions.R       # Funções para análise de fenótipos
│
├── outputs/                        # Resultados
│   ├── figures/                    # Gráficos e visualizações
│   └── tables/                     # Tabelas de resultados
│
├── shiny_app/                      # Dashboard interativo
│   └── app.R                       # Aplicação Shiny completa
│
├── tests/                          # Testes unitários
│   └── test_functions.R            # Testes das funções
│
└── docs/                           # Documentação
    └── user_guide.md               # Guia completo do usuário
```

## Funcionalidades Implementadas

### 1. Geração de Dados Sintéticos
- **1000 indivíduos** com características realistas
- **Variáveis antropométricas**: altura, peso, IMC, circunferências
- **Biomarcadores**: glicose, colesterol, pressão arterial, hemoglobina
- **Demografia**: idade, sexo, etnia, estilo de vida
- **Correlações biologicamente plausíveis** entre variáveis

### 2. Análise Exploratória Completa
- Estatísticas descritivas detalhadas
- Distribuições de todas as variáveis
- Análises de correlação com significância
- Comparações por sexo e grupos
- Detecção automática de outliers
- Visualizações profissionais

### 3. Análises Estatísticas Avançadas
- **PCA (Análise de Componentes Principais)**
  - Redução dimensional
  - Identificação de fatores principais
  - Visualizações biplot e scree plot
  
- **Clustering**
  - K-means com determinação ótima de clusters
  - Clustering hierárquico
  - Caracterização de fenótipos
  - Visualizações no espaço PCA

### 4. Modelagem Preditiva
- **Random Forest para Diabetes**: Predição baseada em fatores de risco
- **Random Forest para Risco Cardiovascular**: Classificação de risco
- **Regressão para Pressão Arterial**: Predição de valores contínuos
- **Árvore de Decisão para Síndrome Metabólica**: Regras interpretáveis
- Avaliação completa com métricas de performance

### 5. Dashboard Interativo (Shiny)
- **5 abas principais** com funcionalidades distintas
- **Visão Geral**: Estatísticas populacionais
- **Distribuições**: Histogramas interativos
- **Correlações**: Matriz de correlação customizável
- **Comparações**: Boxplots e violin plots por grupos
- **Dados**: Tabela interativa com filtros e download

### 6. Funções Customizadas
- Cálculo de IMC e classificação
- Razão cintura-quadril
- Classificação de pressão arterial
- Cálculo de risco cardiovascular
- Detecção de outliers
- Normalização de variáveis
- Análises de correlação com p-values

### 7. Sistema de Testes
- Testes unitários para todas as funções
- Validação de cálculos médicos
- Testes de integração
- Relatórios automáticos de testes

## Como Executar o Projeto

### Pré-requisitos
```r
# R versão 4.0 ou superior
# RStudio (recomendado)
```

### Instalação Rápida
```r
# 1. Executar setup (instala pacotes e cria estrutura)
source("setup.R")

# 2. Executar todas as análises
source("scripts/run_all_analyses.R")

# 3. Abrir dashboard interativo
shiny::runApp("shiny_app/")
```

### Execução Passo a Passo
```r
# Gerar dados sintéticos
source("scripts/01_data_generation.R")

# Limpeza de dados
source("scripts/02_data_cleaning.R")

# Análise exploratória
source("scripts/03_exploratory_analysis.R")

# Análises estatísticas avançadas
source("scripts/04_statistical_analysis.R")

# Modelagem preditiva
source("scripts/05_modeling.R")

# Executar testes
source("tests/test_functions.R")
```

## Resultados Esperados

### Dados Gerados
- Dataset com 1000 indivíduos
- 30+ variáveis fenotípicas
- Distribuições realistas por sexo e idade
- Correlações biologicamente plausíveis

### Visualizações Criadas
- 15+ gráficos de distribuições
- Matriz de correlação interativa
- Plots de PCA (scree plot, biplot)
- Visualizações de clusters
- Gráficos de importância de variáveis
- Dendrograma hierárquico

### Análises Estatísticas
- 3 clusters fenotípicos distintos
- PCA explicando ~70% da variância
- Correlações significativas (p < 0.05)
- Detecção de outliers (<5% dos dados)

### Modelos Preditivos
- **Diabetes**: Acurácia esperada >85%
- **Risco CV**: Acurácia esperada >80%
- **Pressão Arterial**: R² esperado >0.7
- **Síndrome Metabólica**: Acurácia esperada >90%

## Aplicações Práticas

### Pesquisa em Saúde
- Identificação de fenótipos de risco
- Análise de fatores de risco cardiovascular
- Estudos epidemiológicos
- Desenvolvimento de scores de risco

### Clínica
- Triagem de pacientes
- Estratificação de risco
- Monitoramento de populações
- Suporte à decisão clínica

### Educação
- Ensino de bioestatística
- Demonstração de análises multivariadas
- Treinamento em R e Shiny
- Exemplo de projeto completo

## Tecnologias e Pacotes Utilizados

### Core R Packages
- `tidyverse`: Manipulação e visualização
- `data.table`: Processamento eficiente
- `janitor`: Limpeza de dados

### Análises Estatísticas
- `cluster`, `factoextra`: Clustering
- `FactoMineR`: PCA
- `corrplot`: Correlações
- `psych`: Análises descritivas

### Modelagem
- `randomForest`: Random Forest
- `caret`: Machine Learning
- `rpart`: Árvores de decisão
- `glmnet`: Regressão regularizada

### Visualização
- `ggplot2`: Gráficos estáticos
- `plotly`: Gráficos interativos
- `pheatmap`: Heatmaps
- `RColorBrewer`: Paletas de cores

### Dashboard
- `shiny`: Aplicações web
- `shinydashboard`: Layout
- `DT`: Tabelas interativas
- `shinyWidgets`: Widgets avançados

## Próximos Passos

### Para Uso com Dados Reais
1. Validar funções com especialistas médicos
2. Ajustar parâmetros para população específica
3. Implementar validação cruzada rigorosa

### Melhorias Futuras
1. Análises longitudinais
2. Integração com dados genômicos
3. Modelos de machine learning avançados
4. API REST para integração externa
5. Deploy em servidor web

## Conclusão

Este projeto demonstra uma implementação completa e profissional de análise de fenótipos em saúde usando R. O código é modular, bem documentado e inclui todas as funcionalidades necessárias para análises reais de dados de saúde.

A estrutura criada serve como:
- **Aprendizado e Testes** para quem quiser testar
- **Template Básico** para projetos similares
- **Ferramenta educacional** para ensino de bioestatística
- **Base** para pesquisas em epidemiologia
- **Exemplo** de boas práticas em análise de dados

O projeto está em andamento e pode ser adaptado para diferentes contextos e tipos de dados fenotípicos.
