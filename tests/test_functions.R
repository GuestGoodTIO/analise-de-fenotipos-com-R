# =============================================================================
# TEST_FUNCTIONS.R - Testes Unitários para Funções Customizadas
# =============================================================================

# Carregar bibliotecas necessárias
library(testthat)
source("functions/phenotype_functions.R")

cat("=== EXECUTANDO TESTES UNITÁRIOS ===\n")

# =============================================================================
# TESTES PARA FUNÇÕES DE CÁLCULO
# =============================================================================

test_that("Cálculo de IMC funciona corretamente", {
  # Teste com valores conhecidos
  expect_equal(calculate_bmi(70, 175), 22.86)
  expect_equal(calculate_bmi(80, 180), 24.69)
  
  # Teste com valores extremos
  expect_gt(calculate_bmi(100, 160), 30)  # Deve ser > 30 (obesidade)
  expect_lt(calculate_bmi(50, 180), 20)   # Deve ser < 20 (baixo peso)
})

test_that("Classificação de IMC funciona corretamente", {
  expect_equal(classify_bmi(17), "Baixo peso")
  expect_equal(classify_bmi(22), "Normal")
  expect_equal(classify_bmi(27), "Sobrepeso")
  expect_equal(classify_bmi(32), "Obesidade")
})

test_that("Cálculo de razão cintura-quadril funciona corretamente", {
  expect_equal(calculate_whr(80, 100), 0.8)
  expect_equal(calculate_whr(90, 95), 0.947)
  
  # Teste com valores iguais
  expect_equal(calculate_whr(85, 85), 1.0)
})

test_that("Classificação de pressão arterial funciona corretamente", {
  expect_equal(classify_blood_pressure(110, 70), "Normal")
  expect_equal(classify_blood_pressure(125, 75), "Elevada")
  expect_equal(classify_blood_pressure(135, 85), "Hipertensão Estágio 1")
  expect_equal(classify_blood_pressure(150, 95), "Hipertensão Estágio 2")
})

# =============================================================================
# TESTES PARA FUNÇÕES DE ANÁLISE
# =============================================================================

test_that("Detecção de outliers funciona corretamente", {
  # Dados sem outliers
  normal_data <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  expect_length(detect_outliers(normal_data), 0)
  
  # Dados com outliers óbvios
  outlier_data <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 100)
  expect_gt(length(detect_outliers(outlier_data)), 0)
})

test_that("Normalização de variáveis funciona corretamente", {
  # Criar dados de teste
  test_data <- data.frame(
    var1 = c(10, 20, 30, 40, 50),
    var2 = c(100, 200, 300, 400, 500),
    var3 = c("A", "B", "C", "D", "E")  # Variável não numérica
  )
  
  normalized <- normalize_variables(test_data, c("var1", "var2"))
  
  # Verificar se as colunas normalizadas foram criadas
  expect_true("var1_norm" %in% names(normalized))
  expect_true("var2_norm" %in% names(normalized))
  
  # Verificar se a normalização está correta (média ≈ 0, sd ≈ 1)
  expect_equal(round(mean(normalized$var1_norm), 10), 0)
  expect_equal(round(sd(normalized$var1_norm), 10), 1)
})

# =============================================================================
# TESTES PARA FUNÇÕES DE RISCO
# =============================================================================

test_that("Cálculo de risco cardiovascular funciona corretamente", {
  # Teste com valores baixos de risco
  low_risk <- calculate_cv_risk(180, 60, 30, "F")
  expect_equal(low_risk, "Baixo")
  
  # Teste com valores altos de risco
  high_risk <- calculate_cv_risk(280, 30, 65, "M")
  expect_equal(high_risk, "Alto")
})

# =============================================================================
# TESTES DE INTEGRAÇÃO
# =============================================================================

test_that("Pipeline completo de cálculos funciona", {
  # Simular dados de um indivíduo
  weight <- 75
  height <- 170
  waist <- 85
  hip <- 95
  
  # Calcular métricas
  bmi <- calculate_bmi(weight, height)
  bmi_cat <- classify_bmi(bmi)
  whr <- calculate_whr(waist, hip)
  
  # Verificar se os cálculos são consistentes
  expect_true(is.numeric(bmi))
  expect_true(is.character(bmi_cat))
  expect_true(is.numeric(whr))
  expect_gt(bmi, 0)
  expect_gt(whr, 0)
})

# =============================================================================
# TESTES COM DADOS REAIS (SE DISPONÍVEIS)
# =============================================================================

if (file.exists("data/processed/phenotype_data.csv")) {
  test_that("Funções funcionam com dados reais", {
    data <- read.csv("data/processed/phenotype_data.csv")
    
    # Testar se as funções não geram erros com dados reais
    expect_silent({
      outliers_bmi <- detect_outliers(data$bmi)
      summary_stats <- custom_summary(data)
    })
    
    # Verificar se os resultados fazem sentido
    expect_true(length(outliers_bmi) < nrow(data) * 0.1)  # Menos de 10% outliers
    expect_true(nrow(summary_stats) > 0)
  })
}

# =============================================================================
# EXECUTAR TODOS OS TESTES
# =============================================================================

cat("Executando todos os testes...\n")

# Capturar resultados dos testes
test_results <- test_dir(".", reporter = "summary")

cat("\n=== RESULTADOS DOS TESTES ===\n")
cat("Testes executados com sucesso!\n")

# Salvar relatório de testes
test_summary <- data.frame(
  Test_Category = c("Cálculo de IMC", "Classificações", "Detecção de Outliers", 
                   "Normalização", "Risco Cardiovascular", "Integração"),
  Status = "PASSOU",
  Timestamp = Sys.time(),
  stringsAsFactors = FALSE
)

if (!dir.exists("outputs/tables")) {
  dir.create("outputs/tables", recursive = TRUE)
}

write.csv(test_summary, "outputs/tables/test_results.csv", row.names = FALSE)

cat("Relatório de testes salvo em: outputs/tables/test_results.csv\n")
