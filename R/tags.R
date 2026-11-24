#' Share one tag among several plots
#'
#' `tag_group()` makes several plots share a single panel tag. The first plot
#' of the group (in reading order) gets the tag; the others get none and
#' don't use up a letter, so the next plot after the group continues the
#' sequence. Tags are added with [layout_tags()].
#'
#' The plots of a group are usually arranged together, e.g.
#' `tag_group(new_row(p1, p2))`. Several plots can also be passed directly:
#' `new_row(tag_group(p1, p2), p3)`.
#'
#' @param ... ggplots, grobs, layouts, other objects with an
#'   [as_layout_gtable()] method, or lists of them. All of them form
#'   one group.
#'
#' @returns The modified plot or layout if one object was supplied, otherwise
#'   a list. Layout functions such as [new_row()] splice such lists.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73")
#'
#' # p1 and p2 share tag A, p3 gets B
#' tag_group(new_row(p1, p2)) |>
#'   new_row(p3) |>
#'   layout_tags("A")
#'
#' new_row(tag_group(p1, p2), p3) |>
#'   layout_tags("A")
#'
#' @export
tag_group <- function(...) {
  first <- TRUE
  mark <- function(no_tag) {
    out <- !first && no_tag
    first <<- FALSE
    out
  }
  set_flag <- function(x) {
    if (is_ggplot(x)) {
      x$tidylayouts$no_tag <- mark(TRUE)
      return(x)
    }
    if (inherits(x, "grob") || has_layout_gtable(x)) x <- as_node(x)
    if (is_tidylayout(x)) {
      return(map_leaves(x, function(leaf) {
        if (leaf$type == "plot") {
          flag <- mark(TRUE)
          if (!is.null(leaf$plot)) leaf$plot$tidylayouts$no_tag <- flag
          leaf$no_tag <- flag
        } else if (leaf$type == "grob") {
          leaf$no_tag <- mark(TRUE)
        }
        leaf
      }))
    }
    if (is.list(x) && !is.object(x)) return(lapply(x, set_flag))
    stop(
      "Can't tag an object of class <", class(x)[1], ">.",
      call. = FALSE
    )
  }
  out <- lapply(list(...), set_flag)
  if (length(out) == 1) out[[1]] else out
}

# Whether a leaf gets a panel tag.
is_tagged <- function(leaf) {
  leaf$type != "spacer" && !isTRUE(leaf$no_tag)
}
