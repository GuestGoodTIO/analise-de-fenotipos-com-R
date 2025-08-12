# =============================================================================
# SETUP.R - Configuração e Instalação de Dependências
# Projeto: Análise de Fenótipos em Saúde
# =============================================================================

# Função para instalar pacotes se não estiverem instalados
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    install.packages(new_packages, dependencies = TRUE)
  }
}

# Lista de pacotes necessários
required_packages <- c(
  # Manipulação de dados
  "tidyverse",      # dplyr, ggplot2, tidyr, etc.
  "data.table",     # Manipulação eficiente de dados
  "janitor",        # Limpeza de dados
  
  # Análises estatísticas
  "corrplot",       # Visualização de correlações
  "cluster",        # Análises de clustering
  "factoextra",     # Visualização de PCA e clustering
  "FactoMineR",     # Análise de componentes principais
  "psych",          # Análises psicométricas e descritivas
  
  # Modelagem
  "randomForest",   # Random Forest
  "caret",          # Classification and Regression Training
  "glmnet",         # Regularized regression
  "rpart",          # Decision trees
  "rpart.plot",     # Visualização de árvores
  
  # Visualização
  "ggplot2",        # Gráficos
  "plotly",         # Gráficos interativos
  "ggcorrplot",     # Correlações com ggplot2
  "pheatmap",       # Heatmaps
  "RColorBrewer",   # Paletas de cores
  "viridis",        # Paletas de cores científicas
  
  # Dashboard e interatividade
  "shiny",          # Aplicações web
  "shinydashboard", # Layout para dashboards
  "DT",             # Tabelas interativas
  "shinyWidgets",   # Widgets adicionais para Shiny
  
  # Relatórios
  "rmarkdown",      # Documentos dinâmicos
  "knitr",          # Geração de relatórios
  "kableExtra",     # Tabelas formatadas
  
  # Utilitários
  "here",           # Caminhos de arquivos
  "readxl",         # Leitura de arquivos Excel
  "writexl",        # Escrita de arquivos Excel
  "lubridate",      # Manipulação de datas
  "scales"          # Formatação de escalas
)

# Instalar pacotes
cat("Instalando pacotes necessários...\n")
install_if_missing(required_packages)

# Carregar bibliotecas principais
library(tidyverse)
library(here)

# Criar estrutura de diretórios
cat("Criando estrutura de diretórios...\n")

directories <- c(
  "data",
  "data/raw",
  "data/processed",
  "scripts",
  "functions",
  "outputs",
  "outputs/figures",
  "outputs/tables",
  "shiny_app",
  "tests",
  "docs"
)

for (dir in directories) {
  if (!dir.exists(here(dir))) {
    dir.create(here(dir), recursive = TRUE)
    cat("Criado:", dir, "\n")
  }
}

# Configurações globais
options(
  scipen = 999,           # Evitar notação científica
  digits = 4,             # Número de dígitos
  stringsAsFactors = FALSE # Não converter strings em fatores automaticamente
)

# Tema padrão para ggplot2
theme_set(theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10)
  ))

# Paleta de cores personalizada
custom_colors <- c(
  "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
  "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"
)

cat("Setup concluído com sucesso!\n")
cat("Estrutura de diretórios criada.\n")
cat("Pacotes instalados e carregados.\n")
cat("Configurações globais definidas.\n")
