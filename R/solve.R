# Size solver ---------------------------------------------------------------
#
# Pure numeric code, independent of ggplot2. The two axes are solved
# independently with the same algorithm. Positions are in mm; the y axis runs
# top-down.
#
# Every container is a sequence of tracks along an axis. Each track holds one
# or more children that share the track's span:
#   row    on x: one track per child   | on y: one track with all children
#   column on x: one track with all    | on y: one track per child
#   grid   on x: one track per column  | on y: one track per row
# Alignment: a container's alignment places its direct plots and spacers
# within their track and distributes its own slack between tracks. Nested
# containers always fill their track and use their own alignment.
#
# A track exposes the outer edges of its children's panels. Its decorations
# (lead/trail) are the maximum of its children's decorations.
#
# `auto` marks a centered plot (`center_x()`): its slot takes spare space
# like a free panel (shared equally), but the panel keeps its size and is
# centered in the slot. Like CSS auto margins, this only applies within the
# container the plot sits in directly: containers never pass `auto` on to
# their parent, so a centered plot doesn't make its container grow.
#
# `flex` means a node can grow (it contains free panels). `bounded` means its
# natural size is defined by fixed content: a track is bounded if any child
# is, a container if all its tracks are. A free plot below a fixed row is
# bounded by that row; a free plot beside it is not.

container_tracks <- function(node, axis) {
  n <- length(node$children)
  idx <- seq_len(n)
  main <- switch(node$type, row = "x", column = "y", grid = NA)
  if (identical(main, axis)) return(as.list(idx))
  if (!is.na(main)) return(list(idx))
  # grid: cells filled row-wise
  if (axis == "x") {
    split(idx, (idx - 1) %% node$ncol)
  } else {
    split(idx, (idx - 1) %/% node$ncol)
  }
}

# Bottom-up: natural size of every node along `axis`. `gap` is the spacing
# between neighbouring tracks (mm).
annotate_axis <- function(node, axis, gap = 0) {
  if (!is_container(node)) {
    m <- node$meas[[axis]]
    m$bounded <- !m$flex
    m$auto <- !m$flex && isTRUE(node$center[[axis]])
    node$m[[axis]] <- m
    return(node)
  }
  node$children <- lapply(node$children, annotate_axis, axis = axis, gap = gap)
  ms <- lapply(node$children, function(child) child$m[[axis]])
  tracks <- lapply(unname(container_tracks(node, axis)), function(idx) {
    list(
      idx = idx,
      lead = max(vapply(ms[idx], `[[`, numeric(1), "lead")),
      span = max(vapply(ms[idx], `[[`, numeric(1), "span")),
      trail = max(vapply(ms[idx], `[[`, numeric(1), "trail")),
      flex = any(vapply(ms[idx], `[[`, logical(1), "flex")),
      auto = any(vapply(ms[idx], `[[`, logical(1), "auto")),
      bounded = any(vapply(ms[idx], `[[`, logical(1), "bounded"))
    )
  })
  k <- length(tracks)
  outer <- sum(vapply(tracks, function(t) t$lead + t$span + t$trail, numeric(1))) +
    (k - 1) * gap
  node$tracks[[axis]] <- tracks
  node$m[[axis]] <- list(
    lead = tracks[[1]]$lead,
    span = outer - tracks[[1]]$lead - tracks[[k]]$trail,
    trail = tracks[[k]]$trail,
    flex = any(vapply(tracks, `[[`, logical(1), "flex")),
    auto = FALSE,
    bounded = all(vapply(tracks, `[[`, logical(1), "bounded"))
  )
  node
}

# Top-down: assign each node a panel-span start and size along `axis`.
# Results are written to `acc` (an environment) keyed by leaf id.
# `band` is the top of the tag band a leaf belongs to (y axis only).
# `slot` is the decoration space (lead, trail) of the track a node sits in;
# centered plots are centered within their slot including it.
place_axis <- function(node, axis, start, span, band, acc, gap = 0,
                       slot = c(0, 0)) {
  if (!is_container(node)) {
    entry <- acc[[node$id]] %||% list()
    entry[[axis]] <- list(start = start, span = span, band = band,
                          slot_lead = slot[1], slot_trail = slot[2])
    acc[[node$id]] <- entry
    return(invisible())
  }
  tracks <- node$tracks[[axis]]
  align <- node$align[[axis]]
  k <- length(tracks)
  extra <- max(span - node$m[[axis]]$span, 0)
  spans <- vapply(tracks, `[[`, numeric(1), "span")
  # Spare space goes to free and centered plots (shared equally); only if
  # there are none is it placed by this container's alignment.
  grow <- vapply(tracks, function(t) t$flex || t$auto, logical(1))
  gaps <- numeric(k + 1)  # slack before track 1, between tracks, after track k
  if (any(grow)) {
    spans[grow] <- spans[grow] + extra / sum(grow)
  } else if (align == "start") {
    gaps[k + 1] <- extra
  } else if (align == "end") {
    gaps[1] <- extra
  } else if (align == "center" || k == 1) {
    gaps[c(1, k + 1)] <- extra / 2
  } else {
    gaps[seq(2, k)] <- extra / (k - 1)
  }

  pos <- start + gaps[1]
  for (i in seq_len(k)) {
    track <- tracks[[i]]
    track_band <- pos - track$lead
    if (i == 1) track_band <- min(band, track_band)
    for (j in track$idx) {
      child <- node$children[[j]]
      cm <- child$m[[axis]]
      # Nested containers always fill the track and arrange their own
      # contents with their own alignment. This container's alignment only
      # places its direct plots and spacers.
      fill <- cm$flex || cm$auto || is_container(child)
      child_span <- if (fill) spans[i] else cm$span
      offset <- switch(align,
        end = spans[i] - child_span,
        center = (spans[i] - child_span) / 2,
        0
      )
      place_axis(child, axis, pos + offset, child_span, track_band, acc, gap,
                 c(track$lead, track$trail))
    }
    pos <- pos + spans[i] + track$trail
    if (i < k) pos <- pos + gap + gaps[i + 1] + tracks[[i + 1]]$lead
  }
  invisible()
}

assign_ids <- function(node) {
  counter <- 0
  walk <- function(node) {
    if (is_container(node)) {
      node$children <- lapply(node$children, walk)
    } else {
      counter <<- counter + 1
      node$id <- paste0("leaf", counter)
    }
    node
  }
  walk(node)
}

# Solve a measured layout.
#
# `available` is the space for the figure (mm, c(width, height)), `size` the
# requested figure size (NA = not set), `top` extra space above everything
# (title), `spacing` the gaps between tracks (x, y) and `outer` the margin
# around the figure (mm). Returns the annotated tree, the leaf placements and
# the figure size.
solve_layout <- function(node, available = c(NA, NA), size = c(NA, NA), top = 0,
                         spacing = c(0, 0), outer = 0) {
  node <- assign_ids(node)
  node <- annotate_axis(node, "x", spacing[1])
  node <- annotate_axis(node, "y", spacing[2])
  acc <- new.env(parent = emptyenv())
  fig <- c(x = NA_real_, y = NA_real_)
  for (i in 1:2) {
    axis <- c("x", "y")[i]
    m <- node$m[[axis]]
    before <- outer + if (axis == "y") top else 0
    reserved <- before + m$lead + m$trail + outer
    target <- if (!is.na(size[i])) {
      size[i] - reserved
    } else if (!m$bounded && !is.na(available[i])) {
      available[i] - reserved
    } else {
      m$span
    }
    span <- max(target, m$span)
    place_axis(node, axis, before + m$lead, span, Inf, acc, spacing[i],
               c(m$lead, m$trail))
    fig[axis] <- span + reserved
  }
  list(node = node, placement = as.list(acc), size = fig)
}
