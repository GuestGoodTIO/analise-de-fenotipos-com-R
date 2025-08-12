# =============================================================================
# 01_DATA_GENERATION.R - Geração de Dados Sintéticos de Fenótipos
# =============================================================================

# Carregar bibliotecas e funções
source("setup.R")
source("functions/phenotype_functions.R")

set.seed(42)  # Para reprodutibilidade

# Parâmetros da simulação
n_subjects <- 1000  # Número de indivíduos

cat("Gerando dados sintéticos para", n_subjects, "indivíduos...\n")

# =============================================================================
# DADOS DEMOGRÁFICOS E BÁSICOS
# =============================================================================

phenotype_data <- tibble(
  # ID único
  subject_id = paste0("SUB_", str_pad(1:n_subjects, 4, pad = "0")),
  
  # Demografia
  age = round(rnorm(n_subjects, mean = 45, sd = 15)),
  sex = sample(c("M", "F"), n_subjects, replace = TRUE, prob = c(0.48, 0.52)),
  ethnicity = sample(c("Caucasiano", "Afrodescendente", "Asiático", "Hispânico", "Outro"), 
                    n_subjects, replace = TRUE, 
                    prob = c(0.6, 0.15, 0.1, 0.1, 0.05)),
  
  # Estilo de vida
  smoking_status = sample(c("Nunca fumou", "Ex-fumante", "Fumante atual"), 
                         n_subjects, replace = TRUE, 
                         prob = c(0.6, 0.25, 0.15)),
  alcohol_consumption = sample(c("Não bebe", "Moderado", "Excessivo"), 
                              n_subjects, replace = TRUE, 
                              prob = c(0.3, 0.6, 0.1)),
  physical_activity = sample(c("Sedentário", "Leve", "Moderado", "Intenso"), 
                            n_subjects, replace = TRUE, 
                            prob = c(0.3, 0.3, 0.3, 0.1))
) %>%
  # Ajustar idade para valores realistas
  mutate(age = pmax(18, pmin(80, age)))

# =============================================================================
# MEDIDAS ANTROPOMÉTRICAS
# =============================================================================

# Altura baseada em sexo e etnia
phenotype_data <- phenotype_data %>%
  mutate(
    # Altura (cm) - diferenças por sexo e etnia
    height_cm = case_when(
      sex == "M" & ethnicity == "Caucasiano" ~ rnorm(n(), 175, 7),
      sex == "M" & ethnicity == "Afrodescendente" ~ rnorm(n(), 177, 7),
      sex == "M" & ethnicity == "Asiático" ~ rnorm(n(), 170, 6),
      sex == "M" & ethnicity == "Hispânico" ~ rnorm(n(), 172, 6),
      sex == "F" & ethnicity == "Caucasiano" ~ rnorm(n(), 162, 6),
      sex == "F" & ethnicity == "Afrodescendente" ~ rnorm(n(), 164, 6),
      sex == "F" & ethnicity == "Asiático" ~ rnorm(n(), 157, 5),
      sex == "F" & ethnicity == "Hispânico" ~ rnorm(n(), 159, 5),
      TRUE ~ rnorm(n(), 168, 8)
    ),
    
    # Peso (kg) - correlacionado com altura e idade
    weight_kg = height_cm * 0.4 + age * 0.3 + rnorm(n(), 0, 8) + 
                ifelse(sex == "M", 10, -5),
    
    # Ajustar para valores realistas
    height_cm = round(pmax(140, pmin(210, height_cm)), 1),
    weight_kg = round(pmax(40, pmin(150, weight_kg)), 1)
  ) %>%
  # Calcular IMC
  mutate(
    bmi = calculate_bmi(weight_kg, height_cm),
    bmi_category = classify_bmi(bmi)
  )

# Medidas corporais adicionais
phenotype_data <- phenotype_data %>%
  mutate(
    # Circunferência da cintura (correlacionada com IMC)
    waist_circumference_cm = round(60 + bmi * 2.5 + rnorm(n(), 0, 5), 1),
    
    # Circunferência do quadril
    hip_circumference_cm = round(waist_circumference_cm * 1.1 + rnorm(n(), 0, 3), 1),
    
    # Percentual de gordura corporal
    body_fat_percentage = case_when(
      sex == "M" ~ pmax(5, pmin(35, 10 + (bmi - 20) * 1.2 + rnorm(n(), 0, 3))),
      sex == "F" ~ pmax(10, pmin(45, 18 + (bmi - 20) * 1.5 + rnorm(n(), 0, 4)))
    ),
    
    # Ajustar circunferências para valores realistas
    waist_circumference_cm = pmax(60, pmin(130, waist_circumference_cm)),
    hip_circumference_cm = pmax(70, pmin(140, hip_circumference_cm))
  ) %>%
  # Calcular razão cintura-quadril
  mutate(
    waist_hip_ratio = calculate_whr(waist_circumference_cm, hip_circumference_cm)
  )

# =============================================================================
# BIOMARCADORES SANGUÍNEOS
# =============================================================================

phenotype_data <- phenotype_data %>%
  mutate(
    # Glicose em jejum (mg/dL) - influenciada por IMC e idade
    glucose_mg_dl = round(85 + (bmi - 22) * 2 + (age - 40) * 0.5 + 
                         rnorm(n(), 0, 10), 0),
    
    # Colesterol total (mg/dL)
    total_cholesterol_mg_dl = round(180 + age * 0.8 + (bmi - 22) * 3 + 
                                   rnorm(n(), 0, 25), 0),
    
    # HDL colesterol (mg/dL) - maior em mulheres
    hdl_cholesterol_mg_dl = round(ifelse(sex == "F", 55, 45) - (bmi - 22) * 0.8 + 
                                 rnorm(n(), 0, 8), 0),
    
    # LDL colesterol (calculado)
    ldl_cholesterol_mg_dl = round(total_cholesterol_mg_dl - hdl_cholesterol_mg_dl - 
                                 rnorm(n(), 30, 10), 0),
    
    # Triglicerídeos (mg/dL)
    triglycerides_mg_dl = round(100 + (bmi - 22) * 8 + age * 0.5 + 
                               rnorm(n(), 0, 40), 0),
    
    # Hemoglobina (g/dL) - maior em homens
    hemoglobin_g_dl = round(ifelse(sex == "M", 15, 13) + rnorm(n(), 0, 1), 1),
    
    # Proteína C-reativa (mg/L) - marcador inflamatório
    crp_mg_l = round(exp(rnorm(n(), log(2), 0.8)), 2),
    
    # Ajustar para valores realistas
    glucose_mg_dl = pmax(70, pmin(300, glucose_mg_dl)),
    total_cholesterol_mg_dl = pmax(120, pmin(350, total_cholesterol_mg_dl)),
    hdl_cholesterol_mg_dl = pmax(25, pmin(100, hdl_cholesterol_mg_dl)),
    ldl_cholesterol_mg_dl = pmax(50, pmin(250, ldl_cholesterol_mg_dl)),
    triglycerides_mg_dl = pmax(50, pmin(500, triglycerides_mg_dl)),
    hemoglobin_g_dl = pmax(8, pmin(18, hemoglobin_g_dl)),
    crp_mg_l = pmax(0.1, pmin(20, crp_mg_l))
  )

# =============================================================================
# PRESSÃO ARTERIAL
# =============================================================================

phenotype_data <- phenotype_data %>%
  mutate(
    # Pressão sistólica (mmHg) - influenciada por idade, IMC e estilo de vida
    systolic_bp_mmhg = round(110 + age * 0.6 + (bmi - 22) * 1.5 + 
                            ifelse(smoking_status == "Fumante atual", 8, 0) +
                            ifelse(physical_activity == "Sedentário", 5, 0) +
                            rnorm(n(), 0, 12), 0),
    
    # Pressão diastólica (mmHg)
    diastolic_bp_mmhg = round(70 + age * 0.3 + (bmi - 22) * 0.8 + 
                             ifelse(smoking_status == "Fumante atual", 4, 0) +
                             rnorm(n(), 0, 8), 0),
    
    # Ajustar para valores realistas
    systolic_bp_mmhg = pmax(90, pmin(200, systolic_bp_mmhg)),
    diastolic_bp_mmhg = pmax(60, pmin(120, diastolic_bp_mmhg))
  ) %>%
  # Classificar pressão arterial
  mutate(
    bp_category = classify_blood_pressure(systolic_bp_mmhg, diastolic_bp_mmhg)
  )

# =============================================================================
# VARIÁVEIS DERIVADAS E CLASSIFICAÇÕES
# =============================================================================

phenotype_data <- phenotype_data %>%
  mutate(
    # Risco cardiovascular
    cv_risk = calculate_cv_risk(total_cholesterol_mg_dl, hdl_cholesterol_mg_dl, 
                               age, sex),
    
    # Síndrome metabólica (critérios simplificados)
    metabolic_syndrome = case_when(
      waist_circumference_cm > ifelse(sex == "M", 102, 88) &
      triglycerides_mg_dl > 150 &
      hdl_cholesterol_mg_dl < ifelse(sex == "M", 40, 50) &
      systolic_bp_mmhg > 130 ~ "Sim",
      TRUE ~ "Não"
    ),
    
    # Diabetes (baseado em glicose)
    diabetes_status = case_when(
      glucose_mg_dl >= 126 ~ "Diabetes",
      glucose_mg_dl >= 100 ~ "Pré-diabetes",
      TRUE ~ "Normal"
    ),
    
    # Histórico familiar (simulado)
    family_history_diabetes = sample(c("Sim", "Não"), n(), replace = TRUE, 
                                    prob = c(0.3, 0.7)),
    family_history_cvd = sample(c("Sim", "Não"), n(), replace = TRUE, 
                               prob = c(0.25, 0.75))
  )

# =============================================================================
# SALVAR DADOS
# =============================================================================

# Salvar dados brutos
write_csv(phenotype_data, "data/raw/phenotype_data_raw.csv")

# Criar versão com dados faltantes (mais realista)
phenotype_data_missing <- phenotype_data %>%
  mutate(
    # Introduzir alguns valores faltantes de forma realística
    crp_mg_l = ifelse(runif(n()) < 0.05, NA, crp_mg_l),
    body_fat_percentage = ifelse(runif(n()) < 0.08, NA, body_fat_percentage),
    triglycerides_mg_dl = ifelse(runif(n()) < 0.03, NA, triglycerides_mg_dl)
  )

write_csv(phenotype_data_missing, "data/processed/phenotype_data.csv")

# Resumo dos dados gerados
cat("\n=== RESUMO DOS DADOS GERADOS ===\n")
cat("Número de indivíduos:", nrow(phenotype_data), "\n")
cat("Número de variáveis:", ncol(phenotype_data), "\n")
cat("Distribuição por sexo:\n")
print(table(phenotype_data$sex))
cat("\nDistribuição por categoria de IMC:\n")
print(table(phenotype_data$bmi_category))
cat("\nEstatísticas de idade:\n")
print(summary(phenotype_data$age))

cat("\nDados salvos em:\n")
cat("- data/raw/phenotype_data_raw.csv\n")
cat("- data/processed/phenotype_data.csv\n")

cat("\nGeração de dados concluída com sucesso!\n")
