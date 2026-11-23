test_that("break_lines fills lines greedily", {
  bl <- tidylayouts:::break_lines
  expect_equal(bl(c(40, 40, 40), 100), list(1:2, 3L))
  expect_equal(bl(c(40, 40, 40), 120), list(1:3))
  expect_equal(bl(c(40, 40, 40), 100, gap = 25), list(1L, 2L, 3L))
  expect_equal(bl(c(30, 150, 30), 100), list(1L, 2L, 3L))  # too wide: own line
  expect_equal(bl(c(50, 50), 100), list(1:2))               # exactly fits
})

# fake leaves are 10 + 30 + 2 = 42 mm wide
test_that("a wrapping row becomes a column of rows", {
  l <- new_row(fake(), fake(), fake(), fake(), fake(), wrap = 100)
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(w$type, "column")
  expect_equal(vapply(w$children, `[[`, "", "type"), c("row", "row", "row"))
  expect_equal(lengths(lapply(w$children, `[[`, "children")), c(2, 2, 1))
  expect_null(w$wrap)
})

test_that("rows that fit are left alone", {
  l <- new_row(fake(), fake(), wrap = 100)
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(w$type, "row")
  expect_length(w$children, 2)
  l <- new_row(fake(), fake(), fake())
  expect_equal(tidylayouts:::wrap_rows(l)$type, "row")
})

test_that("gaps count towards the line width", {
  l <- new_row(fake(), fake(), wrap = 90)
  expect_equal(tidylayouts:::wrap_rows(l, gap = 0)$type, "row")
  expect_equal(tidylayouts:::wrap_rows(l, gap = 10)$type, "column")
})

test_that("justify spreads all lines but the last", {
  l <- new_row(fake(), fake(), fake(), wrap = 100, horizontal_align = "justify")
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(vapply(w$children, function(x) x$align$x, ""), c("justify", "start"))
  expect_equal(w$align$x, "start")
  l <- new_row(fake(), fake(), fake(), wrap = 100, horizontal_align = "center")
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(vapply(w$children, function(x) x$align$x, ""), c("center", "center"))
})

test_that("too wide plots warn and get their own line", {
  l <- new_row(fake(), fake(w = 120), fake(), wrap = 100)
  expect_warning(w <- tidylayouts:::wrap_rows(l), "wider than `wrap`")
  expect_equal(lengths(lapply(w$children, `[[`, "children")), c(1, 1, 1))
})

test_that("wrapped lines stack below each other and keep reading order", {
  l <- new_row(fake(), fake(), fake(), wrap = 100)
  sol <- tidylayouts:::solve_layout(tidylayouts:::wrap_rows(l))
  pl <- sol$placement
  expect_equal(pl$leaf1$y$start, pl$leaf2$y$start)
  expect_gt(pl$leaf3$y$start, pl$leaf1$y$start)
  expect_equal(pl$leaf3$x$start, pl$leaf1$x$start)
})

test_that("a wrapping row is not extended by new_column", {
  l <- new_row(dummy(), dummy(), wrap = 50) |> new_column(dummy())
  expect_equal(l$type, "row")
  expect_length(l$children, 2)
  expect_equal(l$children[[1]]$wrap, 50)
})

test_that("wrap is validated and works with real plots", {
  expect_error(new_row(dummy(), wrap = 0), "positive")
  expect_error(new_row(dummy(), wrap = "a"), "positive")
  p <- lapply(1:5, function(i) dummy(width = 20 + 10 * i, name = paste0("p", i)))
  res <- solve_real(new_row(p, wrap = 120) |> layout_tags("A"))
  y <- vapply(res$sol$placement, function(x) x$y$start, numeric(1))
  expect_gt(length(unique(round(y, 3))), 1)
  expect_lte(res$sol$size[["x"]], 120 + 1e-6)
  file <- withr::local_tempfile(fileext = ".png")
  expect_no_error(save_layout(new_row(p, wrap = 120), file))
})

# fake leaves are 10 + 30 + 2 = 42 mm wide
test_that("a wrapping grid gets as many columns as fit", {
  g <- new_grid(fake(), fake(), fake(), fake(), fake(), wrap = 100)
  expect_equal(c(g$ncol, g$nrow), c(5L, 1L))   # provisional before measuring
  w <- tidylayouts:::wrap_rows(g)
  expect_equal(c(w$ncol, w$nrow), c(2L, 3L))
  expect_length(w$children, 6)                 # padded with an empty cell
  expect_equal(w$children[[6]]$type, "spacer")
  expect_null(w$wrap)
  w <- tidylayouts:::wrap_rows(new_grid(fake(), fake(), fake(), wrap = 200))
  expect_equal(w$ncol, 3L)
})

test_that("grid columns share their width when choosing the count", {
  # a wide plot in the first column makes that column wider for all rows
  g <- new_grid(fake(w = 60), fake(), fake(), fake(), wrap = 120)
  # ncol = 2: (10 + 60 + 2) + 42 = 114 fits; ncol = 3: 72 + 42 + 42 = 156 doesn't
  expect_equal(tidylayouts:::wrap_rows(g)$ncol, 2L)
  # gaps count too
  g <- new_grid(fake(), fake(), wrap = 90)
  expect_equal(tidylayouts:::wrap_rows(g, gap = 0)$ncol, 2L)
  expect_equal(tidylayouts:::wrap_rows(g, gap = 10)$ncol, 1L)
})

test_that("grid wrap is validated and warns when nothing fits", {
  expect_error(new_grid(dummy(), wrap = 100, ncol = 2), "not both")
  expect_error(new_grid(dummy(), wrap = 100, nrow = 2), "not both")
  expect_error(new_grid(dummy(), wrap = -5), "positive")
  expect_warning(
    w <- tidylayouts:::wrap_rows(new_grid(fake(w = 150), fake(), wrap = 100)),
    "even with one column"
  )
  expect_equal(w$ncol, 1L)
})

test_that("wrapping grids solve and render with real plots", {
  p <- lapply(1:7, function(i) dummy(width = 30, height = 20, name = paste0("p", i)))
  l <- new_row(dummy(width = 60, name = "top")) |> new_grid(p, wrap = 100)
  res <- solve_real(l)
  x <- vapply(res$leaves[-1], function(leaf) res$sol$placement[[leaf$id]]$x$start, numeric(1))
  expect_equal(length(unique(round(x[!is.na(x)], 3))), 2)   # two shared columns
  expect_lte(res$sol$size[["x"]], 100 + 1e-6)
  file <- withr::local_tempfile(fileext = ".png")
  expect_no_error(save_layout(l, file))
})

# fake leaves are 2 + 30 + 10 = 42 mm tall
test_that("a wrapping column becomes a row of columns", {
  l <- new_column(fake(), fake(), fake(), fake(), fake(), wrap = 100)
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(w$type, "row")
  expect_equal(vapply(w$children, `[[`, "", "type"), c("column", "column", "column"))
  expect_equal(lengths(lapply(w$children, `[[`, "children")), c(2, 2, 1))
  expect_null(w$wrap)
  expect_equal(tidylayouts:::wrap_rows(new_column(fake(), fake(), wrap = 100))$type, "column")
})

test_that("column wrapping uses the vertical gap and vertical alignment", {
  l <- new_column(fake(), fake(), wrap = 90)
  expect_equal(tidylayouts:::wrap_rows(l, gap = c(50, 0))$type, "column")
  expect_equal(tidylayouts:::wrap_rows(l, gap = c(0, 10))$type, "row")
  l <- new_column(fake(), fake(), fake(), wrap = 100, vertical_align = "justify")
  w <- tidylayouts:::wrap_rows(l)
  expect_equal(vapply(w$children, function(x) x$align$y, ""), c("justify", "start"))
  expect_equal(w$align$y, "start")
})

test_that("too tall plots warn and get a column of their own", {
  l <- new_column(fake(), fake(h = 120), fake(), wrap = 100)
  expect_warning(w <- tidylayouts:::wrap_rows(l), "taller than `wrap`")
  expect_equal(lengths(lapply(w$children, `[[`, "children")), c(1, 1, 1))
})

test_that("wrapped columns sit side by side, tags run down first", {
  l <- new_column(fake(), fake(), fake(), wrap = 100)
  sol <- tidylayouts:::solve_layout(tidylayouts:::wrap_rows(l))
  pl <- sol$placement
  expect_equal(pl$leaf1$x$start, pl$leaf2$x$start)
  expect_gt(pl$leaf2$y$start, pl$leaf1$y$start)
  expect_gt(pl$leaf3$x$start, pl$leaf1$x$start)
  expect_equal(pl$leaf3$y$start, pl$leaf1$y$start)
})

test_that("a wrapping column is a closed block and renders", {
  l <- new_column(dummy(), dummy(), wrap = 50) |> new_row(dummy())
  expect_equal(l$type, "column")
  expect_length(l$children, 2)
  expect_equal(l$children[[1]]$wrap, 50)
  expect_error(new_column(dummy(), wrap = 0), "positive")
  p <- lapply(1:5, function(i) dummy(height = 25, name = paste0("p", i)))
  res <- solve_real(new_column(p, wrap = 80) |> layout_tags("A"))
  expect_lte(res$sol$size[["y"]], 80 + 1e-6)
  file <- withr::local_tempfile(fileext = ".png")
  expect_no_error(save_layout(new_column(p, wrap = 80, vertical_align = "top"), file))
})

test_that("wrapped columns default to top alignment, explicit values win", {
  expect_equal(new_column(fake(), wrap = 100)$align$y, "start")
  expect_equal(new_column(fake())$align$y, "end")
  expect_equal(new_column(fake(), wrap = 100, vertical_align = "bottom")$align$y, "end")
})
