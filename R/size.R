#' Panel sizes and margins in a layout
#'
#' A plot often has more space in a layout than its panel needs, e.g. a plot
#' below a row of plots, or next to a taller plot. These functions decide how
#' a plot uses that space:
#'
#' * `auto_width()` and `auto_height()` let the layout decide the panel size:
#'   the panel takes exactly the space the plot gets from its neighbours. It
#'   can become larger or smaller than before.
#' * `auto_margins()` keeps the panel at its size and centers the plot in the
#'   spare space, with equal room on both sides (like `margin: auto` in CSS).
#'   The tag stays at the edge of the space. Only spare space within the
#'   row, column or grid the plot sits in is used. Centering vertically
#'   (`y = TRUE`) moves the plot away from the row's shared bottom edge, so
#'   its x axis no longer lines up with its neighbours'.
#' * `set_size()` sets a fixed panel size in mm. For tidyplots it calls
#'   `tidyplots::adjust_size()`; for plain ggplots it sets
#'   `theme(panel.widths, panel.heights)`, always per panel (also for facets).
#'
#' If several plots in a row or column take spare space, they share it
#' equally. These functions work for tidyplots and plain ggplots. Layouts are
#' modified recursively, i.e. all plots inside them are changed.
#'
#' @param ... ggplots, layouts, or lists of them.
#' @param x,y Center horizontally / vertically.
#' @param width,height Panel width and height in mm. `NULL` leaves a
#'   dimension unchanged.
#'
#' @returns The modified plot or layout if one object was supplied, otherwise
#'   a list. Layout functions such as [new_row()] splice such lists, so
#'   `new_column(auto_height(p1, p2))` works.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' p3 <- dummy(name = "p3", color = "#009E73")
#' wide <- dummy(name = "wide", color = "#E69F00", width = 50)
#'
#' new_column(p1, p2) |>
#'   new_column(auto_height(p3))
#'
#' new_row(p1, p2) |>
#'   new_row(auto_width(p3))
#'
#' # keep the panel size, center the plot in the spare width
#' new_row(wide, wide) |>
#'   new_row(p1, auto_margins(p2, y = FALSE)) |>
#'   layout_tags("A")
#'
#' new_row(p1, set_size(p2, width = 45))
#'
#' @export
auto_width <- function(...) {
  place_in_space(list(...), axis = "x", mode = "stretch")
}

#' @rdname auto_width
#' @export
auto_height <- function(...) {
  place_in_space(list(...), axis = "y", mode = "stretch")
}

#' @rdname auto_width
#' @export
auto_margins <- function(..., x = TRUE, y = TRUE) {
  check_flag <- function(value, arg) {
    if (!is.logical(value) || length(value) != 1 || is.na(value)) {
      stop("`", arg, "` must be TRUE or FALSE.", call. = FALSE)
    }
  }
  check_flag(x, "x")
  check_flag(y, "y")
  if (!x && !y) stop("At least one of `x` and `y` must be TRUE.", call. = FALSE)
  out <- lapply(list(...), function(item) {
    if (x) item <- place_in_space(list(item), axis = "x", mode = "center")
    if (y) item <- place_in_space(list(item), axis = "y", mode = "center")
    item
  })
  if (length(out) == 1) out[[1]] else out
}

#' @rdname auto_width
#' @export
set_size <- function(..., width = NULL, height = NULL) {
  check_size <- function(value, arg) {
    if (is.null(value)) return(invisible())
    if (!is.numeric(value) || length(value) != 1 || is.na(value) || value <= 0) {
      stop("`", arg, "` must be a positive number (mm) or NULL. ",
           "To let the layout decide, use `auto_width()` or `auto_height()`.",
           call. = FALSE)
    }
  }
  check_size(width, "width")
  check_size(height, "height")
  out <- lapply(list(...), resize, width = width, height = height)
  if (length(out) == 1) out[[1]] else out
}

# "stretch": make the panel free (it fills the space) and drop centering.
# "center": keep the panel size and mark the plot as centered; the solver
# then lets its slot take spare space, and the renderer centers it.
place_in_space <- function(items, axis, mode) {
  out <- lapply(items, function(x) {
    if (mode == "stretch") {
      x <- resize(
        x,
        width = if (axis == "x") NA else NULL,
        height = if (axis == "y") NA else NULL
      )
    }
    set_center(x, axis, mode == "center")
  })
  if (length(out) == 1) out[[1]] else out
}

resize <- function(x, width, height) {
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
    return(lapply(x, resize, width = width, height = height))
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
#' @param width,height Panel size in mm. `NA` lets the layout decide (like
#'   [auto_width()]).
#' @param name Label shown in the panel.
#' @param color Color of the panel border and label.
#'
#' @returns `dummy()` returns a ggplot, `spacer()` a layout element.
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#'
#' new_row(p1, spacer(width = 20), p2)
#' new_row(p1, spacer(), p2) |> layout_size(width = 120)
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
