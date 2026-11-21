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

# Compact description of a layout tree, e.g. "column(row(p1, p2), p3)".
structure_of <- function(node) {
  if (!tidylayouts:::is_container(node)) {
    if (node$type == "spacer") return("#")
    return(node$plot$layers[[1]]$aes_params$label)
  }
  inner <- vapply(node$children, structure_of, character(1))
  extra <- if (node$type == "grid") paste0("[", node$ncol, "]") else ""
  paste0(node$type, extra, "(", paste(inner, collapse = ", "), ")")
}

named_dummies <- function(n) lapply(seq_len(n), function(i) dummy(name = paste0("p", i)))

# Internal append-or-wrap, to build exact test trees compactly: `below()`
# appends to a column or wraps in one, `beside()` does the same for rows.
below <- function(layout, ..., horizontal_align = NULL, vertical_align = NULL) {
  tidylayouts:::extend_layout(layout, "column", list(...), horizontal_align, vertical_align)
}
beside <- function(layout, ..., horizontal_align = NULL, vertical_align = NULL) {
  tidylayouts:::extend_layout(layout, "row", list(...), horizontal_align, vertical_align)
}

# Test-only constructors for exact trees (the package exports only new_*()).
# Not named row()/grid(): helpers are looked up after base, so base::row() wins.
tl_row <- function(..., horizontal_align = "left", vertical_align = "bottom") {
  tidylayouts:::new_container("row", tidylayouts:::collect_items(list(...)),
                              horizontal_align, vertical_align)
}
tl_column <- function(..., horizontal_align = "left", vertical_align = "bottom") {
  tidylayouts:::new_container("column", tidylayouts:::collect_items(list(...)),
                              horizontal_align, vertical_align)
}
tl_grid <- function(..., ncol = NULL, nrow = NULL,
                 horizontal_align = "left", vertical_align = "bottom") {
  tidylayouts:::make_grid(list(...), ncol = ncol, nrow = nrow,
                          horizontal_align = horizontal_align,
                          vertical_align = vertical_align)
}
