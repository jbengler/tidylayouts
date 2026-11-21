#' Lay out plots from a design string
#'
#' `layout_plots()` describes a whole figure in one call: a design string
#' shows where each plot goes.
#'
#' **Design.** Each line of `design` is a row of cells, each character a cell:
#' * Each letter is one plot. A plot may cover several cells, which must form
#'   a rectangle. Uppercase and lowercase letters are different plots.
#' * `#` is an empty cell.
#'
#' The design describes the arrangement, not the size: plots keep their own
#' panel sizes, also when they span several cells. To let a plot fill the
#' space it spans, list it in `auto_width` or `auto_height` (or center it
#' with `auto_margins_x`/`auto_margins_y`). Designs that can't be split along full rows and
#' columns (e.g. a pinwheel) are not supported.
#'
#' **Arrangement.** The design is split along full rows and columns that no
#' plot crosses. Blocks of plots without spanning plots are built according
#' to `arrange_by`. With `"row"` (default), each line of the design becomes a
#' row, so `"AB\nCD"` is the same as
#' `new_row(A, B) |> new_row(C, D)`: each line is laid out on its own. With
#' `"column"`, each design column becomes a column. With `"grid"`, the
#' block becomes a grid (see [new_grid()]), so plots in the same row and column of the
#' design share their lines.
#'
#' **Plot order.** Plots in `...` are assigned in alphabetical order of the
#' letters: `A` to `Z`, then `a` to `z`.
#'
#' **Tags.** The letters only place the plots. Tags are numbered in reading
#' order, as with [layout_tags()]. To let several plots share one tag, pass
#' them through [tag_group()], e.g. `layout_plots(tag_group(p1, p2), p3, ...)`.
#'
#' The result is a normal layout, so it can be extended and adjusted with
#' [new_row()], [layout_spacing()] etc.
#'
#' @param ... ggplots, grobs or layouts, in the order described above. Lists
#'   are spliced.
#' @param design A string with one line per row of cells.
#' @param arrange_by How blocks without spanning plots are built: `"row"`
#'   (default, one row per design line), `"column"` (one column per design
#'   column) or `"grid"` (shared rows and columns).
#' @param tags Panel tags, as in [layout_tags()]: `"A"`, `"a"`, `"1"`, `"I"`,
#'   `"i"` or a character vector. `NULL` (default) adds no tags.
#' @param auto_width,auto_height Letters of plots whose panel size is
#'   decided by the layout (see [auto_width()]), e.g. `"EF"`.
#' @param auto_margins_x,auto_margins_y Letters of plots that keep their
#'   panel size and are centered horizontally or vertically in the available
#'   space (see [auto_margins()]).
#'
#' @returns A layout.
#'
#' @examples
#' p <- lapply(paste0("p", 1:7), function(x) dummy(name = x))
#'
#' layout_plots(
#'   p,
#'   design = "
#'     ABEF
#'     CDEF
#'     GGGG
#'   ",
#'   auto_width = "G",
#'   auto_height = "EF",
#'   tags = "A"
#' )
#'
#' # the first two plots share tag A; # is an empty cell
#' layout_plots(
#'   tag_group(p[[1]], p[[2]]), p[[3]], p[[4]],
#'   design = "
#'     ABC
#'     D##
#'   ",
#'   tags = "A",
#'   auto_margins_x = "D"
#' )
#'
#' @export
layout_plots <- function(..., design, arrange_by = c("row", "column", "grid"),
                         tags = NULL,
                         auto_width = NULL, auto_height = NULL,
                         auto_margins_x = NULL, auto_margins_y = NULL) {
  arrange_by <- match.arg(arrange_by)
  cells <- parse_design(design)
  ids <- design_ids(cells)
  plots <- collect_items(list(...))
  if (length(plots) != length(ids$order)) {
    stop(
      "The design has ", length(ids$order), " plots (",
      paste(ids$order, collapse = ", "), ") but ",
      length(plots), " were supplied.",
      call. = FALSE
    )
  }
  names(plots) <- ids$order

  modifiers <- list(
    stretch_x = letters_of(auto_width, "auto_width", cells),
    stretch_y = letters_of(auto_height, "auto_height", cells),
    center_x = letters_of(auto_margins_x, "auto_margins_x", cells),
    center_y = letters_of(auto_margins_y, "auto_margins_y", cells)
  )
  both <- c(
    intersect(modifiers$stretch_x, modifiers$center_x),
    intersect(modifiers$stretch_y, modifiers$center_y)
  )
  if (length(both) > 0) {
    stop(
      "Plot(s) ", paste(unique(both), collapse = ", "),
      " can't have both an automatic size and automatic margins in the same direction.",
      call. = FALSE
    )
  }

  for (id in ids$order) {
    plots[[id]] <- apply_design_modifiers(plots[[id]], id, modifiers)
  }

  layout <- build_design(ids$matrix, plots, arrange_by)
  if (!is.null(tags)) layout <- layout_tags(layout, tags = tags)
  layout
}

# Design parsing ------------------------------------------------------------

parse_design <- function(design) {
  if (!is.character(design) || length(design) != 1) {
    stop("`design` must be a single string.", call. = FALSE)
  }
  lines <- trimws(strsplit(design, "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  if (length(lines) == 0) stop("`design` is empty.", call. = FALSE)
  chars <- strsplit(lines, "", fixed = TRUE)
  width <- unique(lengths(chars))
  if (length(width) != 1) {
    stop("All rows of `design` must have the same number of cells.", call. = FALSE)
  }
  cells <- matrix(unlist(chars), nrow = length(lines), byrow = TRUE)
  bad <- setdiff(unique(as.vector(cells)), c(LETTERS, letters, "#"))
  if (length(bad) > 0) {
    stop(
      "`design` may only contain letters and `#`, not ",
      paste0('"', bad, '"', collapse = ", "), ".",
      call. = FALSE
    )
  }
  cells
}

# Give every plot an id: each letter is one plot, each `#` its own empty
# cell. Returns the id matrix and the plot order (A-Z, then a-z).
design_ids <- function(cells) {
  ids <- cells
  empty <- which(cells == "#")
  ids[empty] <- paste0("#", seq_along(empty))

  used <- unique(as.vector(cells[cells != "#"]))
  order <- c(LETTERS[LETTERS %in% used], letters[letters %in% used])
  for (ch in order) {
    where <- which(cells == ch, arr.ind = TRUE)
    rows <- range(where[, 1])
    cols <- range(where[, 2])
    block <- cells[rows[1]:rows[2], cols[1]:cols[2], drop = FALSE]
    if (any(block != ch)) {
      stop("The cells of `", ch, "` must form a rectangle.", call. = FALSE)
    }
  }
  list(matrix = ids, order = order)
}

letters_of <- function(value, arg, cells) {
  if (is.null(value)) return(character())
  if (!is.character(value) || length(value) != 1) {
    stop("`", arg, "` must be a single string of letters, e.g. \"EF\".", call. = FALSE)
  }
  out <- strsplit(gsub("\\s", "", value), "", fixed = TRUE)[[1]]
  unknown <- setdiff(out, cells[cells != "#"])
  if (length(unknown) > 0) {
    stop(
      "`", arg, "` refers to letters not in the design: ",
      paste(unknown, collapse = ", "), ".",
      call. = FALSE
    )
  }
  out
}

# Plots --------------------------------------------------------------------

apply_design_modifiers <- function(node, id, modifiers) {
  in_mod <- function(name) id %in% modifiers[[name]]
  # Panel sizes are only changed on request: spanning cells is placement only.
  for (axis in c("x", "y")) {
    if (in_mod(paste0("stretch_", axis))) {
      node <- place_in_space(list(node), axis, "stretch")
    }
    if (in_mod(paste0("center_", axis))) {
      node <- place_in_space(list(node), axis, "center")
    }
  }
  node
}

# Building the tree ----------------------------------------------------------
#
# The design is split along full rows (or columns) that no plot crosses, and
# each part is built recursively. A block without spanning plots is built
# according to `arrange_by`:
#   "row":    one row() per design line, stacked in a column()
#   "column": one column() per design column, side by side in a row()
#   "grid":   one grid() with shared rows and columns
# When cutting across the lines of the chosen mode (e.g. cutting columns in
# "row" mode), neighbouring span-free bands are merged first, so the lines
# are rebuilt as a whole.

build_design <- function(ids, plots, arrange_by = "row") {
  ids <- ids[, , drop = FALSE]
  unique_ids <- unique(as.vector(ids))
  if (length(unique_ids) == 1) return(design_leaf(unique_ids, plots))
  if (span_free(ids)) return(design_block(ids, plots, arrange_by))

  directions <- if (arrange_by == "column") c("cols", "rows") else c("rows", "cols")
  for (direction in directions) {
    bands <- design_bands(ids, direction)
    if (length(bands) > 1) {
      along_lines <- (arrange_by == "row" && direction == "rows") ||
        (arrange_by == "column" && direction == "cols")
      if (!along_lines) bands <- merge_span_free(bands, direction)
      nodes <- lapply(bands, build_design, plots = plots, arrange_by = arrange_by)
      type <- if (direction == "rows") "column" else "row"
      return(new_container(type, nodes, "left", "bottom"))
    }
  }
  stop(
    "This design can't be split into rows and columns. ",
    "Arrange such plots with `new_row()`/`new_column()` instead.",
    call. = FALSE
  )
}

# A block without spanning plots.
design_block <- function(ids, plots, arrange_by) {
  leaf_or <- function(cells, type) {
    nodes <- lapply(cells, design_leaf, plots = plots)
    if (length(nodes) == 1) return(nodes[[1]])
    new_container(type, nodes, "left", "bottom")
  }
  if (nrow(ids) == 1) return(leaf_or(as.vector(ids), "row"))
  if (ncol(ids) == 1) return(leaf_or(as.vector(ids), "column"))
  if (arrange_by == "row") {
    lines <- lapply(seq_len(nrow(ids)), function(r) leaf_or(ids[r, ], "row"))
    return(new_container("column", lines, "left", "bottom"))
  }
  if (arrange_by == "column") {
    lines <- lapply(seq_len(ncol(ids)), function(c) leaf_or(ids[, c], "column"))
    return(new_container("row", lines, "left", "bottom"))
  }
  nodes <- lapply(as.vector(t(ids)), design_leaf, plots = plots)
  new_container("grid", nodes, "left", "bottom",
                ncol = ncol(ids), nrow = nrow(ids))
}

design_leaf <- function(id, plots) {
  if (startsWith(id, "#")) return(new_node("spacer", width = NA, height = NA))
  plots[[id]]
}

# No plot covers more than one cell.
span_free <- function(ids) {
  !anyDuplicated(as.vector(ids))
}

# Split into bands along every full row/column boundary that no plot crosses.
design_bands <- function(ids, direction) {
  n <- if (direction == "rows") nrow(ids) else ncol(ids)
  slice <- function(i) if (direction == "rows") ids[i, , drop = FALSE] else ids[, i, drop = FALSE]
  cuts <- vapply(seq_len(n - 1), function(k) {
    length(intersect(as.vector(slice(seq_len(k))), as.vector(slice(seq(k + 1, n))))) == 0
  }, logical(1))
  starts <- c(1, which(cuts) + 1)
  ends <- c(which(cuts), n)
  Map(function(s, e) slice(s:e), starts, ends)
}

# Merge consecutive bands without spanning plots into one block.
merge_span_free <- function(bands, direction) {
  bind <- if (direction == "rows") rbind else cbind
  out <- list()
  current <- NULL
  for (band in bands) {
    if (span_free(band) && !is.null(current) && span_free(current)) {
      current <- bind(current, band)
    } else {
      if (!is.null(current)) out <- c(out, list(current))
      current <- band
    }
  }
  c(out, list(current))
}
