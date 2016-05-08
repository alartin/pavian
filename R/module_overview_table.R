library(shiny)
library(DT)

#' Title
#'
#' @param id
#'
#' @return
#' @export
#'
#' @examples
reportOverviewModuleUI <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    checkboxInput(ns("opt_samples_overview_percent"), label = "Show percentages instead of number of reads"),
    div(style = 'overflow-x: scroll',
        DT::dataTableOutput(ns('dt_samples_overview')))
  )

}

#' Shiny modules to display an overview of metagenomics reports
#'
#' @param input
#' @param output
#' @param session
#'
#' @return
#' @export
#'
#' @examples
reportOverviewModule <- function(input, output, session, samples_df, reports, datatable_opts = NULL) {
  library(DT)

  r_state <- list()

  observeEvent(input$opt_samples_overview_percent, {
    ## save state of table
    #r_state <<- list(
    #  search_columns = input$dt_samples_overview_search_columns,
    #  state = input$dt_samples_overview_state
    #  )
    str(input$dt_samples_overview_state)
  })

  ## Samples overview output
  output$dt_samples_overview <- DT::renderDataTable({

    validate(need(samples_df(), message = "No data available."))
    validate(need(reports(), message = "No data available."))

    samples_summary <- do.call(rbind, lapply(reports(), summarize_report))
    #rownames(samples_summary) <- basename(rownames(samples_summary))
    colnames(samples_summary) <-
      beautify_string(colnames(samples_summary))

    number_range <-  c(0, max(samples_summary[, 1], na.rm = TRUE))
    start_color_bar_at <- 1

    if (isTRUE(input$opt_samples_overview_percent)) {
      start_color_bar_at <- 2
      number_range <- c(0, 100)
      samples_summary[, 2:ncol(samples_summary)] <-
        100 * signif(sweep(samples_summary[, 2:ncol(samples_summary)], 1, samples_summary[, 1], `/`), 2)
    }


    dt <- DT::datatable(
      samples_summary,
      selection = 'single'
      ,extensions = c('Responsive', 'Buttons')
      ,
      options = list(
        dom = 'Bfrtip'
        , buttons = c('pageLength','pdf', 'excel' , 'csv', 'copy')
        #, buttons = c('pageLength', 'colvis', 'excel', 'pdf')                             # pageLength / colvis / excel / pdf
        , lengthMenu = list(c(10, 25, 100, -1), c('10', '25', '100', 'All'))
        , pageLength = 25
        , options = c(datatable_opts, list(stateSave = TRUE))
      )
    ) %>%
      DT::formatStyle(
        colnames(samples_summary)[start_color_bar_at:5],
        background = DT::styleColorBar(number_range, 'lightblue')
      ) %>%
      DT::formatStyle(colnames(samples_summary)[6:ncol(samples_summary)],
                      background = DT::styleColorBar(c(0, max(
                        samples_summary[, 6], na.rm = TRUE
                      )), 'lightgreen'))

    #formatString <- function(table, columns, before="", after="") {
    #  DT:::formatColumns(table, columns, function(col, before, after)
    #    sprintf("$(this.api().cell(row, %s).node()).html((%s + data[%d]) + %s);  ",col, before, col, after),
    #    before, after
    #  )
    #}

    if (isTRUE(input$opt_samples_overview_percent)) {
      dt <- dt %>%
        formatCurrency(1, currency = '', digits = 0) %>%
        formatString(2:ncol(samples_summary),
                     string_after = '%',
                     string_before = '')  ## TODO: display as percent
      ## not implemented for now as formatPercentage enforces a certain number of digits, but I like to round
      ## with signif.
    } else {
      dt <-
        dt %>% formatCurrency(1:ncol(samples_summary),
                              currency = '',
                              digits = 0)
    }
    dt
  })

}