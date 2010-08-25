#' Create a test.
#' 
#' A test encapsulates a series of expectations about small, self-contained
#' set of functionality.  Each test is contained in a \link{context} and
#' contains multiple expectation generated by \code{\link{expect_that}}.  
#' 
#' Tests are evaluated in their own environments, and should not affect 
#' global state.
#' 
#' When run from the command line, tests return \code{NULL} if all 
#' expectations are met, otherwise it raises an error.
#'
#' @param desc test name.  Names should be kept as brief as possible, as they
#'   are often used as line prefixes.
#' @param code test code containing expectations
#' @export
#' @examples
#' test_that("trigonometric functions match identies", {
#'   expect_that(sin(pi / 4), equals(1 / sqrt(2)))
#'   expect_that(cos(pi / 4), equals(1 / sqrt(2)))
#'   expect_that(tan(pi / 4), equals(1))
#' })
#' # Failing test:
#' \dontrun{
#' test_that("trigonometric functions match identities", {
#'   expect_that(sin(pi / 4), equals(1))
#' })
#' }
test_that <- function(desc, code) {
  test_reporter()$start_test(desc)
  on.exit(test_reporter()$end_test())
  
  env <- new.env(parent = globalenv())  
  res <- suppressMessages(try_capture_stack(substitute(code), env))
  
  if (is.error(res)) {
    traceback <- create_traceback(res$calls)
    report <- error_report(res, traceback)
    test_reporter()$add_result(report)
  }
  
  invisible()
}

#' Generate error report from traceback.
#'
#' @keywords internal
#' @param error error message
#' @param traceback traceback generated by \code{\link{create_traceback}}
error_report <- function(error, traceback) {
  msg <- str_replace(as.character(error), "Error.*?: ", "")
  
  if (length(traceback) > 0) {
    user_calls <- str_c(traceback, collapse = "\n")      
    msg <- str_c(msg, user_calls)
  } else {
    # Need to remove trailing newline from error message to be consistent
    # with other messages
    msg <- str_replace(msg, "\n$", "")
  }
  
  expectation(NA, msg)
}