# =============================================================================
# RUN_ALL_ANALYSES.R - Script Principal para Executar Todas as Análises
# =============================================================================

cat("=== PROJETO DE ANÁLISE DE FENÓTIPOS EM SAÚDE ===\n")
cat("Executando todas as análises do projeto...\n\n")

# Verificar se o setup foi executado
if (!file.exists("data")) {
  cat("Executando setup inicial...\n")
  source("setup.R")
}

# =============================================================================
# 1. GERAÇÃO DE DADOS
# =============================================================================

cat("1. GERAÇÃO DE DADOS SINTÉTICOS\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

if (!file.exists("data/processed/phenotype_data.csv")) {
  cat("Gerando dados sintéticos...\n")
  source("scripts/01_data_generation.R")
} else {
  cat("Dados já existem. Pulando geração...\n")
}

# =============================================================================
# 2. ANÁLISE EXPLORATÓRIA
# =============================================================================

cat("\n2. ANÁLISE EXPLORATÓRIA\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

cat("Executando análise exploratória...\n")
source("scripts/03_exploratory_analysis.R")

# =============================================================================
# 3. ANÁLISES ESTATÍSTICAS AVANÇADAS
# =============================================================================

cat("\n3. ANÁLISES ESTATÍSTICAS AVANÇADAS\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

cat("Executando análises de clustering e PCA...\n")
source("scripts/04_statistical_analysis.R")

# =============================================================================
# 4. MODELAGEM PREDITIVA
# =============================================================================

cat("\n4. MODELAGEM PREDITIVA\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

cat("Executando modelagem preditiva...\n")
source("scripts/05_modeling.R")

# =============================================================================
# 5. RESUMO FINAL
# =============================================================================

cat("\n5. RESUMO FINAL\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Verificar arquivos gerados
output_files <- list.files("outputs", recursive = TRUE, full.names = TRUE)
cat("Arquivos de saída gerados:\n")
for (file in output_files) {
  cat("-", file, "\n")
}

cat("\n=== ANÁLISES CONCLUÍDAS COM SUCESSO! ===\n")
cat("Resultados disponíveis em:\n")
cat("- outputs/figures/ (gráficos e visualizações)\n")
cat("- outputs/tables/ (tabelas e estatísticas)\n")
cat("\nPara visualizar o dashboard interativo, execute:\n")
cat("shiny::runApp('shiny_app/')\n")

# Criar relatório de execução
execution_report <- data.frame(
  Script = c("01_data_generation.R", "03_exploratory_analysis.R", 
            "04_statistical_analysis.R", "05_modeling.R"),
  Status = "Concluído",
  Timestamp = Sys.time(),
  stringsAsFactors = FALSE
)

write.csv(execution_report, "outputs/execution_report.csv", row.names = FALSE)

cat("\nRelatório de execução salvo em: outputs/execution_report.csv\n")
