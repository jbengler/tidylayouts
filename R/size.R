#' Stretch or center plots in the available space
#'
#' A plot often has more space in a layout than its panel needs, e.g. a
#' plot below a row of plots, or next to a taller plot. These functions let
#' the plot take that spare space:
#'
#' * `stretch_x()` and `stretch_y()` stretch the panel to fill the spare
#'   width or height.
#' * `center_x()` and `center_y()` keep the panel at its size and center the
#'   plot in the spare space, with equal room on both sides. Its tag stays at
#'   the edge of the space. Only spare space within the row, column or grid
#'   the plot sits in is used; a centered plot never makes that container
#'   wider or taller.
#'
#' `x` and `y` refer to the horizontal and vertical direction of the figure.
#' For plots with flipped coordinates, `stretch_x()` therefore stretches the
#' plot's y axis. If several plots in a row or column take spare space, they
#' share it equally.
#'
#' Panel sizes themselves are set on the plot: with `tidyplots::adjust_size()`
#' for tidyplots, or with `theme(panel.widths, panel.heights)` for plain
#' ggplots (a single unit sets the total size of all facet panels; use e.g.
#' `unit(c(30, 30), "mm")` for 30 mm per panel). These functions work for
#' both. Layouts are modified recursively, i.e. all plots inside them are
#' changed.
#'
#' @param ... ggplots, layouts, or lists of them.
#'
#' @returns The modified plot or layout if one object was supplied, otherwise
#'   a list. Layout functions such as [row()] splice such lists, so
#'   `add_right(stretch_y(p1, p2))` works.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73")
#' wide <- dummy(name = "wide", color = "#E69F00", width = 50)
#'
#' column(p1, p2) |>
#'   add_right(stretch_y(p3))
#'
#' row(p1, p2) |>
#'   add_below(stretch_x(p3))
#'
#' # keep the panel size, center the plot in the spare width
#' row(wide, wide) |>
#'   add_below(row(p1, center_x(p2))) |>
#'   layout_tags("A")
#'
#' @export
stretch_x <- function(...) {
  place_in_space(list(...), axis = "x", mode = "stretch")
}

#' @rdname stretch_x
#' @export
stretch_y <- function(...) {
  place_in_space(list(...), axis = "y", mode = "stretch")
}

#' @rdname stretch_x
#' @export
center_x <- function(...) {
  place_in_space(list(...), axis = "x", mode = "center")
}

#' @rdname stretch_x
#' @export
center_y <- function(...) {
  place_in_space(list(...), axis = "y", mode = "center")
}

# "stretch": make the panel free (it fills the space) and drop centering.
# "center": keep the panel size and mark the plot as centered; the solver
# then lets its slot take spare space, and the renderer centers it.
place_in_space <- function(items, axis, mode) {
  out <- lapply(items, function(x) {
    if (mode == "stretch") {
      x <- set_size(
        x,
        width = if (axis == "x") NA else NULL,
        height = if (axis == "y") NA else NULL
      )
    }
    set_center(x, axis, mode == "center")
  })
  if (length(out) == 1) out[[1]] else out
}

set_size <- function(x, width, height) {
  if (is_ggplot(x)) return(set_plot_size(x, width, height))
  if (is_tidylayout(x)) {
    return(map_leaves(x, function(leaf) {
      if (leaf$type == "plot") {
        leaf$plot <- set_plot_size(leaf$plot, width, height)
        leaf$gtable <- NULL
      }
      leaf
    }))
  }
  if (is.list(x) && !is.object(x)) {
    return(lapply(x, set_size, width = width, height = height))
  }
  stop(
    "Can't change the size of an object of class <", class(x)[1], ">.",
    call. = FALSE
  )
}

# The center flag is stored on the plot (it survives later changes such as
# `+ theme()`) and copied to layout leaves.
set_center <- function(x, axis, value) {
  if (is_ggplot(x)) {
    x$tidylayouts$center[[axis]] <- value
    return(x)
  }
  if (is_tidylayout(x)) {
    return(map_leaves(x, function(leaf) {
      if (leaf$type == "plot") {
        leaf$plot <- set_center(leaf$plot, axis, value)
        leaf$center[[axis]] <- value
      }
      leaf
    }))
  }
  if (is.list(x) && !is.object(x)) {
    return(lapply(x, set_center, axis = axis, value = value))
  }
  stop(
    "Can't change the size of an object of class <", class(x)[1], ">.",
    call. = FALSE
  )
}

unit_to_mm <- c(mm = 1, cm = 10, `in` = 25.4, inch = 25.4, inches = 25.4,
                pt = 25.4 / 72.27, points = 25.4 / 72.27, bigpts = 25.4 / 72)

set_plot_size <- function(plot, width, height) {
  if (inherits(plot, "tidyplot") && requireNamespace("tidyplots", quietly = TRUE)) {
    # Keep tidyplots' own size bookkeeping consistent.
    stored_unit <- plot$tidyplot$unit %||% "mm"
    factor <- unit_to_mm[[stored_unit]]
    as_mm <- function(new, stored) {
      if (!is.null(new)) return(new)
      if (is.null(stored) || is.na(stored)) return(stored)
      stored * factor
    }
    return(tidyplots::adjust_size(
      plot,
      width = as_mm(width, plot$tidyplot$width),
      height = as_mm(height, plot$tidyplot$height),
      unit = "mm"
    ))
  }
  if (!is.null(width)) {
    plot$theme$panel.widths <- if (is.na(width)) NULL else grid::unit(c(width, width), "mm")
  }
  if (!is.null(height)) {
    plot$theme$panel.heights <- if (is.na(height)) NULL else grid::unit(c(height, height), "mm")
  }
  plot
}

#' Placeholders
#'
#' `dummy()` creates a placeholder plot, useful for sketching layouts.
#' `spacer()` creates an empty slot; with `NA` sizes it absorbs leftover
#' space, with a size in mm it is a fixed gap.
#'
#' @param width,height Panel size in mm. `NA` lets the panel stretch.
#' @param name Label shown in the panel.
#' @param color Color of the panel border and label.
#'
#' @returns `dummy()` returns a ggplot, `spacer()` a layout element.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#'
#' row(p1, spacer(width = 20), p2)
#' row(p1, spacer(), p2) |> layout_size(width = 120)
#'
#' @export
dummy <- function(width = 30, height = 30, name = "dummy", color = "darkgrey") {
  p <- ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = 0, label = name, size = 20, size.unit = "pt",
                      colour = color) +
    ggplot2::coord_cartesian(xlim = c(-1, 1), ylim = c(-1, 1), expand = FALSE) +
    ggplot2::theme_void() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(
        colour = color, fill = grDevices::adjustcolor(color, alpha.f = 0.35),
        linewidth = 1
      ),
      plot.margin = ggplot2::margin(5.5, 5.5, 5.5, 5.5)
    )
  set_plot_size(p, width, height)
}

#' @rdname dummy
#' @export
spacer <- function(width = NA, height = NA) {
  new_node("spacer", width = width, height = height)
}
