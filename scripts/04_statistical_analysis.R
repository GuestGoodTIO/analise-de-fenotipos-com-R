# =============================================================================
# 04_STATISTICAL_ANALYSIS.R - Análises Estatísticas Avançadas
# =============================================================================

# Carregar bibliotecas e funções
source("setup.R")
source("functions/phenotype_functions.R")

library(cluster)
library(factoextra)
library(FactoMineR)
library(randomForest)
library(caret)
library(rpart)
library(rpart.plot)

# Carregar dados
data <- read_csv("data/processed/phenotype_data.csv")

cat("=== ANÁLISES ESTATÍSTICAS AVANÇADAS ===\n")
cat("Iniciando análises de clustering, PCA e modelagem preditiva...\n\n")

# =============================================================================
# 1. PREPARAÇÃO DOS DADOS PARA ANÁLISES MULTIVARIADAS
# =============================================================================

cat("1. PREPARAÇÃO DOS DADOS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Selecionar variáveis numéricas para análises
analysis_vars <- c(
  "age", "height_cm", "weight_kg", "bmi", "waist_circumference_cm",
  "hip_circumference_cm", "body_fat_percentage", "waist_hip_ratio",
  "glucose_mg_dl", "total_cholesterol_mg_dl", "hdl_cholesterol_mg_dl",
  "ldl_cholesterol_mg_dl", "triglycerides_mg_dl", "hemoglobin_g_dl",
  "crp_mg_l", "systolic_bp_mmhg", "diastolic_bp_mmhg"
)

# Criar dataset para análises (remover NAs)
analysis_data <- data %>%
  select(subject_id, sex, all_of(analysis_vars)) %>%
  na.omit()

cat("Dados para análise:", nrow(analysis_data), "indivíduos\n")
cat("Variáveis incluídas:", length(analysis_vars), "\n\n")

# Normalizar variáveis para análises multivariadas
scaled_data <- analysis_data %>%
  select(all_of(analysis_vars)) %>%
  scale() %>%
  as.data.frame()

rownames(scaled_data) <- analysis_data$subject_id

# =============================================================================
# 2. ANÁLISE DE COMPONENTES PRINCIPAIS (PCA)
# =============================================================================

cat("2. ANÁLISE DE COMPONENTES PRINCIPAIS\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Executar PCA
pca_result <- PCA(scaled_data, graph = FALSE)

# Resumo da variância explicada
variance_explained <- get_eigenvalue(pca_result)
write_csv(variance_explained, "outputs/tables/pca_variance_explained.csv")

cat("Variância explicada pelos primeiros 5 componentes:\n")
print(round(variance_explained[1:5, ], 3))

# Contribuições das variáveis
var_contrib <- get_pca_var(pca_result)$contrib
write_csv(as.data.frame(var_contrib), "outputs/tables/pca_variable_contributions.csv")

# Visualizações PCA
# Scree plot
scree_plot <- fviz_eig(pca_result, addlabels = TRUE, ylim = c(0, 30)) +
  labs(title = "Scree Plot - Variância Explicada por Componente",
       x = "Componentes Principais", y = "% da Variância Explicada") +
  theme_minimal()

ggsave("outputs/figures/pca_scree_plot.png", scree_plot, 
       width = 10, height = 6, dpi = 300)

# Biplot
biplot <- fviz_pca_biplot(pca_result, 
                         col.ind = analysis_data$sex,
                         palette = c("#FF6B6B", "#4ECDC4"),
                         addEllipses = TRUE,
                         label = "var",
                         col.var = "black",
                         repel = TRUE) +
  labs(title = "PCA Biplot - Indivíduos e Variáveis",
       color = "Sexo") +
  theme_minimal()

ggsave("outputs/figures/pca_biplot.png", biplot, 
       width = 12, height = 10, dpi = 300)

# Contribuição das variáveis aos primeiros 2 PCs
contrib_plot <- fviz_contrib(pca_result, choice = "var", axes = 1:2, top = 10) +
  labs(title = "Contribuição das Variáveis aos PC1 e PC2") +
  theme_minimal()

ggsave("outputs/figures/pca_variable_contributions.png", contrib_plot, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# 3. ANÁLISE DE CLUSTERING
# =============================================================================

cat("\n3. ANÁLISE DE CLUSTERING\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Determinar número ótimo de clusters usando método do cotovelo
set.seed(42)
wss <- fviz_nbclust(scaled_data, kmeans, method = "wss", k.max = 10) +
  labs(title = "Método do Cotovelo para Determinação do Número de Clusters") +
  theme_minimal()

ggsave("outputs/figures/clustering_elbow_method.png", wss, 
       width = 10, height = 6, dpi = 300)

# Método da silhueta
silhouette <- fviz_nbclust(scaled_data, kmeans, method = "silhouette", k.max = 10) +
  labs(title = "Método da Silhueta para Determinação do Número de Clusters") +
  theme_minimal()

ggsave("outputs/figures/clustering_silhouette_method.png", silhouette, 
       width = 10, height = 6, dpi = 300)

# K-means com 3 clusters (baseado nos métodos acima)
set.seed(42)
kmeans_result <- kmeans(scaled_data, centers = 3, nstart = 25)

# Adicionar clusters aos dados originais
analysis_data$cluster <- as.factor(kmeans_result$cluster)

# Visualização dos clusters no espaço PCA
cluster_pca_plot <- fviz_cluster(kmeans_result, data = scaled_data,
                                palette = c("#FF6B6B", "#4ECDC4", "#95E1D3"),
                                geom = "point",
                                ellipse.type = "convex",
                                ggtheme = theme_minimal()) +
  labs(title = "Clusters Fenotípicos no Espaço PCA")

ggsave("outputs/figures/clustering_pca_visualization.png", cluster_pca_plot, 
       width = 12, height = 8, dpi = 300)

# Caracterização dos clusters
cluster_summary <- analysis_data %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    percent = round(n() / nrow(analysis_data) * 100, 1),
    age_mean = round(mean(age), 1),
    bmi_mean = round(mean(bmi), 1),
    systolic_bp_mean = round(mean(systolic_bp_mmhg), 1),
    glucose_mean = round(mean(glucose_mg_dl), 1),
    total_chol_mean = round(mean(total_cholesterol_mg_dl), 1),
    hdl_chol_mean = round(mean(hdl_cholesterol_mg_dl), 1),
    sex_male_percent = round(sum(sex == "M") / n() * 100, 1),
    .groups = "drop"
  )

write_csv(cluster_summary, "outputs/tables/cluster_characterization.csv")

cat("Caracterização dos clusters:\n")
print(cluster_summary)

# Boxplots das principais variáveis por cluster
cluster_vars <- c("bmi", "systolic_bp_mmhg", "glucose_mg_dl", "total_cholesterol_mg_dl")

cluster_boxplot <- analysis_data %>%
  select(cluster, all_of(cluster_vars)) %>%
  pivot_longer(-cluster, names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = cluster, y = value, fill = cluster)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~variable, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("#FF6B6B", "#4ECDC4", "#95E1D3")) +
  labs(title = "Características dos Clusters Fenotípicos",
       x = "Cluster", y = "Valor") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("outputs/figures/cluster_characteristics.png", cluster_boxplot, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# 4. CLUSTERING HIERÁRQUICO
# =============================================================================

cat("\n4. CLUSTERING HIERÁRQUICO\n")
cat(paste(rep("=", 40), collapse = ""), "\n")

# Calcular matriz de distâncias
dist_matrix <- dist(scaled_data, method = "euclidean")

# Clustering hierárquico
hc_result <- hclust(dist_matrix, method = "ward.D2")

# Dendrograma
dendro_plot <- fviz_dend(hc_result, k = 3, 
                        cex = 0.5,
                        k_colors = c("#FF6B6B", "#4ECDC4", "#95E1D3"),
                        color_labels_by_k = TRUE,
                        rect = TRUE) +
  labs(title = "Dendrograma - Clustering Hierárquico") +
  theme_minimal()

ggsave("outputs/figures/hierarchical_clustering_dendrogram.png", dendro_plot, 
       width = 14, height = 8, dpi = 300)

# Cortar dendrograma em 3 clusters
hc_clusters <- cutree(hc_result, k = 3)
analysis_data$hc_cluster <- as.factor(hc_clusters)

# Comparar clusters k-means vs hierárquico
cluster_comparison <- table(analysis_data$cluster, analysis_data$hc_cluster)
write_csv(as.data.frame.matrix(cluster_comparison), "outputs/tables/cluster_comparison.csv")

cat("Comparação entre K-means e Clustering Hierárquico:\n")
print(cluster_comparison)

cat("\nAnálises estatísticas avançadas concluídas!\n")
cat("Resultados salvos em outputs/figures/ e outputs/tables/\n")
