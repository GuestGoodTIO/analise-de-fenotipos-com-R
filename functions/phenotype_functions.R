# =============================================================================
# PHENOTYPE_FUNCTIONS.R - Funções Customizadas para Análise de Fenótipos
# =============================================================================

# Função para calcular IMC
calculate_bmi <- function(weight_kg, height_cm) {
  height_m <- height_cm / 100
  bmi <- weight_kg / (height_m^2)
  return(round(bmi, 2))
}

# Função para classificar IMC
classify_bmi <- function(bmi) {
  case_when(
    bmi < 18.5 ~ "Baixo peso",
    bmi >= 18.5 & bmi < 25 ~ "Normal",
    bmi >= 25 & bmi < 30 ~ "Sobrepeso",
    bmi >= 30 ~ "Obesidade"
  )
}

# Função para calcular razão cintura-quadril
calculate_whr <- function(waist_cm, hip_cm) {
  whr <- waist_cm / hip_cm
  return(round(whr, 3))
}

# Função para classificar pressão arterial
classify_blood_pressure <- function(systolic, diastolic) {
  case_when(
    systolic < 120 & diastolic < 80 ~ "Normal",
    systolic >= 120 & systolic < 130 & diastolic < 80 ~ "Elevada",
    (systolic >= 130 & systolic < 140) | (diastolic >= 80 & diastolic < 90) ~ "Hipertensão Estágio 1",
    systolic >= 140 | diastolic >= 90 ~ "Hipertensão Estágio 2"
  )
}

# Função para calcular risco cardiovascular baseado em colesterol
calculate_cv_risk <- function(total_chol, hdl_chol, age, sex) {
  # Simplificado - baseado em diretrizes gerais
  ldl_hdl_ratio <- (total_chol - hdl_chol) / hdl_chol
  
  risk_score <- case_when(
    ldl_hdl_ratio < 2.5 ~ 1,
    ldl_hdl_ratio >= 2.5 & ldl_hdl_ratio < 3.5 ~ 2,
    ldl_hdl_ratio >= 3.5 ~ 3
  )
  
  # Ajuste por idade
  age_factor <- case_when(
    age < 40 ~ 0,
    age >= 40 & age < 50 ~ 1,
    age >= 50 & age < 60 ~ 2,
    age >= 60 ~ 3
  )
  
  # Ajuste por sexo (homens têm risco ligeiramente maior)
  sex_factor <- ifelse(sex == "M", 1, 0)
  
  total_risk <- risk_score + age_factor + sex_factor
  
  case_when(
    total_risk <= 2 ~ "Baixo",
    total_risk > 2 & total_risk <= 4 ~ "Moderado",
    total_risk > 4 ~ "Alto"
  )
}

# Função para detectar outliers usando IQR
detect_outliers <- function(x, k = 1.5) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  
  lower_bound <- q1 - k * iqr
  upper_bound <- q3 + k * iqr
  
  outliers <- which(x < lower_bound | x > upper_bound)
  return(outliers)
}

# Função para normalizar variáveis (z-score)
normalize_variables <- function(data, variables) {
  data_normalized <- data
  for (var in variables) {
    if (var %in% names(data) && is.numeric(data[[var]])) {
      data_normalized[[paste0(var, "_norm")]] <- scale(data[[var]])[,1]
    }
  }
  return(data_normalized)
}

# Função para criar summary estatístico personalizado
custom_summary <- function(data, group_var = NULL) {
  if (is.null(group_var)) {
    summary_stats <- data %>%
      select(where(is.numeric)) %>%
      summarise(across(everything(), list(
        mean = ~mean(.x, na.rm = TRUE),
        median = ~median(.x, na.rm = TRUE),
        sd = ~sd(.x, na.rm = TRUE),
        min = ~min(.x, na.rm = TRUE),
        max = ~max(.x, na.rm = TRUE),
        q25 = ~quantile(.x, 0.25, na.rm = TRUE),
        q75 = ~quantile(.x, 0.75, na.rm = TRUE)
      ))) %>%
      pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
      separate(variable, into = c("variable", "statistic"), sep = "_(?=[^_]*$)") %>%
      pivot_wider(names_from = statistic, values_from = value)
  } else {
    summary_stats <- data %>%
      select(all_of(group_var), where(is.numeric)) %>%
      group_by(across(all_of(group_var))) %>%
      summarise(across(where(is.numeric), list(
        mean = ~mean(.x, na.rm = TRUE),
        median = ~median(.x, na.rm = TRUE),
        sd = ~sd(.x, na.rm = TRUE)
      )), .groups = "drop") %>%
      pivot_longer(-all_of(group_var), names_to = "variable", values_to = "value") %>%
      separate(variable, into = c("variable", "statistic"), sep = "_(?=[^_]*$)") %>%
      pivot_wider(names_from = statistic, values_from = value)
  }
  
  return(summary_stats)
}

# Função para criar matriz de correlação com significância
correlation_matrix_with_p <- function(data, method = "pearson") {
  numeric_data <- data %>% select(where(is.numeric))
  
  cor_matrix <- cor(numeric_data, use = "complete.obs", method = method)
  
  # Calcular p-values
  p_matrix <- matrix(NA, nrow = ncol(numeric_data), ncol = ncol(numeric_data))
  colnames(p_matrix) <- rownames(p_matrix) <- colnames(numeric_data)
  
  for (i in 1:ncol(numeric_data)) {
    for (j in 1:ncol(numeric_data)) {
      if (i != j) {
        test_result <- cor.test(numeric_data[,i], numeric_data[,j], method = method)
        p_matrix[i,j] <- test_result$p.value
      } else {
        p_matrix[i,j] <- 0
      }
    }
  }
  
  return(list(correlation = cor_matrix, p_values = p_matrix))
}

# Função para plotar distribuições por grupo
plot_distributions_by_group <- function(data, variable, group_var, title = NULL) {
  if (is.null(title)) {
    title <- paste("Distribuição de", variable, "por", group_var)
  }
  
  p <- ggplot(data, aes_string(x = variable, fill = group_var)) +
    geom_density(alpha = 0.7) +
    facet_wrap(as.formula(paste("~", group_var)), scales = "free_y") +
    labs(title = title,
         x = variable,
         y = "Densidade") +
    theme_minimal() +
    theme(legend.position = "none")
  
  return(p)
}

# Função para identificar variáveis com alta correlação
find_high_correlations <- function(cor_matrix, threshold = 0.7) {
  cor_matrix[upper.tri(cor_matrix, diag = TRUE)] <- NA
  
  high_cor <- which(abs(cor_matrix) > threshold, arr.ind = TRUE)
  
  if (nrow(high_cor) > 0) {
    high_cor_df <- data.frame(
      var1 = rownames(cor_matrix)[high_cor[,1]],
      var2 = colnames(cor_matrix)[high_cor[,2]],
      correlation = cor_matrix[high_cor],
      stringsAsFactors = FALSE
    ) %>%
      arrange(desc(abs(correlation)))
    
    return(high_cor_df)
  } else {
    return(data.frame())
  }
}
