# =============================================================================
# 02_DATA_CLEANING.R - Limpeza e Preparação de Dados
# =============================================================================

# Carregar bibliotecas e funções
source("setup.R")
source("functions/phenotype_functions.R")

library(janitor)

cat("=== LIMPEZA E PREPARAÇÃO DE DADOS ===\n")

# =============================================================================
# 1. CARREGAR DADOS BRUTOS
# =============================================================================

cat("1. CARREGANDO DADOS BRUTOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Verificar se os dados brutos existem
if (!file.exists("data/raw/phenotype_data_raw.csv")) {
  cat("Dados brutos não encontrados. Executando geração de dados...\n")
  source("scripts/01_data_generation.R")
}

# Carregar dados brutos
raw_data <- read_csv("data/raw/phenotype_data_raw.csv")

cat("Dados brutos carregados:", nrow(raw_data), "linhas,", ncol(raw_data), "colunas\n")

# =============================================================================
# 2. VERIFICAÇÃO INICIAL DOS DADOS
# =============================================================================

cat("\n2. VERIFICAÇÃO INICIAL DOS DADOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Estrutura dos dados
cat("Estrutura dos dados:\n")
str(raw_data)

# Verificar valores faltantes
missing_summary <- raw_data %>%
  summarise_all(~sum(is.na(.))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(missing_percent = round(missing_count / nrow(raw_data) * 100, 2)) %>%
  filter(missing_count > 0) %>%
  arrange(desc(missing_count))

if (nrow(missing_summary) > 0) {
  cat("\nValores faltantes por variável:\n")
  print(missing_summary)
} else {
  cat("\nNenhum valor faltante encontrado.\n")
}

# Verificar duplicatas
duplicates <- raw_data %>%
  group_by(subject_id) %>%
  filter(n() > 1) %>%
  nrow()

cat("Registros duplicados:", duplicates, "\n")

# =============================================================================
# 3. LIMPEZA DE DADOS
# =============================================================================

cat("\n3. LIMPEZA DE DADOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Iniciar com dados limpos
clean_data <- raw_data

# Limpar nomes das colunas (se necessário)
clean_data <- clean_data %>% clean_names()

# Verificar e corrigir tipos de dados
clean_data <- clean_data %>%
  mutate(
    # Garantir que IDs são caracteres
    subject_id = as.character(subject_id),
    
    # Garantir que variáveis categóricas são fatores
    sex = factor(sex, levels = c("M", "F")),
    ethnicity = factor(ethnicity),
    smoking_status = factor(smoking_status, 
                           levels = c("Nunca fumou", "Ex-fumante", "Fumante atual")),
    alcohol_consumption = factor(alcohol_consumption,
                                levels = c("Não bebe", "Moderado", "Excessivo")),
    physical_activity = factor(physical_activity,
                              levels = c("Sedentário", "Leve", "Moderado", "Intenso")),
    bmi_category = factor(bmi_category,
                         levels = c("Baixo peso", "Normal", "Sobrepeso", "Obesidade")),
    bp_category = factor(bp_category),
    cv_risk = factor(cv_risk, levels = c("Baixo", "Moderado", "Alto")),
    diabetes_status = factor(diabetes_status,
                            levels = c("Normal", "Pré-diabetes", "Diabetes")),
    metabolic_syndrome = factor(metabolic_syndrome, levels = c("Não", "Sim")),
    family_history_diabetes = factor(family_history_diabetes, levels = c("Não", "Sim")),
    family_history_cvd = factor(family_history_cvd, levels = c("Não", "Sim"))
  )

# =============================================================================
# 4. VALIDAÇÃO DE DADOS
# =============================================================================

cat("4. VALIDAÇÃO DE DADOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Função para validar ranges de variáveis
validate_ranges <- function(data) {
  validation_results <- list()
  
  # Validar idade
  age_issues <- data %>%
    filter(age < 18 | age > 100) %>%
    nrow()
  validation_results$age <- paste("Idades fora do range (18-100):", age_issues)
  
  # Validar IMC
  bmi_issues <- data %>%
    filter(bmi < 10 | bmi > 60) %>%
    nrow()
  validation_results$bmi <- paste("IMC fora do range (10-60):", bmi_issues)
  
  # Validar pressão arterial
  bp_issues <- data %>%
    filter(systolic_bp_mmhg < 80 | systolic_bp_mmhg > 250 |
           diastolic_bp_mmhg < 40 | diastolic_bp_mmhg > 150) %>%
    nrow()
  validation_results$bp <- paste("Pressão arterial fora do range:", bp_issues)
  
  # Validar glicose
  glucose_issues <- data %>%
    filter(glucose_mg_dl < 50 | glucose_mg_dl > 400) %>%
    nrow()
  validation_results$glucose <- paste("Glicose fora do range (50-400):", glucose_issues)
  
  return(validation_results)
}

validation_results <- validate_ranges(clean_data)

cat("Resultados da validação:\n")
for (result in validation_results) {
  cat("-", result, "\n")
}

# =============================================================================
# 5. DETECÇÃO E TRATAMENTO DE OUTLIERS
# =============================================================================

cat("\n5. DETECÇÃO E TRATAMENTO DE OUTLIERS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Variáveis numéricas para análise de outliers
numeric_vars <- c("age", "height_cm", "weight_kg", "bmi", "waist_circumference_cm",
                 "body_fat_percentage", "glucose_mg_dl", "total_cholesterol_mg_dl",
                 "hdl_cholesterol_mg_dl", "triglycerides_mg_dl", "systolic_bp_mmhg",
                 "diastolic_bp_mmhg", "crp_mg_l")

# Detectar outliers para cada variável
outlier_summary <- tibble()

for (var in numeric_vars) {
  if (var %in% names(clean_data)) {
    outliers <- detect_outliers(clean_data[[var]])
    
    outlier_summary <- bind_rows(outlier_summary,
      tibble(
        variable = var,
        n_outliers = length(outliers),
        percent_outliers = round(length(outliers) / nrow(clean_data) * 100, 2),
        outlier_threshold = ifelse(length(outliers) > 0, "Detectados", "Nenhum")
      )
    )
  }
}

cat("Resumo de outliers:\n")
print(outlier_summary)

# Salvar resumo de outliers
write_csv(outlier_summary, "outputs/tables/outlier_detection_summary.csv")

# Marcar outliers extremos (opcional - não remover automaticamente)
clean_data <- clean_data %>%
  mutate(
    outlier_flag = case_when(
      bmi > 50 | bmi < 12 ~ "BMI_extreme",
      systolic_bp_mmhg > 220 | systolic_bp_mmhg < 70 ~ "BP_extreme",
      glucose_mg_dl > 350 | glucose_mg_dl < 60 ~ "Glucose_extreme",
      TRUE ~ "Normal"
    )
  )

extreme_outliers <- clean_data %>%
  filter(outlier_flag != "Normal") %>%
  nrow()

cat("Outliers extremos marcados:", extreme_outliers, "\n")

# =============================================================================
# 6. CRIAÇÃO DE VARIÁVEIS DERIVADAS
# =============================================================================

cat("\n6. CRIAÇÃO DE VARIÁVEIS DERIVADAS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Criar variáveis derivadas adicionais
clean_data <- clean_data %>%
  mutate(
    # Categorias de idade
    age_group = case_when(
      age < 30 ~ "18-29",
      age >= 30 & age < 40 ~ "30-39",
      age >= 40 & age < 50 ~ "40-49",
      age >= 50 & age < 60 ~ "50-59",
      age >= 60 ~ "60+"
    ),
    
    # Razão LDL/HDL
    ldl_hdl_ratio = round(ldl_cholesterol_mg_dl / hdl_cholesterol_mg_dl, 2),
    
    # Pressão arterial média
    mean_arterial_pressure = round((systolic_bp_mmhg + 2 * diastolic_bp_mmhg) / 3, 1),
    
    # Score de risco metabólico (simplificado)
    metabolic_risk_score = case_when(
      bmi >= 30 ~ 3,
      bmi >= 25 ~ 2,
      bmi >= 23 ~ 1,
      TRUE ~ 0
    ) + case_when(
      systolic_bp_mmhg >= 140 ~ 2,
      systolic_bp_mmhg >= 130 ~ 1,
      TRUE ~ 0
    ) + case_when(
      glucose_mg_dl >= 126 ~ 3,
      glucose_mg_dl >= 100 ~ 1,
      TRUE ~ 0
    ),
    
    # Converter para fator
    age_group = factor(age_group, levels = c("18-29", "30-39", "40-49", "50-59", "60+"))
  )

cat("Variáveis derivadas criadas:\n")
cat("- age_group: Grupos etários\n")
cat("- ldl_hdl_ratio: Razão LDL/HDL\n")
cat("- mean_arterial_pressure: Pressão arterial média\n")
cat("- metabolic_risk_score: Score de risco metabólico\n")

# =============================================================================
# 7. VERIFICAÇÃO FINAL E SALVAMENTO
# =============================================================================

cat("\n7. VERIFICAÇÃO FINAL E SALVAMENTO\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Verificação final
cat("Dados finais:\n")
cat("- Linhas:", nrow(clean_data), "\n")
cat("- Colunas:", ncol(clean_data), "\n")
cat("- Valores faltantes totais:", sum(is.na(clean_data)), "\n")

# Resumo das variáveis categóricas
cat("\nDistribuição das principais variáveis categóricas:\n")
categorical_summary <- clean_data %>%
  select(sex, age_group, bmi_category, diabetes_status, cv_risk) %>%
  summarise_all(~paste(table(.), collapse = ", "))

print(categorical_summary)

# Salvar dados limpos
write_csv(clean_data, "data/processed/phenotype_data.csv")

# Criar relatório de limpeza
cleaning_report <- tibble(
  step = c("Dados originais", "Após limpeza", "Outliers extremos", "Variáveis derivadas"),
  n_rows = c(nrow(raw_data), nrow(clean_data), extreme_outliers, 4),
  n_cols = c(ncol(raw_data), ncol(clean_data), NA, NA),
  description = c("Dados brutos carregados", "Dados limpos e validados", 
                 "Outliers marcados", "Novas variáveis criadas")
)

write_csv(cleaning_report, "outputs/tables/data_cleaning_report.csv")

cat("\nLimpeza de dados concluída!\n")
cat("Dados salvos em: data/processed/phenotype_data.csv\n")
cat("Relatório salvo em: outputs/tables/data_cleaning_report.csv\n")
