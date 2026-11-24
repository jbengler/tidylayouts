#' Layout options
#'
#' Options that apply to the whole figure.
#'
#' * `layout_size()` sets the figure size in mm, e.g. a journal column width
#'   (Nature: 89 mm single column, 183 mm double column). Free panels absorb
#'   the extra space; if there are none, it becomes slack placed according to
#'   the containers' alignment.
#' * `layout_spacing()` sets the gaps between neighbouring plots in mm,
#'   measured between their outer boxes (axis labels, legends and tags
#'   included). It replaces the plots' own `plot.margin`, so gaps are even
#'   when plots use different themes. Without it, the gaps come from the
#'   plot margins. `outer` adds a margin around the whole figure. Note that
#'   axis labels can stick out past their panel (e.g. the last tick label);
#'   ggplot2 normally relies on the plot margin for that space. With small
#'   gaps, such labels may overlap neighbouring plots, and at the figure's
#'   edge they can be cut off; use a small `outer` margin (1-2 mm) then.
#' * `layout_tags()` adds panel tags. Tags are aligned at the top of their
#'   row, even when plots in that row have different heights. To let several
#'   plots share one tag, use [tag_group()].
#' * `layout_title()` adds a title above the figure.
#'
#' @param layout A layout, ggplot, grob or other object with an
#'   [as_layout_gtable()] method.
#' @param width,height Figure size in mm. `NULL` leaves it unchanged, `NA`
#'   unsets it.
#' @param inner Gap between plots in mm. One value for both directions, or
#'   `c(horizontal, vertical)`. `NULL` leaves it unchanged, `NA` returns to
#'   the plot margins (also per direction, e.g. `c(NA, 5)`).
#' @param outer Margin around the whole figure in mm (default 0). `NULL`
#'   leaves it unchanged, `NA` resets it.
#' @param tags `"A"`, `"a"`, `"1"`, `"I"`, `"i"`, or a character vector of
#'   labels.
#' @param title Title text.
#' @param fontsize,fontface Text style.
#'
#' @returns A layout.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00", height = 45)
#' p3 <- dummy(name = "p3", color = "#009E73", width = NA)
#'
#' new_row(p1, p2) |>
#'   new_row(p3) |>
#'   layout_tags("A") |>
#'   layout_title("My figure") |>
#'   layout_size(width = 120)
#'
#' new_row(p1, p2) |>
#'   new_row(p3) |>
#'   layout_spacing(inner = 2, outer = 5)
#'
#' new_row(p1, p2) |>
#'   new_row(p3) |>
#'   layout_spacing(inner = c(2, 6))
#'
#' @export
layout_size <- function(layout, width = NULL, height = NULL) {
  layout <- as_node(layout)
  if (!is.null(width)) layout$opts$width <- if (is.na(width)) NULL else width
  if (!is.null(height)) layout$opts$height <- if (is.na(height)) NULL else height
  layout
}

#' @rdname layout_size
#' @export
layout_spacing <- function(layout, inner = NULL, outer = NULL) {
  layout <- as_node(layout)
  check_mm(inner, "inner", max_length = 2)
  check_mm(outer, "outer", max_length = 1)
  opts <- layout$opts$spacing %||% list()
  if (!is.null(inner)) {
    inner <- rep_len(inner, 2)
    opts <- set_opt(opts, "horizontal", inner[1])
    opts <- set_opt(opts, "vertical", inner[2])
  }
  if (!is.null(outer)) opts <- set_opt(opts, "outer", outer)
  layout$opts$spacing <- opts
  layout
}

check_mm <- function(value, arg, max_length) {
  if (is.null(value)) return(invisible())
  ok <- length(value) >= 1 && length(value) <= max_length &&
    (is.numeric(value) || all(is.na(value))) &&
    all(is.na(value) | value >= 0)
  if (!ok) {
    what <- if (max_length == 1) "a single" else "one or two"
    stop("`", arg, "` must be ", what, " non-negative number(s) in mm, NA or NULL.",
         call. = FALSE)
  }
  invisible()
}

set_opt <- function(opts, name, value) {
  opts[[name]] <- if (is.na(value)) NULL else value
  opts
}

#' @rdname layout_size
#' @export
layout_tags <- function(layout, tags = "A", fontsize = 10, fontface = "bold") {
  layout <- as_node(layout)
  layout$opts$tags <- list(
    tags = tags,
    gp = grid::gpar(fontsize = fontsize, fontface = fontface)
  )
  layout
}

#' @rdname layout_size
#' @export
layout_title <- function(layout, title, fontsize = 12, fontface = "bold") {
  layout <- as_node(layout)
  layout$opts$title <- list(
    label = title,
    gp = grid::gpar(fontsize = fontsize, fontface = fontface)
  )
  layout
}
