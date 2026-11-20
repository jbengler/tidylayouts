# Measuring leaves ----------------------------------------------------------
#
# Every leaf is described per axis by
#   lead  - decoration before the panel span (mm), e.g. y axis + title on x
#   span  - natural size of the panel span (mm); for free panels only the
#           absolute parts inside the span (e.g. gaps between facets)
#   trail - decoration after the panel span (mm)
#   flex  - TRUE if the span can grow (free panels)
# Measuring needs an open graphics device (text sizes), so it happens at
# draw time.
#
# `zero_margin` (x, y) drops the plot margins (first and last track of a
# ggplot gtable) when `layout_spacing()` sets the gaps instead.

measure_leaves <- function(node, tag_height = 0, zero_margin = c(FALSE, FALSE)) {
  map_leaves(node, function(leaf) {
    # Only tagged plots reserve space for a tag (see `tag_group()`).
    th <- if (is_tagged(leaf)) tag_height else 0
    measure_leaf(leaf, tag_height = th, zero_margin = zero_margin)
  })
}

measure_leaf <- function(leaf, tag_height = 0, zero_margin = c(FALSE, FALSE)) {
  if (leaf$type == "spacer") {
    leaf$meas <- list(
      x = spacer_meas(leaf$width),
      y = spacer_meas(leaf$height)
    )
    return(leaf)
  }
  if (leaf$type == "grob") {
    leaf$meas <- list(
      x = list(lead = 0, span = 0, trail = 0, flex = TRUE),
      y = list(lead = tag_height, span = 0, trail = 0, flex = TRUE)
    )
    leaf$tag_height <- tag_height
    return(leaf)
  }
  gt <- leaf$gtable %||% ggplot2::ggplotGrob(leaf$plot)
  panels <- gt$layout[grepl("^panel", gt$layout$name), , drop = FALSE]
  leaf$gtable <- gt
  leaf$dims <- list(
    x = measure_tracks(gt$widths, panels$l, panels$r, grid::convertWidth, zero_margin[1]),
    y = measure_tracks(gt$heights, panels$t, panels$b, grid::convertHeight, zero_margin[2])
  )
  leaf$meas <- lapply(leaf$dims, `[[`, "meas")
  leaf$meas$y$lead <- leaf$meas$y$lead + tag_height
  leaf$tag_height <- tag_height
  leaf
}

# Convert every plot to a gtable once. This is the expensive step (it runs
# the plots' stats); the gtables don't depend on the drawing size, so they
# are reused on every redraw (window resize, RStudio pane changes).
#
# With `keep_plots = FALSE` the ggplot objects are dropped afterwards. The
# drawn grob only needs the gtables, and ggplot objects carry their data and
# environments (often 10+ MB each), which made RStudio's plot snapshots slow
# to save.
build_gtables <- function(node, keep_plots = TRUE) {
  map_leaves(node, function(leaf) {
    if (leaf$type == "plot") {
      if (is.null(leaf$gtable)) leaf$gtable <- ggplot2::ggplotGrob(leaf$plot)
      leaf$center <- leaf$center %||% leaf$plot$tidylayouts$center
      leaf$no_tag <- leaf$no_tag %||% leaf$plot$tidylayouts$no_tag
      if (!keep_plots) leaf$plot <- NULL
    }
    leaf
  })
}

spacer_meas <- function(size) {
  if (is.na(size)) {
    list(lead = 0, span = 0, trail = 0, flex = TRUE)
  } else {
    list(lead = 0, span = size, trail = 0, flex = FALSE)
  }
}

measure_tracks <- function(sizes, first, last, convert, zero_margin = FALSE) {
  n <- length(sizes)
  mm <- vapply(seq_len(n), function(i) convert(sizes[i], "mm", valueOnly = TRUE), numeric(1))
  if (zero_margin) mm[c(1, n)] <- 0
  from <- min(first)
  to <- max(last)
  panel <- sort(unique(unlist(Map(seq, first, last))))
  free <- any(vapply(panel, function(i) has_null(sizes[i]), logical(1)))
  inner <- setdiff(seq(from, to), panel)
  if (free) mm[panel] <- 0
  list(
    mm = mm,
    panel = panel,
    from = from,
    to = to,
    meas = list(
      lead = sum(mm[seq_len(from - 1)]),
      span = if (free) sum(mm[inner]) else sum(mm[seq(from, to)]),
      trail = sum(mm[seq_len(n - to) + to]),
      flex = free
    )
  )
}

has_null <- function(u) {
  any(grepl("null", unlist(grid::unitType(u, recurse = TRUE)), fixed = TRUE))
}

# Track sizes (mm) of a leaf gtable for an assigned panel span. Free panels
# share the space left after the absolute parts of the span.
resolve_tracks <- function(dims, span) {
  mm <- dims$mm
  if (dims$meas$flex) {
    mm[dims$panel] <- max(span - dims$meas$span, 0) / length(dims$panel)
  }
  mm
}
