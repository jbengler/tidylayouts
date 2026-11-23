# Wrapping -------------------------------------------------------------------
#
# Rows, columns and grids created with `wrap = <mm>` are resolved after
# measuring and before solving, so the solver sees an ordinary tree:
# * a row is broken into lines like text in a word processor: each line
#   takes as many children as fit (greedy); the row becomes a column of rows.
# * a column is broken the same way by height into a row of columns.
# * a grid gets the largest number of columns for which it still fits.

# `gap` is the spacing between plots: c(horizontal, vertical) in mm.
wrap_rows <- function(node, gap = c(0, 0)) {
  if (!is_container(node)) return(node)
  node$children <- lapply(node$children, wrap_rows, gap = gap)
  if (is.null(node$wrap)) return(node)
  switch(node$type,
    grid = wrap_grid(node, gap[1]),
    row = wrap_line(node, "x", gap[1]),
    column = wrap_line(node, "y", gap[2]),
    node
  )
}

# Break a row (axis "x") or column (axis "y") into lines of at most `wrap`
# mm. A row becomes a column of rows, a column becomes a row of columns.
wrap_line <- function(node, axis, gap = 0) {
  sizes <- vapply(node$children, function(child) extent(child, axis, gap)$total, numeric(1))
  lines <- break_lines(sizes, node$wrap, gap)
  too_big <- sizes > node$wrap + 1e-9
  if (any(too_big)) {
    what <- if (axis == "x") "wider" else "taller"
    unit <- if (axis == "x") "line" else "column"
    warning(
      sum(too_big), " plot(s) are ", what, " than `wrap` (", node$wrap,
      " mm) and get a ", unit, " of their own.",
      call. = FALSE
    )
  }
  node$wrap <- NULL
  if (length(lines) == 1) return(node)

  parts <- lapply(seq_along(lines), function(i) {
    align <- node$align[[axis]]
    # like justified text: the last line is not spread apart
    if (align == "justify" && i == length(lines)) align <- "start"
    out <- node
    out$children <- node$children[lines[[i]]]
    out$align[[axis]] <- align
    out
  })
  out <- node
  out$type <- if (axis == "x") "column" else "row"
  out$children <- parts
  out$align[[axis]] <- switch(node$align[[axis]], justify = "start", node$align[[axis]])
  out
}

# Natural extent of a node along `axis`: decoration before, panel span,
# decoration after, and their total (mm).
extent <- function(node, axis, gap = 0) {
  m <- annotate_axis(node, axis, gap)$m[[axis]]
  list(lead = m$lead, span = m$span, trail = m$trail, total = m$lead + m$span + m$trail)
}

# Choose the number of grid columns: the largest that fits into `wrap`.
# Grid columns share their width (the widest panel and decorations in the
# column), so each candidate is measured as a whole.
wrap_grid <- function(node, gap = 0) {
  cells <- node$children
  n <- length(cells)
  ext <- lapply(cells, extent, axis = "x", gap = gap)
  grid_width <- function(ncol) {
    col <- (seq_len(n) - 1) %% ncol
    per_col <- vapply(split(seq_len(n), col), function(idx) {
      max(vapply(ext[idx], `[[`, numeric(1), "lead")) +
        max(vapply(ext[idx], `[[`, numeric(1), "span")) +
        max(vapply(ext[idx], `[[`, numeric(1), "trail"))
    }, numeric(1))
    sum(per_col) + gap * (ncol - 1)
  }
  fits <- vapply(seq_len(n), function(k) grid_width(k) <= node$wrap + 1e-9, logical(1))
  ncol <- if (any(fits)) max(which(fits)) else 1L
  if (!any(fits)) {
    warning(
      "The grid doesn't fit into `wrap` (", node$wrap,
      " mm) even with one column.",
      call. = FALSE
    )
  }
  nrow <- ceiling(n / ncol)
  empty <- rep(list(new_node("spacer", width = NA, height = NA)), ncol * nrow - n)
  empty <- lapply(empty, measure_leaf)
  node$children <- c(cells, empty)
  node$ncol <- as.integer(ncol)
  node$nrow <- as.integer(nrow)
  node$wrap <- NULL
  node
}

# Greedy line breaking: indices of the items on each line.
break_lines <- function(widths, limit, gap = 0) {
  lines <- list()
  current <- integer()
  used <- 0
  for (i in seq_along(widths)) {
    needed <- if (length(current) == 0) widths[i] else used + gap + widths[i]
    if (length(current) > 0 && needed > limit + 1e-9) {
      lines <- c(lines, list(current))
      current <- i
      used <- widths[i]
    } else {
      current <- c(current, i)
      used <- needed
    }
  }
  c(lines, list(current))
}
