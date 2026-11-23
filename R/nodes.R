# Layout tree -------------------------------------------------------------
#
# A layout is a tree of nodes of class "tidylayout". Container nodes
# ("row", "column", "grid") hold children; leaf nodes ("plot", "grob",
# "spacer") hold content. Nothing is drawn until the layout is printed.

new_node <- function(type, children = list(), ...) {
  structure(list(type = type, children = children, ...), class = "tidylayout")
}

is_tidylayout <- function(x) inherits(x, "tidylayout")

is_container <- function(x) x$type %in% c("row", "column", "grid")

is_ggplot <- function(x) inherits(x, "ggplot")

as_node <- function(x, call = parent.frame()) {
  if (is_tidylayout(x)) return(x)
  if (is_ggplot(x)) {
    return(new_node("plot", plot = x, center = x$tidylayouts$center,
                    no_tag = x$tidylayouts$no_tag))
  }
  if (inherits(x, "grob")) return(new_node("grob", grob = x))
  stop(
    "Can't use an object of class <", class(x)[1], "> in a layout. ",
    "Supply ggplots, grobs or layouts.",
    call. = FALSE
  )
}

# Flatten `...` into a list of nodes. Plain lists (e.g. from `auto_height(p1, p2)`)
# are spliced. `NULL` is dropped, or kept as an empty cell if `keep_null = TRUE`.
collect_items <- function(dots, keep_null = FALSE) {
  out <- list()
  for (x in dots) {
    if (is.null(x)) {
      if (keep_null) out <- c(out, list(new_node("spacer", width = NA, height = NA)))
    } else if (is.list(x) && !is.object(x)) {
      out <- c(out, collect_items(x, keep_null = keep_null))
    } else {
      out <- c(out, list(as_node(x)))
    }
  }
  out
}

# Alignment is stored per axis as "start", "end", "center" or "justify".
# The y axis runs top-down, so "top" is "start" and "bottom" is "end".
horizontal_values <- c(left = "start", right = "end", center = "center", justify = "justify")
vertical_values <- c(top = "start", bottom = "end", center = "center", justify = "justify")

check_align <- function(value, values, arg) {
  if (!is.character(value) || length(value) != 1 || !value %in% names(values)) {
    stop(
      "`", arg, "` must be one of ",
      paste0('"', names(values), '"', collapse = ", "), ".",
      call. = FALSE
    )
  }
  unname(values[value])
}

new_container <- function(type, children, horizontal_align, vertical_align, ...) {
  new_node(
    type,
    children = children,
    align = list(
      x = check_align(horizontal_align, horizontal_values, "horizontal_align"),
      y = check_align(vertical_align, vertical_values, "vertical_align")
    ),
    ...
  )
}

# Internal constructors ------------------------------------------------------

make_grid <- function(items, ncol = NULL, nrow = NULL,
                      horizontal_align = "left", vertical_align = "bottom") {
  children <- collect_items(items, keep_null = TRUE)
  n <- length(children)
  if (n == 0) stop("`new_grid()` needs at least one plot.", call. = FALSE)
  if (is.null(ncol) && is.null(nrow)) {
    ncol <- ceiling(sqrt(n))
  }
  if (is.null(ncol)) ncol <- ceiling(n / nrow)
  if (is.null(nrow)) nrow <- ceiling(n / ncol)
  if (ncol * nrow < n) {
    stop("`ncol * nrow` is too small for ", n, " plots.", call. = FALSE)
  }
  empty <- rep(list(new_node("spacer", width = NA, height = NA)), ncol * nrow - n)
  new_container(
    "grid", c(children, empty), horizontal_align, vertical_align,
    ncol = as.integer(ncol), nrow = as.integer(nrow)
  )
}

#' Build a layout row by row
#'
#' `new_row()` adds a row of plots below everything built so far,
#' `new_column()` adds a column of plots to the right of it, and `new_grid()`
#' adds a grid of plots below it. Together they build a figure step by step:
#'
#' ```r
#' new_row(p1, p2) |>
#'   new_row(p3, p4) |>
#'   new_column(p5) |>
#'   new_column(p6) |>
#'   new_row(p7)
#' ```
#'
#' **Starting and adding.** If the first argument is a layout, the new row
#' (column, grid) is added to it. Otherwise, a new layout is started, so
#' `new_row(p1, p2)` is simply a row of `p1` and `p2`. To start a new row
#' with an existing layout as its first element, wrap it in a list:
#' `new_row(list(inner), p3)`. Several plots in one call form one row
#' (column): `new_column(p5, p6)` is a single column with `p6` below `p5`,
#' whereas `new_column(p5) |> new_column(p6)` gives two columns side by side.
#' Layouts can also be passed as elements, e.g. `new_column(new_grid(...))`
#' puts a grid to the right.
#'
#' **Panel alignment.** Plots are aligned by their panel edges, not by their
#' outer boxes. Within a row, panel bottoms line up by default (so do the x
#' axes); within a column, panel left edges line up (so do the y axes).
#'
#' **Rows vs. grids.** Each row is laid out on its own: in
#' `new_row(p1, p2) |> new_row(p3, p4)`, the rows line up at the left edge of
#' their outermost panels, but `p2` and `p4` need not line up. In
#' `new_grid(p1, p2, p3, p4, ncol = 2)`, every grid column is as wide as its
#' widest panel, so `p2` sits exactly above `p4`. In a grid, `NULL` leaves an
#' empty cell.
#'
#' **Spare space.** When plots have a fixed size, a row (column, grid) often
#' has more space than its plots need. `horizontal_align` and
#' `vertical_align` decide where that space goes *inside this row*: they
#' place its plots and spread space between them. Nested rows, columns and
#' grids always fill the space they are given and arrange their own contents
#' with their own alignment. For example, in
#' `new_row(p1, p2) |> new_row(p3, p4, horizontal_align = "justify")`
#' the lower row spans the full width of the upper row, with the extra space
#' between `p3` and `p4`.
#'
#' @param ... A layout (optional, first) followed by ggplots (including
#'   tidyplots), grobs or layouts. Lists are spliced, so the output of
#'   [auto_height()] can be passed directly.
#' @param horizontal_align Where leftover horizontal space in the new row
#'   (column, grid) goes: `"left"` (default), `"right"`, `"center"` or
#'   `"justify"` (between its plots).
#' @param vertical_align Where leftover vertical space goes: `"bottom"`
#'   (default), `"top"`, `"center"` or `"justify"` (between its plots). For
#'   `new_column()` with `wrap`, the default is `"top"`.
#' @param ncol,nrow Number of grid columns and rows. Cells are filled
#'   row-wise.
#' @param wrap Maximum width in mm (maximum height for `new_column()`),
#'   axis labels, legends and gaps included. `NULL` (default) never wraps.
#'   * In `new_row()`, a row that doesn't fit is broken into several lines,
#'     like text in a word processor: each line takes as many plots as fit
#'     and is laid out on its own. `horizontal_align` applies to every line;
#'     with `"justify"` all lines but the last are spread to the width of the
#'     widest line. Best for plots of different widths.
#'   * In `new_grid()`, the number of columns is chosen as large as possible
#'     while the grid fits. All rows share the same columns, so this is best
#'     for plots of similar widths (small multiples). Can't be combined with
#'     `ncol` or `nrow`.
#'   * In `new_column()`, a column that is too tall is broken into several
#'     columns side by side, like newspaper columns. `vertical_align`
#'     (default `"top"` here) applies within every column; with `"justify"`
#'     all columns but the last are spread to the height of the tallest one.
#'     Tags run down each column before moving to the next.
#'
#'   A plot larger than `wrap` gets a line (column) of its own.
#'
#' @returns A layout.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73")
#' p4 <- dummy(name = "p4", color = "#E69F00")
#' p5 <- dummy(name = "p5", color = "#56B4E9", height = NA)
#' p6 <- dummy(name = "p6", color = "#F5C710", height = NA)
#' p7 <- dummy(name = "p7", color = "#DD227D", width = NA)
#' wide <- dummy(name = "wide", color = "#009E73", width = 45)
#'
#' new_row(p1, p2) |>
#'   new_row(p3, p4) |>
#'   new_column(p5) |>
#'   new_column(p6) |>
#'   new_row(p7)
#'
#' new_grid(p1, p2, p3, p4, ncol = 2) |>
#'   new_column(p5) |>
#'   new_row(p7)
#'
#' # break a long row into lines of at most 100 mm
#' new_row(p1, p2, p3, p4, p1, p2, wrap = 100)
#'
#' # as many grid columns as fit into 100 mm
#' new_grid(p1, p2, p3, p4, p1, p2, wrap = 100)
#'
#' # columns of at most 80 mm height
#' new_column(p1, p2, p3, p4, p1, wrap = 80)
#'
#' # alignment inside a row or column
#' new_column(wide, p1, horizontal_align = "center")
#' new_row(wide, wide) |>
#'   new_row(p1, p2, horizontal_align = "justify")
#'
#' @export
new_row <- function(..., wrap = NULL, horizontal_align = "left",
                    vertical_align = "bottom") {
  check_wrap(wrap)
  new_line(list(...), "row", horizontal_align, vertical_align, wrap = wrap)
}

#' @rdname new_row
#' @export
new_column <- function(..., wrap = NULL, horizontal_align = "left",
                       vertical_align = NULL) {
  check_wrap(wrap)
  # wrapped columns read like newspaper columns: from the top
  vertical_align <- vertical_align %||% if (is.null(wrap)) "bottom" else "top"
  new_line(list(...), "column", horizontal_align, vertical_align, wrap = wrap)
}

#' @rdname new_row
#' @export
new_grid <- function(..., ncol = NULL, nrow = NULL, wrap = NULL,
                     horizontal_align = "left", vertical_align = "bottom") {
  dots <- list(...)
  check_wrap(wrap)
  if (!is.null(wrap) && (!is.null(ncol) || !is.null(nrow))) {
    stop("Use either `wrap` or `ncol`/`nrow` in `new_grid()`, not both.", call. = FALSE)
  }
  build <- function(items) {
    if (is.null(wrap)) {
      return(make_grid(items, ncol = ncol, nrow = nrow,
                       horizontal_align = horizontal_align,
                       vertical_align = vertical_align))
    }
    # one row for now; the number of columns is chosen after measuring
    n <- length(collect_items(items, keep_null = TRUE))
    g <- make_grid(items, ncol = max(n, 1), nrow = 1,
                   horizontal_align = horizontal_align, vertical_align = vertical_align)
    g$wrap <- wrap
    g
  }
  if (length(dots) == 0) stop("`new_grid()` needs at least one plot.", call. = FALSE)
  first <- dots[[1]]
  if (!is_tidylayout(first) || !is_container(first)) return(build(dots))
  if (length(dots) == 1) {
    stop("`new_grid()` needs at least one plot to add.", call. = FALSE)
  }
  # like a new row: the grid goes below everything built so far
  extend_layout(first, "column", list(build(dots[-1])), NULL, NULL)
}

new_line <- function(dots, type, horizontal_align, vertical_align, wrap = NULL) {
  if (length(dots) == 0) {
    stop("`new_", type, "()` needs at least one plot.", call. = FALSE)
  }
  first <- dots[[1]]
  if (!is_tidylayout(first) || !is_container(first)) {
    return(new_container(type, collect_items(dots), horizontal_align, vertical_align,
                         wrap = wrap))
  }
  items <- collect_items(dots[-1])
  if (length(items) == 0) {
    stop("`new_", type, "()` needs at least one plot to add.", call. = FALSE)
  }
  line <- new_container(type, items, horizontal_align, vertical_align, wrap = wrap)
  # a new row goes below everything (column), a new column to the right (row)
  outer <- if (type == "row") "column" else "row"
  extend_layout(first, outer, list(line), NULL, NULL)
}

check_wrap <- function(wrap) {
  if (!is.null(wrap) &&
      (!is.numeric(wrap) || length(wrap) != 1 || is.na(wrap) || wrap <= 0)) {
    stop("`wrap` must be a positive width in mm, or NULL.", call. = FALSE)
  }
  invisible()
}

# Append `dots` to `layout` if it is a container of `type`; otherwise wrap
# both in a new container of `type`. Layout options stay with the root.
extend_layout <- function(layout, type, dots, horizontal_align, vertical_align) {
  layout <- as_node(layout)
  items <- collect_items(dots)
  # a wrapping row is a closed block: never append to it
  if (identical(layout$type, type) && is.null(layout$wrap)) {
    layout$children <- c(layout$children, items)
    if (!is.null(horizontal_align)) {
      layout$align$x <- check_align(horizontal_align, horizontal_values, "horizontal_align")
    }
    if (!is.null(vertical_align)) {
      layout$align$y <- check_align(vertical_align, vertical_values, "vertical_align")
    }
    return(layout)
  }
  # Layout options (tags, title, size) stay with the root.
  opts <- layout$opts
  layout$opts <- NULL
  out <- new_container(
    type, c(list(layout), items),
    horizontal_align %||% "left", vertical_align %||% "bottom"
  )
  out$opts <- opts
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Leaves in depth-first order.
layout_leaves <- function(node) {
  if (!is_container(node)) return(list(node))
  unlist(lapply(node$children, layout_leaves), recursive = FALSE)
}

# Apply `f` to every leaf, keeping the tree structure.
map_leaves <- function(node, f, ...) {
  if (!is_container(node)) return(f(node, ...))
  node$children <- lapply(node$children, map_leaves, f = f, ...)
  node
}
