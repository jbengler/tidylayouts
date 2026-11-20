# A leaf with synthetic measurements, for testing the solver without ggplot2.
fake <- function(w = 30, h = 30, lead_x = 10, trail_x = 2, lead_y = 2, trail_y = 10) {
  m <- function(span, lead, trail) {
    list(lead = lead, span = if (is.na(span)) 0 else span, trail = trail, flex = is.na(span))
  }
  node <- tidylayouts:::new_node("spacer", width = w, height = h)
  node$meas <- list(x = m(w, lead_x, trail_x), y = m(h, lead_y, trail_y))
  node
}

solve_fake <- function(layout, ...) {
  sol <- tidylayouts:::solve_layout(layout, ...)
  sol$placement
}

# Measure and solve real plots on a null device.
solve_real <- function(layout, available = c(NA, NA)) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  sol <- tidylayouts:::prepare_layout(layout, available)
  leaves <- tidylayouts:::layout_leaves(sol$node)
  names(leaves) <- vapply(leaves, `[[`, character(1), "id")
  list(sol = sol, leaves = leaves)
}

centered <- function(node, axis = "x") {
  node$center[[axis]] <- TRUE
  node
}

# Set a fixed panel size (mm) on a plot, as `adjust_size()` / `theme(panel.widths)` would.
fix <- function(p, width = NULL, height = NULL) {
  tidylayouts:::set_plot_size(p, width, height)
}
