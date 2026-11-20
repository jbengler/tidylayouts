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

# Flatten `...` into a list of nodes. Plain lists (e.g. from `stretch_y(p1, p2)`)
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

#' Arrange plots in rows, columns and grids
#'
#' `row()` places plots side by side, `column()` stacks them, and `grid()`
#' arranges them in a table with shared row and column tracks.
#'
#' Plots are aligned by their panel edges, not by their outer boxes. Within a
#' row, panel bottoms line up by default (so do the x axes); within a column,
#' panel left edges line up (so do the y axes).
#'
#' **Alignment.** When plots have a fixed size, a container often has more
#' space than its plots need. `horizontal_align` and `vertical_align` decide
#' where that space goes *inside this container*: they place its direct plots
#' and spread space between them. Nested rows, columns and grids always fill
#' the space they are given and arrange their own contents with their own
#' alignment. For example, in
#' `row(p1, p2) |> add_below(row(p3, p4, horizontal_align = "justify"))`
#' the lower row spans the full width of the upper row, with the extra space
#' between `p3` and `p4`.
#'
#' `column(row(p1, p2), row(p3, p4))` is not the same as
#' `grid(p1, p2, p3, p4, ncol = 2)`: in the column of rows, each row is laid
#' out independently, so `p2` and `p4` need not line up. In the grid, every
#' grid column is as wide as its widest panel, so `p2` sits exactly above `p4`.
#'
#' @param ... ggplots (including tidyplots), grobs or layouts. Lists are
#'   spliced, so the output of [stretch_y()] can be passed directly. In
#'   `row()` and `column()`, `NULL` is ignored; in `grid()`, `NULL` leaves an
#'   empty cell.
#' @param horizontal_align Where leftover horizontal space in this container
#'   goes: `"left"` (default), `"right"`, `"center"` or `"justify"` (between
#'   its plots).
#' @param vertical_align Where leftover vertical space in this container
#'   goes: `"bottom"` (default), `"top"`, `"center"` or `"justify"` (between
#'   its plots).
#' @param ncol,nrow Number of grid columns and rows. Cells are filled
#'   row-wise.
#'
#' @returns A layout.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73", width = 45)
#'
#' row(p1, p2)
#' column(p1, p3)
#' column(p1, p3, horizontal_align = "center")
#' grid(p1, p2, p3, p1, ncol = 2)
#'
#' # nested rows fill the available width and use their own alignment
#' row(p3, p3) |> add_below(row(p1, p2, horizontal_align = "justify"))
#'
#' @export
row <- function(..., horizontal_align = "left", vertical_align = "bottom") {
  new_container("row", collect_items(list(...)), horizontal_align, vertical_align)
}

#' @rdname row
#' @export
column <- function(..., horizontal_align = "left", vertical_align = "bottom") {
  new_container("column", collect_items(list(...)), horizontal_align, vertical_align)
}

#' @rdname row
#' @export
grid <- function(..., ncol = NULL, nrow = NULL,
                 horizontal_align = "left", vertical_align = "bottom") {
  children <- collect_items(list(...), keep_null = TRUE)
  n <- length(children)
  if (n == 0) stop("`grid()` needs at least one plot.", call. = FALSE)
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

#' Extend a layout
#'
#' `add_right()` places plots to the right of a layout, `add_below()` places
#' them below.
#'
#' If the layout is already a row (for `add_right()`) or a column (for
#' `add_below()`), the plots are appended to it. Otherwise, including for
#' grids, the layout is wrapped in a new row or column together with the new
#' plots.
#'
#' @param layout A layout, ggplot or grob.
#' @inheritParams row
#' @param horizontal_align,vertical_align Alignment of the resulting row or
#'   column, i.e. where it places its direct plots (see [row()]). To align the
#'   plots inside a nested row or column, set the alignment on that row or
#'   column instead. `NULL` keeps the current alignment when appending, and
#'   uses the default (`"left"`, `"bottom"`) when wrapping.
#'
#' @returns A layout.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73", height = NA)
#' p4 <- dummy(name = "p4", color = "#E69F00", width = NA)
#'
#' row(p1, p2) |>
#'   add_right(p3) |>
#'   add_below(p4)
#'
#' @export
add_right <- function(layout, ..., horizontal_align = NULL, vertical_align = NULL) {
  extend_layout(layout, "row", list(...), horizontal_align, vertical_align)
}

#' @rdname add_right
#' @export
add_below <- function(layout, ..., horizontal_align = NULL, vertical_align = NULL) {
  extend_layout(layout, "column", list(...), horizontal_align, vertical_align)
}

extend_layout <- function(layout, type, dots, horizontal_align, vertical_align) {
  layout <- as_node(layout)
  items <- collect_items(dots)
  if (identical(layout$type, type)) {
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
