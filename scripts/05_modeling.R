# =============================================================================
# 05_MODELING.R - Modelagem Preditiva para Fenótipos
# =============================================================================

# Carregar bibliotecas e funções
source("setup.R")
source("functions/phenotype_functions.R")

library(randomForest)
library(caret)
library(rpart)
library(rpart.plot)
library(glmnet)

# Carregar dados
data <- read_csv("data/processed/phenotype_data.csv")

cat("=== MODELAGEM PREDITIVA ===\n")
cat("Desenvolvendo modelos para predição de características de saúde...\n\n")

# =============================================================================
# 1. PREPARAÇÃO DOS DADOS PARA MODELAGEM
# =============================================================================

cat("1. PREPARAÇÃO DOS DADOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Criar dataset completo para modelagem
modeling_data <- data %>%
  select(
    # Variáveis preditoras
    age, sex, height_cm, weight_kg, bmi, waist_circumference_cm,
    body_fat_percentage, physical_activity, smoking_status,
    family_history_diabetes, family_history_cvd,
    
    # Variáveis alvo
    diabetes_status, cv_risk, metabolic_syndrome, bp_category,
    glucose_mg_dl, total_cholesterol_mg_dl, systolic_bp_mmhg
  ) %>%
  na.omit()

cat("Dados para modelagem:", nrow(modeling_data), "indivíduos\n\n")

# Converter variáveis categóricas em fatores
modeling_data <- modeling_data %>%
  mutate(
    sex = as.factor(sex),
    physical_activity = as.factor(physical_activity),
    smoking_status = as.factor(smoking_status),
    family_history_diabetes = as.factor(family_history_diabetes),
    family_history_cvd = as.factor(family_history_cvd),
    diabetes_status = as.factor(diabetes_status),
    cv_risk = as.factor(cv_risk),
    metabolic_syndrome = as.factor(metabolic_syndrome),
    bp_category = as.factor(bp_category)
  )

# =============================================================================
# 2. MODELO 1: PREDIÇÃO DE DIABETES
# =============================================================================

cat("2. MODELO DE PREDIÇÃO DE DIABETES\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Preparar dados para predição de diabetes
diabetes_data <- modeling_data %>%
  select(age, sex, bmi, waist_circumference_cm, body_fat_percentage,
         physical_activity, smoking_status, family_history_diabetes,
         diabetes_status) %>%
  filter(diabetes_status != "Pré-diabetes")  # Focar em Normal vs Diabetes

diabetes_data$diabetes_status <- droplevels(diabetes_data$diabetes_status)

# Dividir em treino e teste
set.seed(42)
train_index <- createDataPartition(diabetes_data$diabetes_status, p = 0.7, list = FALSE)
train_diabetes <- diabetes_data[train_index, ]
test_diabetes <- diabetes_data[-train_index, ]

cat("Dados de treino:", nrow(train_diabetes), "\n")
cat("Dados de teste:", nrow(test_diabetes), "\n")
cat("Distribuição da variável alvo (treino):\n")
print(table(train_diabetes$diabetes_status))

# Random Forest para diabetes
set.seed(42)
rf_diabetes <- randomForest(diabetes_status ~ ., 
                           data = train_diabetes,
                           ntree = 500,
                           importance = TRUE)

# Predições
pred_diabetes <- predict(rf_diabetes, test_diabetes)
conf_matrix_diabetes <- confusionMatrix(pred_diabetes, test_diabetes$diabetes_status)

cat("\nPerformance do modelo Random Forest - Diabetes:\n")
print(conf_matrix_diabetes)

# Importância das variáveis
importance_diabetes <- importance(rf_diabetes)
importance_df_diabetes <- data.frame(
  variable = rownames(importance_diabetes),
  importance = importance_diabetes[, "MeanDecreaseGini"]
) %>%
  arrange(desc(importance))

write_csv(importance_df_diabetes, "outputs/tables/diabetes_model_importance.csv")

# Plot de importância
importance_plot_diabetes <- ggplot(importance_df_diabetes, 
                                  aes(x = reorder(variable, importance), y = importance)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Importância das Variáveis - Modelo de Diabetes",
       x = "Variáveis", y = "Importância (Mean Decrease Gini)") +
  theme_minimal()

ggsave("outputs/figures/diabetes_model_importance.png", importance_plot_diabetes, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# 3. MODELO 2: PREDIÇÃO DE RISCO CARDIOVASCULAR
# =============================================================================

cat("\n3. MODELO DE PREDIÇÃO DE RISCO CARDIOVASCULAR\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Preparar dados para predição de risco CV
cv_data <- modeling_data %>%
  select(age, sex, bmi, total_cholesterol_mg_dl, systolic_bp_mmhg,
         smoking_status, physical_activity, family_history_cvd, cv_risk)

# Dividir em treino e teste
set.seed(42)
train_index_cv <- createDataPartition(cv_data$cv_risk, p = 0.7, list = FALSE)
train_cv <- cv_data[train_index_cv, ]
test_cv <- cv_data[-train_index_cv, ]

cat("Distribuição do risco CV (treino):\n")
print(table(train_cv$cv_risk))

# Random Forest para risco CV
set.seed(42)
rf_cv <- randomForest(cv_risk ~ ., 
                     data = train_cv,
                     ntree = 500,
                     importance = TRUE)

# Predições
pred_cv <- predict(rf_cv, test_cv)
conf_matrix_cv <- confusionMatrix(pred_cv, test_cv$cv_risk)

cat("\nPerformance do modelo Random Forest - Risco CV:\n")
print(conf_matrix_cv)

# Importância das variáveis
importance_cv <- importance(rf_cv)
importance_df_cv <- data.frame(
  variable = rownames(importance_cv),
  importance = importance_cv[, "MeanDecreaseGini"]
) %>%
  arrange(desc(importance))

write_csv(importance_df_cv, "outputs/tables/cv_risk_model_importance.csv")

# =============================================================================
# 4. MODELO 3: PREDIÇÃO DE PRESSÃO ARTERIAL SISTÓLICA
# =============================================================================

cat("\n4. MODELO DE PREDIÇÃO DE PRESSÃO ARTERIAL\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Preparar dados para predição de pressão arterial (regressão)
bp_data <- modeling_data %>%
  select(age, sex, bmi, waist_circumference_cm, physical_activity,
         smoking_status, systolic_bp_mmhg)

# Dividir em treino e teste
set.seed(42)
train_index_bp <- createDataPartition(bp_data$systolic_bp_mmhg, p = 0.7, list = FALSE)
train_bp <- bp_data[train_index_bp, ]
test_bp <- bp_data[-train_index_bp, ]

# Random Forest para regressão
set.seed(42)
rf_bp <- randomForest(systolic_bp_mmhg ~ ., 
                     data = train_bp,
                     ntree = 500,
                     importance = TRUE)

# Predições
pred_bp <- predict(rf_bp, test_bp)

# Métricas de regressão
rmse_bp <- sqrt(mean((pred_bp - test_bp$systolic_bp_mmhg)^2))
mae_bp <- mean(abs(pred_bp - test_bp$systolic_bp_mmhg))
r2_bp <- cor(pred_bp, test_bp$systolic_bp_mmhg)^2

cat("Performance do modelo de Pressão Arterial:\n")
cat("RMSE:", round(rmse_bp, 2), "\n")
cat("MAE:", round(mae_bp, 2), "\n")
cat("R²:", round(r2_bp, 3), "\n")

# Plot de predições vs valores reais
bp_predictions_plot <- data.frame(
  real = test_bp$systolic_bp_mmhg,
  predicted = pred_bp
) %>%
  ggplot(aes(x = real, y = predicted)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
  labs(title = "Predições vs Valores Reais - Pressão Arterial Sistólica",
       x = "Pressão Arterial Real (mmHg)",
       y = "Pressão Arterial Predita (mmHg)") +
  theme_minimal()

ggsave("outputs/figures/bp_predictions_plot.png", bp_predictions_plot, 
       width = 8, height = 6, dpi = 300)

# =============================================================================
# 5. ÁRVORE DE DECISÃO PARA SÍNDROME METABÓLICA
# =============================================================================

cat("\n5. ÁRVORE DE DECISÃO PARA SÍNDROME METABÓLICA\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Preparar dados para árvore de decisão
tree_data <- modeling_data %>%
  select(age, sex, bmi, waist_circumference_cm, glucose_mg_dl,
         total_cholesterol_mg_dl, systolic_bp_mmhg, metabolic_syndrome)

# Dividir em treino e teste
set.seed(42)
train_index_tree <- createDataPartition(tree_data$metabolic_syndrome, p = 0.7, list = FALSE)
train_tree <- tree_data[train_index_tree, ]
test_tree <- tree_data[-train_index_tree, ]

# Árvore de decisão
tree_model <- rpart(metabolic_syndrome ~ ., 
                   data = train_tree,
                   method = "class",
                   control = rpart.control(cp = 0.01))

# Visualizar árvore
png("outputs/figures/metabolic_syndrome_decision_tree.png", 
    width = 1200, height = 800, res = 150)
rpart.plot(tree_model, 
           main = "Árvore de Decisão - Síndrome Metabólica",
           extra = 102,
           fallen.leaves = TRUE,
           cex = 0.8)
dev.off()

# Predições da árvore
pred_tree <- predict(tree_model, test_tree, type = "class")
conf_matrix_tree <- confusionMatrix(pred_tree, test_tree$metabolic_syndrome)

cat("Performance da Árvore de Decisão - Síndrome Metabólica:\n")
print(conf_matrix_tree)

# =============================================================================
# 6. RESUMO DOS MODELOS
# =============================================================================

cat("\n6. RESUMO DOS MODELOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Criar resumo dos resultados
model_summary <- data.frame(
  Modelo = c("RF - Diabetes", "RF - Risco CV", "RF - Pressão Arterial", "Árvore - Sínd. Metabólica"),
  Tipo = c("Classificação", "Classificação", "Regressão", "Classificação"),
  Acurácia = c(
    round(conf_matrix_diabetes$overall["Accuracy"], 3),
    round(conf_matrix_cv$overall["Accuracy"], 3),
    round(r2_bp, 3),
    round(conf_matrix_tree$overall["Accuracy"], 3)
  ),
  Métrica = c("Accuracy", "Accuracy", "R²", "Accuracy")
)

write_csv(model_summary, "outputs/tables/model_summary.csv")

cat("Resumo dos modelos:\n")
print(model_summary)

cat("\nModelagem preditiva concluída!\n")
cat("Resultados salvos em outputs/figures/ e outputs/tables/\n")
