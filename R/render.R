# Rendering -----------------------------------------------------------------
#
# A layout is drawn through a gTree whose children are computed at draw
# time (`makeContent()`), when the available space and text metrics are
# known. Every leaf gtable gets absolute track sizes and is placed in its
# own viewport, so its panel edges land exactly where the solver put them.

layout_grob <- function(layout) {
  grid::gTree(
    layout = build_gtables(as_node(layout), keep_plots = FALSE),
    cl = "tidylayout_grob"
  )
}

#' @exportS3Method grid::makeContent
makeContent.tidylayout_grob <- function(x) {
  available <- c(
    grid::convertWidth(grid::unit(1, "npc"), "mm", valueOnly = TRUE),
    grid::convertHeight(grid::unit(1, "npc"), "mm", valueOnly = TRUE)
  )
  grid::setChildren(x, render_layout(x$layout, available))
}

text_height <- function(label, gp) {
  grid::convertHeight(grid::grobHeight(grid::textGrob(label, gp = gp)), "mm", valueOnly = TRUE)
}

# Measure and solve. Needs an open graphics device.
prepare_layout <- function(layout, available = c(NA, NA)) {
  opts <- layout$opts
  tag_height <- 0
  if (!is.null(opts$tags)) {
    tag_height <- text_height("Ag", opts$tags$gp) + 1
  }
  title_height <- 0
  if (!is.null(opts$title)) {
    title_height <- text_height(opts$title$label, opts$title$gp) + 2
  }
  spacing <- c(opts$spacing$horizontal %||% NA, opts$spacing$vertical %||% NA)
  outer <- opts$spacing$outer %||% 0
  node <- measure_leaves(layout, tag_height, zero_margin = !is.na(spacing))
  node <- wrap_rows(node, gap = if (is.na(spacing[1])) 0 else spacing[1])
  sol <- solve_layout(
    node,
    available = available,
    size = c(opts$width %||% NA, opts$height %||% NA),
    top = title_height,
    spacing = ifelse(is.na(spacing), 0, spacing),
    outer = outer
  )
  sol$outer <- outer
  sol$opts <- opts
  sol
}

render_layout <- function(layout, available) {
  sol <- prepare_layout(layout, available)
  # Centre the figure in the available space (top-left if it doesn't fit).
  offset <- pmax((available - sol$size) / 2, 0)
  offset[is.na(offset)] <- 0
  mm <- function(v) grid::unit(v, "mm")
  from_top <- function(v) grid::unit(1, "npc") - mm(v)

  leaves <- layout_leaves(sol$node)
  tagged <- vapply(leaves, is_tagged, logical(1))
  labels <- character(length(leaves))
  if (!is.null(sol$opts$tags)) {
    labels[tagged] <- tag_labels(sol$opts$tags$tags, sum(tagged))
  }

  # Two passes: all plot backgrounds first, then all plots. Otherwise a
  # plot's background would paint over axis labels of its neighbours that
  # stick out past their box (e.g. with `layout_spacing(inner = 0)`).
  backgrounds <- list()
  grobs <- list()
  for (i in seq_along(leaves)) {
    leaf <- leaves[[i]]
    if (leaf$type == "spacer") next
    p <- sol$placement[[leaf$id]]
    if (leaf$type == "plot") {
      widths <- resolve_tracks(leaf$dims$x, p$x$span)
      heights <- resolve_tracks(leaf$dims$y, p$y$span)
      gt <- leaf$gtable
      gt$widths <- mm(widths)
      gt$heights <- mm(heights)
      gt$respect <- FALSE
      x0 <- p$x$start - leaf$dims$x$meas$lead
      y0 <- p$y$start - leaf$dims$y$meas$lead
      content <- gt
      box <- c(sum(widths), sum(heights))
      tag_x <- x0
      # Centered plots: the slot took the spare space; center the plot in it
      # (like auto margins). The tag stays at the slot's edge.
      if (is_centered(leaf, "x")) {
        slot <- slot_extent(p$x)
        x0 <- slot[1] + (slot[2] - slot[1] - box[1]) / 2
        tag_x <- slot[1]
      }
      if (is_centered(leaf, "y")) {
        slot <- slot_extent(p$y) + c(leaf$tag_height, 0)
        y0 <- slot[1] + (slot[2] - slot[1] - box[2]) / 2
      }
    } else {
      x0 <- p$x$start
      y0 <- p$y$start
      tag_x <- x0
      content <- leaf$grob
      box <- c(p$x$span, p$y$span)
    }
    vp <- grid::viewport(
      x = mm(offset[1] + x0), y = from_top(offset[2] + y0),
      width = mm(box[1]), height = mm(box[2]),
      just = c("left", "top")
    )
    if (leaf$type == "plot") {
      split <- split_background(content)
      content <- split$plot
      if (!is.null(split$background)) {
        backgrounds <- c(backgrounds, list(
          grid::gTree(children = grid::gList(split$background), vp = vp)
        ))
      }
    }
    grobs <- c(grobs, list(grid::gTree(children = grid::gList(content), vp = vp)))

    if (nzchar(labels[i])) {
      band <- min(p$y$band, p$y$start - leaf$meas$y$lead)
      grobs <- c(grobs, list(grid::textGrob(
        labels[i],
        x = mm(offset[1] + tag_x), y = from_top(offset[2] + band),
        just = c("left", "top"), gp = sol$opts$tags$gp
      )))
    }
  }

  if (!is.null(sol$opts$title)) {
    grobs <- c(grobs, list(grid::textGrob(
      sol$opts$title$label,
      x = mm(offset[1] + sol$outer), y = from_top(offset[2] + sol$outer),
      just = c("left", "top"), gp = sol$opts$title$gp
    )))
  }
  do.call(grid::gList, c(backgrounds, grobs))
}

# Take the plot background out of a ggplot gtable, so it can be drawn in a
# separate first pass. Returns the background (or NULL) and the remaining
# gtable.
split_background <- function(gt) {
  idx <- which(gt$layout$name == "background")
  if (length(idx) == 0) return(list(background = NULL, plot = gt))
  background <- gt$grobs[[idx[1]]]
  gt$grobs <- gt$grobs[-idx]
  gt$layout <- gt$layout[-idx, , drop = FALSE]
  list(background = background, plot = gt)
}

is_centered <- function(leaf, axis) {
  isTRUE(leaf$center[[axis]]) && !leaf$dims[[axis]]$meas$flex
}

# Start and end (mm) of the slot a leaf was placed in, decorations included.
slot_extent <- function(p) {
  c(p$start - p$slot_lead, p$start + p$span + p$slot_trail)
}

tag_labels <- function(tags, n) {
  if (length(tags) > 1) {
    out <- rep("", n)
    k <- min(n, length(tags))
    out[seq_len(k)] <- tags[seq_len(k)]
    return(out)
  }
  seq_n <- seq_len(n)
  switch(tags,
    A = LETTERS[(seq_n - 1) %% 26 + 1],
    a = letters[(seq_n - 1) %% 26 + 1],
    `1` = as.character(seq_n),
    I = as.character(utils::as.roman(seq_n)),
    i = tolower(as.character(utils::as.roman(seq_n))),
    stop('`tags` must be "A", "a", "1", "I", "i" or a character vector.', call. = FALSE)
  )
}

#' @export
print.tidylayout <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}

#' @exportS3Method grid::grid.draw
grid.draw.tidylayout <- function(x, recording = TRUE) {
  grid::grid.draw(layout_grob(x), recording = recording)
}

#' Save a layout
#'
#' Saves a layout at its exact physical size. If all panels have a fixed
#' size, the figure size is computed from the layout. If some panels are
#' free, set the size with `width`/`height` or [layout_size()].
#'
#' @param layout A layout.
#' @param filename File name; the extension determines the format.
#' @param width,height Figure size in mm. Overrides [layout_size()].
#' @param dpi Resolution for raster formats.
#' @param bg Background colour.
#' @param ... Passed on to [ggplot2::ggsave()].
#'
#' @returns The figure size in mm (invisibly).
#'
#' @examples
#' p1 <- dummy(name = "p1", color = "#0072B2")
#' p2 <- dummy(name = "p2", color = "#D55E00")
#' file <- tempfile(fileext = ".pdf")
#' save_layout(row(p1, p2), file)
#'
#' @export
save_layout <- function(layout, filename, width = NULL, height = NULL,
                        dpi = 300, bg = "white", ...) {
  layout <- as_node(layout)
  layout$opts$width <- width %||% layout$opts$width
  layout$opts$height <- height %||% layout$opts$height
  layout <- with_null_device(build_gtables(layout, keep_plots = FALSE))
  size <- layout_dims(layout)
  ggplot2::ggsave(
    filename, plot = layout, width = size[1], height = size[2], units = "mm",
    dpi = dpi, bg = bg, ...
  )
  invisible(size)
}

# Evaluate `expr` with a temporary null pdf device (needed to measure text),
# then make the previously active device current again. `dev.off()` alone
# would activate the *next* open device, not the previous one.
with_null_device <- function(expr) {
  old <- grDevices::dev.cur()
  grDevices::pdf(NULL)
  on.exit({
    grDevices::dev.off()
    if (old > 1) grDevices::dev.set(old)
  })
  expr
}

# Figure size (mm) of a layout. Errors if free panels leave it undefined.
layout_dims <- function(layout) {
  layout <- as_node(layout)
  sol <- with_null_device(prepare_layout(layout))
  m <- list(sol$node$m$x, sol$node$m$y)
  set <- c(!is.null(layout$opts$width), !is.null(layout$opts$height))
  undefined <- c("width", "height")[!vapply(m, `[[`, logical(1), "bounded") & !set]
  if (length(undefined) > 0) {
    stop(
      "The layout has free panels, so its ", paste(undefined, collapse = " and "),
      " can't be determined. Set it with `width`/`height` or `layout_size()`.",
      call. = FALSE
    )
  }
  unname(sol$size)
}
