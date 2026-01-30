
#' Create a new layout
#'
#' @param ... tidyplots to layout.
#'
#' @returns A layout of tidyplots
#'
#' @examples
#' library(tidyplots)
#'
#' study |>
#'   tidyplot(x = treatment, y = score) |>
#'   add_boxplot()
#'
#' @export
row <- function(...) {
  ggalign::align_plots(..., nrow = 1)
}
#' @rdname row
#' @export
column <- function(...) {
  ggalign::align_plots(..., ncol = 1)
}
#' @rdname row
#' @export
grid <- function(...) {
  ggalign::align_plots(...)
}


#' Add more elements to a layout
#'
#' @param ... tidyplots to layout.
#'
#' @returns A layout of tidyplots
#'
#' @examples
#' study |>
#'   tidyplot(x = treatment, y = score) |>
#'   add_boxplot()
#'
#' @export
add_right <- row
#' @rdname add_right
#' @export
add_below <- column


#' Placeholders
#'
#' @param ... tidyplots to layout.
#'
#' @returns A layout of tidyplots
#'
#' @examples
#' # dummy plots
#' dummy(name = "p1", color = "#0072B2")
#' dummy(name = "p2", color = "#D55E00")
#' dummy(height = NA, name = "p3", color = "#009E73")
#' dummy(width = NA, name = "p4", color = "#E69F00")
#' dummy(width = 40, height = 20, name = "p4", color = "#E69F00")
#' dummy(width = NA, height = NA, name = "p4", color = "#E69F00")
#'
#' # empty spacers
#' p1 <- dummy(width = 30, height = 30, name = "p1", color = "#0072B2")
#' grid(p1, p1, p1, p1, p1, p1)
#' grid(p1, spacer(), p1, spacer(), p1, p1)
#' grid(p1, spacer(), p1, spacer(width = 50), p1, p1)
#' grid(p1, spacer(), p1, spacer(height = 50), p1, p1)
#' grid(p1, spacer(), p1, spacer(width = 50, height = 50), p1, p1)
#'
#' @export
spacer <- function(width = NULL, height = NULL) {
  if (is.null(width) && is.null(height)) return(NULL)
  data.frame(x = 1, y = 1) |>
    tidyplots::tidyplot(x, y, width = NA, height = NA) |>
    tidyplots::adjust_size(width = width, height = height) |>
    tidyplots::remove_x_axis() |>
    tidyplots::remove_y_axis()
}
#' @rdname spacer
#' @export
dummy <- function(width = 30, height = 30, name = "dummy", color = "darkgrey") {
  data.frame(x = 1, y = 1, name = name) |>
    tidyplots::tidyplot(x, y, width = width, height = height) |>
    tidyplots::add_data_labels(label = name, fontsize = 20,
                               label_position = "center", color = color) |>
    tidyplots::adjust_theme_details(panel.background = ggplot2::element_rect(
      color = color, fill = scales::col_lighter(color, 30), linewidth = 2
    )) |>
    tidyplots::remove_x_axis() |>
    tidyplots::remove_y_axis()
}



#' Layout adjustments
#'
#' @param ... tidyplots to layout.
#'
#' @returns A layout of tidyplots
#'
#' @examples
#' study |>
#'   tidyplot(x = treatment, y = score) |>
#'   add_boxplot()
#'
#' @export
layout_tags <- function(layout, ...) {
  layout + ggalign::layout_tags(...)
}
#' @rdname layout_tags
#' @export
layout_alignment <- function(layout,
                             horizontal = c("left", "right", "center", "justified"),
                             vertical = c("top", "bottom", "center", "justified")) {
  layout
}
#' @rdname layout_tags
#' @export
layout_spacing <- function(layout, spacing = NULL) {
  layout
}
#' @rdname layout_tags
#' @export
layout_title <- function(layout, ...) {
  layout + ggalign::layout_title(...)
}
#' @rdname layout_tags
#' @export
layout_size <- function(layout,
                        overall_width = NULL,
                        overall_height = NULL) {
  layout
}
