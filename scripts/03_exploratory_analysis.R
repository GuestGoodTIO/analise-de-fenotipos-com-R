# =============================================================================
# 03_EXPLORATORY_ANALYSIS.R - Análise Exploratória de Dados Fenotípicos
# =============================================================================

# Carregar bibliotecas e funções
source("setup.R")
source("functions/phenotype_functions.R")

library(corrplot)
library(ggcorrplot)
library(plotly)
library(pheatmap)

# Carregar dados
data <- read_csv("data/processed/phenotype_data.csv")

cat("=== ANÁLISE EXPLORATÓRIA DE DADOS FENOTÍPICOS ===\n")
cat("Dados carregados:", nrow(data), "indivíduos,", ncol(data), "variáveis\n\n")

# =============================================================================
# 1. ANÁLISE DESCRITIVA GERAL
# =============================================================================

cat("1. ANÁLISE DESCRITIVA GERAL\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Resumo das variáveis numéricas
numeric_vars <- data %>% select(where(is.numeric), -subject_id) %>% names()
summary_stats <- custom_summary(data)

# Salvar tabela de estatísticas descritivas
write_csv(summary_stats, "outputs/tables/descriptive_statistics.csv")

# Contagens das variáveis categóricas
categorical_vars <- data %>% select(where(is.character), -subject_id) %>% names()

cat("Variáveis categóricas:\n")
for (var in categorical_vars) {
  cat("\n", var, ":\n")
  print(table(data[[var]], useNA = "ifany"))
}

# =============================================================================
# 2. DISTRIBUIÇÕES DAS VARIÁVEIS PRINCIPAIS
# =============================================================================

cat("\n2. ANÁLISE DE DISTRIBUIÇÕES\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Função para criar histogramas das principais variáveis
create_distribution_plots <- function(data, variables, ncol = 3) {
  plots <- list()
  
  for (var in variables) {
    p <- ggplot(data, aes_string(x = var)) +
      geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7, color = "white") +
      geom_density(aes(y = ..density.. * nrow(data) * 
                      (max(get(var), na.rm = TRUE) - min(get(var), na.rm = TRUE)) / 30),
                  color = "red", size = 1) +
      labs(title = paste("Distribuição de", var),
           x = var, y = "Frequência") +
      theme_minimal()
    
    plots[[var]] <- p
  }
  
  return(plots)
}

# Principais variáveis antropométricas
anthro_vars <- c("age", "height_cm", "weight_kg", "bmi", "waist_circumference_cm")
anthro_plots <- create_distribution_plots(data, anthro_vars)

# Salvar plots
for (i in seq_along(anthro_plots)) {
  ggsave(paste0("outputs/figures/dist_", names(anthro_plots)[i], ".png"), 
         anthro_plots[[i]], width = 8, height = 6, dpi = 300)
}

# Principais biomarcadores
biomarker_vars <- c("glucose_mg_dl", "total_cholesterol_mg_dl", "hdl_cholesterol_mg_dl", 
                   "triglycerides_mg_dl", "systolic_bp_mmhg")
biomarker_plots <- create_distribution_plots(data, biomarker_vars)

for (i in seq_along(biomarker_plots)) {
  ggsave(paste0("outputs/figures/dist_", names(biomarker_plots)[i], ".png"), 
         biomarker_plots[[i]], width = 8, height = 6, dpi = 300)
}

# =============================================================================
# 3. ANÁLISE POR SEXO
# =============================================================================

cat("3. ANÁLISE POR SEXO\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Comparações por sexo
sex_comparison <- data %>%
  select(sex, all_of(numeric_vars)) %>%
  group_by(sex) %>%
  summarise(across(where(is.numeric), list(
    mean = ~mean(.x, na.rm = TRUE),
    sd = ~sd(.x, na.rm = TRUE),
    median = ~median(.x, na.rm = TRUE)
  )), .groups = "drop") %>%
  pivot_longer(-sex, names_to = "variable", values_to = "value") %>%
  separate(variable, into = c("variable", "statistic"), sep = "_(?=[^_]*$)") %>%
  pivot_wider(names_from = c(sex, statistic), values_from = value)

write_csv(sex_comparison, "outputs/tables/sex_comparison.csv")

# Boxplots por sexo para variáveis principais
create_sex_boxplots <- function(data, variables) {
  plots <- list()
  
  for (var in variables) {
    p <- ggplot(data, aes_string(x = "sex", y = var, fill = "sex")) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
      scale_fill_manual(values = c("F" = "#FF6B6B", "M" = "#4ECDC4")) +
      labs(title = paste(var, "por Sexo"),
           x = "Sexo", y = var) +
      theme_minimal() +
      theme(legend.position = "none")
    
    plots[[var]] <- p
  }
  
  return(plots)
}

sex_boxplots <- create_sex_boxplots(data, c("bmi", "systolic_bp_mmhg", 
                                           "total_cholesterol_mg_dl", "hdl_cholesterol_mg_dl"))

for (i in seq_along(sex_boxplots)) {
  ggsave(paste0("outputs/figures/sex_", names(sex_boxplots)[i], ".png"), 
         sex_boxplots[[i]], width = 8, height = 6, dpi = 300)
}

# =============================================================================
# 4. ANÁLISE DE CORRELAÇÕES
# =============================================================================

cat("4. ANÁLISE DE CORRELAÇÕES\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Matriz de correlação
numeric_data <- data %>% select(all_of(numeric_vars))
cor_result <- correlation_matrix_with_p(numeric_data)

# Correlações significativas (p < 0.05)
significant_cors <- which(cor_result$p_values < 0.05 & 
                         abs(cor_result$correlation) > 0.3, arr.ind = TRUE)

if (nrow(significant_cors) > 0) {
  sig_cor_df <- data.frame(
    var1 = rownames(cor_result$correlation)[significant_cors[,1]],
    var2 = colnames(cor_result$correlation)[significant_cors[,2]],
    correlation = cor_result$correlation[significant_cors],
    p_value = cor_result$p_values[significant_cors]
  ) %>%
    filter(var1 != var2) %>%
    arrange(desc(abs(correlation)))
  
  write_csv(sig_cor_df, "outputs/tables/significant_correlations.csv")
}

# Plot de correlação
cor_plot <- ggcorrplot(cor_result$correlation, 
                      method = "circle",
                      type = "lower",
                      lab = TRUE,
                      lab_size = 2.5,
                      title = "Matriz de Correlação - Variáveis Fenotípicas",
                      ggtheme = theme_minimal())

ggsave("outputs/figures/correlation_matrix.png", cor_plot, 
       width = 12, height = 10, dpi = 300)

# Heatmap de correlação mais detalhado
png("outputs/figures/correlation_heatmap.png", width = 1200, height = 1000, res = 150)
corrplot(cor_result$correlation, method = "color", type = "lower",
         order = "hclust", tl.cex = 0.8, tl.col = "black",
         title = "Matriz de Correlação - Dados Fenotípicos",
         mar = c(0,0,2,0))
dev.off()

# =============================================================================
# 5. ANÁLISE POR CATEGORIA DE IMC
# =============================================================================

cat("5. ANÁLISE POR CATEGORIA DE IMC\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Estatísticas por categoria de IMC
bmi_analysis <- data %>%
  group_by(bmi_category) %>%
  summarise(
    n = n(),
    age_mean = mean(age, na.rm = TRUE),
    systolic_bp_mean = mean(systolic_bp_mmhg, na.rm = TRUE),
    glucose_mean = mean(glucose_mg_dl, na.rm = TRUE),
    total_chol_mean = mean(total_cholesterol_mg_dl, na.rm = TRUE),
    hdl_chol_mean = mean(hdl_cholesterol_mg_dl, na.rm = TRUE),
    triglycerides_mean = mean(triglycerides_mg_dl, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(bmi_analysis, "outputs/tables/bmi_category_analysis.csv")

# Visualização por categoria de IMC
bmi_plot <- data %>%
  select(bmi_category, systolic_bp_mmhg, glucose_mg_dl, total_cholesterol_mg_dl) %>%
  pivot_longer(-bmi_category, names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = bmi_category, y = value, fill = bmi_category)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~variable, scales = "free_y", ncol = 2) +
  scale_fill_viridis_d() +
  labs(title = "Biomarcadores por Categoria de IMC",
       x = "Categoria de IMC", y = "Valor") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

ggsave("outputs/figures/bmi_category_biomarkers.png", bmi_plot, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# 6. DETECÇÃO DE OUTLIERS
# =============================================================================

cat("6. DETECÇÃO DE OUTLIERS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Detectar outliers nas principais variáveis
outlier_summary <- tibble()

for (var in c("bmi", "systolic_bp_mmhg", "glucose_mg_dl", "total_cholesterol_mg_dl")) {
  outliers <- detect_outliers(data[[var]])
  
  outlier_summary <- bind_rows(outlier_summary,
    tibble(
      variable = var,
      n_outliers = length(outliers),
      percent_outliers = round(length(outliers) / nrow(data) * 100, 2),
      outlier_ids = paste(data$subject_id[outliers], collapse = ", ")
    )
  )
}

write_csv(outlier_summary, "outputs/tables/outlier_summary.csv")

cat("Análise exploratória concluída!\n")
cat("Resultados salvos em outputs/figures/ e outputs/tables/\n")
