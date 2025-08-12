# =============================================================================
# SHINY APP - Dashboard Interativo para Análise de Fenótipos
# =============================================================================

# Carregar bibliotecas
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(corrplot)

# Carregar dados
data <- read.csv("../data/processed/phenotype_data.csv", stringsAsFactors = FALSE)

# =============================================================================
# UI (Interface do Usuário)
# =============================================================================

ui <- dashboardPage(
  dashboardHeader(title = "Dashboard de Análise de Fenótipos"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Visão Geral", tabName = "overview", icon = icon("chart-line")),
      menuItem("Distribuições", tabName = "distributions", icon = icon("histogram")),
      menuItem("Correlações", tabName = "correlations", icon = icon("project-diagram")),
      menuItem("Comparações", tabName = "comparisons", icon = icon("balance-scale")),
      menuItem("Dados", tabName = "data", icon = icon("table"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
      "))
    ),
    
    tabItems(
      # ===== ABA 1: VISÃO GERAL =====
      tabItem(tabName = "overview",
        fluidRow(
          # Caixas de informação
          valueBoxOutput("total_subjects"),
          valueBoxOutput("avg_age"),
          valueBoxOutput("male_percentage")
        ),
        
        fluidRow(
          box(
            title = "Distribuição por Sexo", status = "primary", solidHeader = TRUE,
            width = 6, height = 400,
            plotlyOutput("sex_distribution")
          ),
          box(
            title = "Distribuição por Categoria de IMC", status = "primary", solidHeader = TRUE,
            width = 6, height = 400,
            plotlyOutput("bmi_distribution")
          )
        ),
        
        fluidRow(
          box(
            title = "Estatísticas Descritivas Principais", status = "info", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("summary_stats")
          )
        )
      ),
      
      # ===== ABA 2: DISTRIBUIÇÕES =====
      tabItem(tabName = "distributions",
        fluidRow(
          box(
            title = "Controles", status = "primary", solidHeader = TRUE,
            width = 3,
            selectInput("dist_variable", "Selecione a Variável:",
                       choices = c("Idade" = "age",
                                 "IMC" = "bmi",
                                 "Pressão Sistólica" = "systolic_bp_mmhg",
                                 "Glicose" = "glucose_mg_dl",
                                 "Colesterol Total" = "total_cholesterol_mg_dl",
                                 "HDL" = "hdl_cholesterol_mg_dl",
                                 "Triglicerídeos" = "triglycerides_mg_dl"),
                       selected = "bmi"),
            
            checkboxInput("show_by_sex", "Separar por Sexo", value = FALSE),
            
            sliderInput("bins", "Número de Bins:",
                       min = 10, max = 50, value = 30)
          ),
          
          box(
            title = "Distribuição da Variável Selecionada", status = "primary", solidHeader = TRUE,
            width = 9, height = 500,
            plotlyOutput("distribution_plot")
          )
        ),
        
        fluidRow(
          box(
            title = "Estatísticas da Variável", status = "info", solidHeader = TRUE,
            width = 12,
            verbatimTextOutput("variable_stats")
          )
        )
      ),
      
      # ===== ABA 3: CORRELAÇÕES =====
      tabItem(tabName = "correlations",
        fluidRow(
          box(
            title = "Controles", status = "primary", solidHeader = TRUE,
            width = 3,
            selectInput("cor_vars", "Selecione as Variáveis:",
                       choices = c("age", "bmi", "systolic_bp_mmhg", "diastolic_bp_mmhg",
                                 "glucose_mg_dl", "total_cholesterol_mg_dl", 
                                 "hdl_cholesterol_mg_dl", "triglycerides_mg_dl"),
                       selected = c("bmi", "systolic_bp_mmhg", "glucose_mg_dl", 
                                  "total_cholesterol_mg_dl"),
                       multiple = TRUE),
            
            selectInput("cor_method", "Método de Correlação:",
                       choices = c("Pearson" = "pearson",
                                 "Spearman" = "spearman"),
                       selected = "pearson")
          ),
          
          box(
            title = "Matriz de Correlação", status = "primary", solidHeader = TRUE,
            width = 9, height = 600,
            plotOutput("correlation_plot")
          )
        )
      ),
      
      # ===== ABA 4: COMPARAÇÕES =====
      tabItem(tabName = "comparisons",
        fluidRow(
          box(
            title = "Controles", status = "primary", solidHeader = TRUE,
            width = 3,
            selectInput("comp_variable", "Variável para Análise:",
                       choices = c("IMC" = "bmi",
                                 "Pressão Sistólica" = "systolic_bp_mmhg",
                                 "Glicose" = "glucose_mg_dl",
                                 "Colesterol Total" = "total_cholesterol_mg_dl"),
                       selected = "bmi"),
            
            selectInput("group_variable", "Agrupar por:",
                       choices = c("Sexo" = "sex",
                                 "Categoria IMC" = "bmi_category",
                                 "Status Diabetes" = "diabetes_status",
                                 "Risco CV" = "cv_risk"),
                       selected = "sex"),
            
            radioButtons("plot_type", "Tipo de Gráfico:",
                        choices = c("Boxplot" = "boxplot",
                                  "Violin Plot" = "violin"),
                        selected = "boxplot")
          ),
          
          box(
            title = "Comparação entre Grupos", status = "primary", solidHeader = TRUE,
            width = 9, height = 500,
            plotlyOutput("comparison_plot")
          )
        ),
        
        fluidRow(
          box(
            title = "Estatísticas por Grupo", status = "info", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("group_stats")
          )
        )
      ),
      
      # ===== ABA 5: DADOS =====
      tabItem(tabName = "data",
        fluidRow(
          box(
            title = "Filtros", status = "primary", solidHeader = TRUE,
            width = 3,
            selectInput("filter_sex", "Sexo:",
                       choices = c("Todos" = "all", "Masculino" = "M", "Feminino" = "F"),
                       selected = "all"),
            
            selectInput("filter_bmi", "Categoria IMC:",
                       choices = c("Todas" = "all", unique(data$bmi_category)),
                       selected = "all"),
            
            numericInput("min_age", "Idade Mínima:", value = min(data$age, na.rm = TRUE),
                        min = min(data$age, na.rm = TRUE), max = max(data$age, na.rm = TRUE)),
            
            numericInput("max_age", "Idade Máxima:", value = max(data$age, na.rm = TRUE),
                        min = min(data$age, na.rm = TRUE), max = max(data$age, na.rm = TRUE)),
            
            downloadButton("download_data", "Download dos Dados", class = "btn-primary")
          ),
          
          box(
            title = "Dados Filtrados", status = "primary", solidHeader = TRUE,
            width = 9,
            DT::dataTableOutput("filtered_data")
          )
        )
      )
    )
  )
)

# =============================================================================
# SERVER (Lógica do Servidor)
# =============================================================================

server <- function(input, output) {
  
  # ===== VISÃO GERAL =====
  
  output$total_subjects <- renderValueBox({
    valueBox(
      value = nrow(data),
      subtitle = "Total de Indivíduos",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$avg_age <- renderValueBox({
    valueBox(
      value = round(mean(data$age, na.rm = TRUE), 1),
      subtitle = "Idade Média",
      icon = icon("calendar"),
      color = "green"
    )
  })
  
  output$male_percentage <- renderValueBox({
    valueBox(
      value = paste0(round(sum(data$sex == "M") / nrow(data) * 100, 1), "%"),
      subtitle = "Percentual Masculino",
      icon = icon("male"),
      color = "yellow"
    )
  })
  
  output$sex_distribution <- renderPlotly({
    p <- data %>%
      count(sex) %>%
      ggplot(aes(x = sex, y = n, fill = sex)) +
      geom_col() +
      scale_fill_manual(values = c("F" = "#FF6B6B", "M" = "#4ECDC4")) +
      labs(x = "Sexo", y = "Frequência") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$bmi_distribution <- renderPlotly({
    p <- data %>%
      count(bmi_category) %>%
      ggplot(aes(x = reorder(bmi_category, n), y = n, fill = bmi_category)) +
      geom_col() +
      coord_flip() +
      labs(x = "Categoria IMC", y = "Frequência") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$summary_stats <- DT::renderDataTable({
    numeric_vars <- c("age", "bmi", "systolic_bp_mmhg", "glucose_mg_dl", "total_cholesterol_mg_dl")
    
    summary_data <- data %>%
      select(all_of(numeric_vars)) %>%
      summarise_all(list(
        Média = ~round(mean(.x, na.rm = TRUE), 2),
        Mediana = ~round(median(.x, na.rm = TRUE), 2),
        `Desvio Padrão` = ~round(sd(.x, na.rm = TRUE), 2),
        Mínimo = ~round(min(.x, na.rm = TRUE), 2),
        Máximo = ~round(max(.x, na.rm = TRUE), 2)
      )) %>%
      tidyr::pivot_longer(everything(), names_to = "Variable_Stat", values_to = "Value") %>%
      tidyr::separate(Variable_Stat, into = c("Variable", "Statistic"), sep = "_") %>%
      tidyr::pivot_wider(names_from = Statistic, values_from = Value)
    
    DT::datatable(summary_data, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # ===== DISTRIBUIÇÕES =====
  
  output$distribution_plot <- renderPlotly({
    var_data <- data[[input$dist_variable]]
    
    if (input$show_by_sex) {
      p <- ggplot(data, aes_string(x = input$dist_variable, fill = "sex")) +
        geom_histogram(bins = input$bins, alpha = 0.7, position = "identity") +
        scale_fill_manual(values = c("F" = "#FF6B6B", "M" = "#4ECDC4")) +
        labs(x = input$dist_variable, y = "Frequência", fill = "Sexo") +
        theme_minimal()
    } else {
      p <- ggplot(data, aes_string(x = input$dist_variable)) +
        geom_histogram(bins = input$bins, fill = "steelblue", alpha = 0.7) +
        labs(x = input$dist_variable, y = "Frequência") +
        theme_minimal()
    }
    
    ggplotly(p)
  })
  
  output$variable_stats <- renderText({
    var_data <- data[[input$dist_variable]]
    
    stats <- paste(
      "Estatísticas Descritivas:",
      paste("Média:", round(mean(var_data, na.rm = TRUE), 2)),
      paste("Mediana:", round(median(var_data, na.rm = TRUE), 2)),
      paste("Desvio Padrão:", round(sd(var_data, na.rm = TRUE), 2)),
      paste("Mínimo:", round(min(var_data, na.rm = TRUE), 2)),
      paste("Máximo:", round(max(var_data, na.rm = TRUE), 2)),
      paste("Valores Faltantes:", sum(is.na(var_data))),
      sep = "\n"
    )
    
    stats
  })
  
  # ===== CORRELAÇÕES =====
  
  output$correlation_plot <- renderPlot({
    if (length(input$cor_vars) < 2) {
      plot.new()
      text(0.5, 0.5, "Selecione pelo menos 2 variáveis", cex = 1.5)
      return()
    }
    
    cor_data <- data %>%
      select(all_of(input$cor_vars)) %>%
      na.omit()
    
    cor_matrix <- cor(cor_data, method = input$cor_method)
    
    corrplot(cor_matrix, method = "color", type = "upper",
             order = "hclust", tl.cex = 0.8, tl.col = "black",
             addCoef.col = "black", number.cex = 0.7)
  })
  
  # ===== COMPARAÇÕES =====
  
  output$comparison_plot <- renderPlotly({
    if (input$plot_type == "boxplot") {
      p <- ggplot(data, aes_string(x = input$group_variable, y = input$comp_variable, 
                                  fill = input$group_variable)) +
        geom_boxplot(alpha = 0.7) +
        labs(x = input$group_variable, y = input$comp_variable) +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      p <- ggplot(data, aes_string(x = input$group_variable, y = input$comp_variable, 
                                  fill = input$group_variable)) +
        geom_violin(alpha = 0.7) +
        labs(x = input$group_variable, y = input$comp_variable) +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    }
    
    ggplotly(p)
  })
  
  output$group_stats <- DT::renderDataTable({
    group_data <- data %>%
      group_by_at(input$group_variable) %>%
      summarise(
        N = n(),
        Média = round(mean(get(input$comp_variable), na.rm = TRUE), 2),
        Mediana = round(median(get(input$comp_variable), na.rm = TRUE), 2),
        `Desvio Padrão` = round(sd(get(input$comp_variable), na.rm = TRUE), 2),
        .groups = "drop"
      )
    
    DT::datatable(group_data, options = list(pageLength = 10))
  })
  
  # ===== DADOS =====
  
  filtered_data <- reactive({
    filtered <- data
    
    if (input$filter_sex != "all") {
      filtered <- filtered %>% filter(sex == input$filter_sex)
    }
    
    if (input$filter_bmi != "all") {
      filtered <- filtered %>% filter(bmi_category == input$filter_bmi)
    }
    
    filtered <- filtered %>%
      filter(age >= input$min_age & age <= input$max_age)
    
    return(filtered)
  })
  
  output$filtered_data <- DT::renderDataTable({
    DT::datatable(filtered_data(), 
                  options = list(pageLength = 15, scrollX = TRUE),
                  filter = "top")
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste("phenotype_data_filtered_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(filtered_data(), file, row.names = FALSE)
    }
  )
}

# =============================================================================
# EXECUTAR APLICAÇÃO
# =============================================================================

shinyApp(ui = ui, server = server)
