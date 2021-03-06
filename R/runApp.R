
#' Run Pavian web interface
#'
#' @param cache_dir Directory to save temporary files.
#' @param server_dir Directory for sample files.
#' @param server_access Allow users to change server directory
#'
#' @param ... Additional arguments to \code{\link[shiny]{runApp}}, such as \code{host} and \code{port}.
#'
#' @export
runApp <- function(cache_dir = "cache",
                   server_dir = Sys.glob("~"),
                   server_access = FALSE,
                   ...) {

  appDir <- system.file("shinyapp", package = "pavian")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `pavian`.", call. = FALSE)
  }

  options(pavian.cache_dir = cache_dir)
  options(pavian.server_dir = server_dir)
  options(pavian.server_access = server_access)

  shiny::runApp(appDir, display.mode="normal", ...)
}
