#' Watch a directory for changes (additions, deletions & modifications).
#'
#' This is used to power the [auto_test()] and
#' [auto_test_package()] functions which are used to rerun tests
#' whenever source code changes.
#'
#' Use Ctrl + break (windows), Esc (mac gui) or Ctrl + C (command line) to
#' stop the watcher.
#'
#' @param path character vector of paths to watch.  Omit trailing backslash.
#' @param pattern file pattern passed to [dir()]
#' @param callback function called everytime a change occurs.  It should
#'   have three parameters: added, deleted, modified, and should return
#'   TRUE to keep watching, or FALSE to stop.
#' @param hash hashes are more accurate at detecting changes, but are slower
#'   for large files.  When FALSE, uses modification time stamps
#' @export
#' @keywords internal
watch <- function(path, callback, pattern = NULL, hash = TRUE) {
  prev <- dir_state(path, pattern, hash = hash)

  repeat {
    Sys.sleep(1)

    curr <- dir_state(path, pattern, hash = hash)
    changes <- compare_state(prev, curr)

    if (changes$n > 0) {
      # cat("C")
      keep_going <- TRUE
      try(keep_going <- callback(changes$added, changes$deleted, changes$modified))

      if (!isTRUE(keep_going)) return(invisible())
    } else {
      # cat(".")
    }

    prev <- curr
  }
}

safe_digest <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  if (is_directory(path)) return(NA_character_)
  if (!is_readable(path)) return(NA_character_)

  rlang::hash_file(path)
}

#' Capture the state of a directory.
#'
#' @param path path to directory
#' @param pattern regular expression with which to filter files
#' @param hash use hash (slow but accurate) or time stamp (fast but less
#'   accurate)
#' @keywords internal
dir_state <- function(path, pattern = NULL, hash = TRUE) {
  files <- dir(path, pattern, full.names = TRUE)

  # It's possible for any of the files to be deleted between the dir()
  # call above and the calls below; `file.info` handles this
  # gracefully, but digest::digest doesn't -- so we wrap it. Both
  # cases will return NA for files that have gone missing.
  if (hash) {
    file_states <- vapply(files, safe_digest, character(1))
  } else {
    file_states <- stats::setNames(file.info(files)$mtime, files)
  }
  file_states[!is.na(file_states)]
}

#' Compare two directory states.
#'
#' @param old previous state
#' @param new current state
#' @return list containing number of changes and files which have been
#'   `added`, `deleted` and `modified`
#' @keywords internal
compare_state <- function(old, new) {
  added <- setdiff(names(new), names(old))
  deleted <- setdiff(names(old), names(new))

  same <- intersect(names(old), names(new))
  modified <- names(new[same])[new[same] != old[same]]

  n <- length(added) + length(deleted) + length(modified)

  list(n = n, added = added, deleted = deleted, modified = modified)
}

# Helpers -----------------------------------------------------------------

is_directory <- function(x) file.info(x)$isdir
is_readable <- function(x) file.access(x, 4) == 0
