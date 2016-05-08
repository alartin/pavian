library(shiny)
library(rhandsontable)

#' Title
#'
#' @param id
#'
#' @return
#' @export
#'
#' @examples
dataInputModuleUI <- function(id) {
  ns <- NS(id)
  shiny::tagList(
    textInput(ns("txt_data_dir"),label="",
              value = system.file("shinyapp/example-data", package = "centrifuger"),
              width = "80%"),
    actionButton(ns("btn_set_data_dir"), "Reload directory"),
    shinyFileTree::shinyFileTreeOutput(ns("files_tree")),
    br(),
    actionButton(ns("btn_check_files"), "Check files"),
    br(),
    htmlOutput(ns("info_samples")),
    br(),
    rHandsontableOutput(ns("table"))
  )
}



#' Title
#'
#' @param input
#' @param output
#' @param session
#' @param pattern
#'
#' @return
#' @export
#'
#' @examples
dataInputModule <- function(input, output, session,
                            ...,
                            pattern = "defs.csv$", cache_tree = TRUE) {
  library(shinyFileTree)

  data_dir <- eventReactive("btn_set_data_dir", {
    input$txt_data_dir
  })

  output$files_tree <- shinyFileTree::renderShinyFileTree({
    validate(
      need(data_dir(), message = "No sample directory is set", label =
             "Sample directory")
    )

    withProgress(message = "Reading directory tree ...", {
      shinyFileTree(
        list(
          text = basename(data_dir()),
          type = "directory",
          state = list(opened = TRUE),
          children = get_list_from_directory(data_dir(),
                                             pattern, hide_empty_dirs = TRUE,
                                             state = list(opened = TRUE))
        ),
        plugins = c("types")
      )
    })
  })

  report_files <- reactive({
    def_files <- files_selected_in_tree()
    def_df <- get_def_df()
    file.path(dirname(def_files), def_df$ReportFile)
  })

  output$table <- renderRHandsontable({
    def_df <- get_def_df()
    if (input$btn_check_files) {
      gd_files <- file.exists(report_files())
      #def_df[gd_files,"ReportFile"] <- sprintf("<span style='background:#00FF00'>%s</span>",def_df[gd_files,"ReportFile"])
      #def_df[!gd_files,"ReportFile"] <- sprintf("<span style='background:#FF0000'>%s</span>",def_df[!gd_files,"ReportFile"])
      def_df[gd_files,"ReportFilePath"] <- sprintf("✓ %s",def_df[gd_files,"ReportFilePath"])
      def_df[!gd_files,"ReportFilePath"] <- sprintf("✗Does not exist: %s",def_df[!gd_files,"ReportFilePath"])


    }

    ## The custom rendering does not seem to work ...
    #rhandsontable(def_df, ...) #%>%
    #hot_col("ReportFile", renderer = htmlwidgets::JS("html"))

    rhandsontable(def_df, ...)
  })

  output$info_samples <- renderText({
    sprintf("<span class='background:#00ff00'>Got %s report files. </span>",
            sum(file.exists(report_files())))
  })


  files_selected_in_tree <- reactive ({
    selected <- grep(pattern, input$files_tree, value = TRUE)

    validate(
      need(
        selected,
        message = "Please select at a sample definition file."
      )
    )

    file.path(dirname(data_dir()),selected)
  })

  get_def_df <- reactive({
    def_files <- files_selected_in_tree()

    validate(
      need(all(file.exists(def_files)), sprintf("An error occured looking up some of the definition files (%s)",paste(def_files, collapse = ", "))))

    ## TODO: Specify order, and allow loading multiple defs files at once
    #column_order <- c("Include", "Name", "Engine")

    def_df <- read.delim(def_files, header = TRUE, sep = ";", stringsAsFactors = FALSE)

    validate(need("ReportFile" %in% colnames(def_df),
                  message = "Required column 'ReportFile' not present in defs.csv"))


    if (!"Include" %in% colnames(def_df))
      def_df <- cbind(Include = TRUE, def_df)

    if ("Class" %in% colnames(def_df))
      def_df$Class <- as.factor(def_df$Class)

    if (!"ReportFilePath" %in% colnames(def_df))
      def_df$ReportFilePath <- file.path(dirname(def_files), def_df$ReportFile)

    def_df
  })

  return(get_def_df)
}
