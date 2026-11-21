mtcars_plot <- function(ylab = "mpg") {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::labs(y = ylab)
}

test_that("real ggplots align by panel edges", {
  a <- fix(mtcars_plot(), width = 30, height = 30)
  b <- fix(mtcars_plot("a much\nlonger\ny label") + ggplot2::scale_y_continuous(labels = function(x) paste0(x, " units")), width = 30, height = 30)
  res <- solve_real(tl_column(a, b))
  pl <- res$sol$placement
  expect_equal(pl$leaf1$x$start, pl$leaf2$x$start)
  expect_gt(res$leaves$leaf2$meas$x$lead, res$leaves$leaf1$meas$x$lead)
})

test_that("free ggplot panels and facets get the assigned span", {
  a <- fix(mtcars_plot(), width = 30, height = 30)
  f <- mtcars_plot() + ggplot2::facet_wrap(~cyl)
  res <- solve_real(tl_row(a, a) |> below(fix(f, height = 30)))
  leaf <- res$leaves$leaf3
  expect_true(leaf$meas$x$flex)
  pl <- res$sol$placement$leaf3
  widths <- tidylayouts:::resolve_tracks(leaf$dims$x, pl$x$span)
  expect_equal(sum(widths[leaf$dims$x$from:leaf$dims$x$to]), pl$x$span)
})

test_that("layouts print and save", {
  l <- tl_row(dummy(), dummy()) |>
    below(dummy(width = NA)) |>
    layout_tags("A") |>
    layout_title("Title")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_no_error(print(l))

  file <- withr::local_tempfile(fileext = ".png")
  size <- save_layout(l, file)
  expect_true(file.exists(file))
  expect_length(size, 2)
  expect_error(save_layout(tl_row(dummy(), dummy(width = NA)), file), "free panels")
  expect_no_error(save_layout(tl_row(dummy(), dummy(width = NA)), file, width = 120))
})

test_that("tag labels", {
  expect_equal(tidylayouts:::tag_labels("a", 3), c("a", "b", "c"))
  expect_equal(tidylayouts:::tag_labels("I", 3), c("I", "II", "III"))
  expect_equal(tidylayouts:::tag_labels(c("x", "y"), 3), c("x", "y", ""))
  expect_error(tidylayouts:::tag_labels("Z", 3), "tags")
})

test_that("layout_spacing replaces plot margins", {
  a <- fix(mtcars_plot(), width = 30, height = 30)
  margin <- 5.5 * 25.4 / 72.27  # 5.5 pt in mm

  res <- solve_real(tl_row(a, a))
  without <- res$sol$placement$leaf2$x$start - res$sol$placement$leaf1$x$start

  res <- solve_real(tl_row(a, a) |> layout_spacing(inner = c(4, NA)))
  with <- res$sol$placement$leaf2$x$start - res$sol$placement$leaf1$x$start
  expect_equal(without - with, 2 * margin - 4, tolerance = 1e-6)
  # vertical margins untouched
  expect_equal(res$leaves$leaf1$dims$y$mm[1], margin, tolerance = 1e-6)
  expect_equal(res$leaves$leaf1$dims$x$mm[1], 0)
})

test_that("layout_spacing sets, keeps and unsets options", {
  l <- tl_row(dummy()) |> layout_spacing(3)
  expect_equal(l$opts$spacing, list(horizontal = 3, vertical = 3))
  l <- l |> layout_spacing(inner = c(2, 6), outer = 2)
  expect_equal(l$opts$spacing, list(horizontal = 2, vertical = 6, outer = 2))
  l <- l |> layout_spacing(outer = NA)
  expect_null(l$opts$spacing$outer)
  expect_equal(l$opts$spacing$vertical, 6)
  l <- l |> layout_spacing(inner = c(NA, 6))
  expect_null(l$opts$spacing$horizontal)
  l <- l |> layout_spacing(NA)
  expect_null(l$opts$spacing$vertical)
  expect_error(layout_spacing(l, -1), "non-negative")
  expect_error(layout_spacing(l, "a"), "non-negative")
  expect_error(layout_spacing(l, c(1, 2, 3)), "one or two")
  expect_error(layout_spacing(l, outer = c(1, 2)), "a single")
})

test_that("spacing layouts print and save", {
  l <- tl_row(dummy(), dummy()) |> layout_tags("A") |> layout_title("T") |>
    layout_spacing(inner = 2, outer = 4)
  file <- withr::local_tempfile(fileext = ".png")
  size <- save_layout(l, file)
  expect_true(file.exists(file))
})

test_that("plot gtables are built once per print and reused on redraw", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  l <- tl_row(dummy(), dummy(width = NA))
  g <- tidylayouts:::layout_grob(l)
  leaves <- tidylayouts:::layout_leaves(g$layout)
  expect_true(all(vapply(leaves, function(x) inherits(x$gtable, "gtable"), logical(1))))
  # the user's layout is not modified
  expect_null(tidylayouts:::layout_leaves(l)[[1]]$gtable)
  # the drawn copy doesn't keep the (large) ggplot objects
  expect_true(all(vapply(leaves, function(x) is.null(x$plot), logical(1))))
  # changing sizes drops a cached gtable
  cached <- tidylayouts:::build_gtables(l)
  freed <- auto_height(cached)
  expect_null(tidylayouts:::layout_leaves(freed)[[1]]$gtable)
  expect_false(is.null(tidylayouts:::layout_leaves(freed)[[1]]$plot))
  expect_no_error({grid::grid.newpage(); grid::grid.draw(g); grid::grid.draw(g)})
})

test_that("save_layout leaves the previously active device current", {
  f1 <- withr::local_tempfile(fileext = ".png")
  f2 <- withr::local_tempfile(fileext = ".png")
  out <- withr::local_tempfile(fileext = ".png")
  before <- grDevices::dev.list()
  grDevices::png(f1)
  first <- grDevices::dev.cur()
  grDevices::png(f2)
  second <- grDevices::dev.cur()
  on.exit({
    grDevices::dev.off(second)
    grDevices::dev.off(first)
  }, add = TRUE)
  grDevices::dev.set(first)

  save_layout(tl_row(dummy(), dummy()), out)
  expect_equal(grDevices::dev.cur(), first)
  expect_equal(sort(grDevices::dev.list()), sort(c(before, first, second)))

  expect_error(save_layout(tl_row(dummy(), dummy(width = NA)), out), "free panels")
  expect_equal(grDevices::dev.cur(), first)
  expect_equal(sort(grDevices::dev.list()), sort(c(before, first, second)))
})

test_that("centered plots render in the middle of their slot, tag at the edge", {
  wide <- dummy(width = 50)
  l <- tl_row(wide, wide) |>
    below(tl_row(dummy(), auto_margins(dummy(), y = FALSE))) |>
    layout_tags("A")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  g <- tidylayouts:::layout_grob(l)
  kids <- tidylayouts:::render_layout(g$layout, c(NA, NA))
  # children: first the 4 backgrounds, then per plot a gTree with viewport
  # and its tag
  vps <- Filter(function(k) inherits(k, "gTree"), kids)
  expect_length(vps, 8)
  vps <- vps[5:8]
  tags <- Filter(function(k) inherits(k, "text"), kids)
  x_of <- function(u) grid::convertX(u, "mm", valueOnly = TRUE)
  box_d <- vps[[4]]$vp
  tag_d <- tags[[4]]
  left <- x_of(box_d$x)
  width <- x_of(box_d$width)
  right_edge <- x_of(vps[[2]]$vp$x) + x_of(vps[[2]]$vp$width)
  slot_left <- x_of(tag_d$x)
  expect_lt(slot_left, left)
  expect_equal(left - slot_left, right_edge - (left + width), tolerance = 1e-6)
})

test_that("plot backgrounds are drawn before all plots", {
  a <- fix(mtcars_plot(), width = 30, height = 30)
  l <- tl_row(a, a, a)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  g <- tidylayouts:::layout_grob(l)
  kids <- tidylayouts:::render_layout(g$layout, c(NA, NA))
  inner <- lapply(kids, function(k) k$children[[1]])
  is_gtable <- vapply(inner, function(x) inherits(x, "gtable"), logical(1))
  expect_equal(is_gtable, c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE))
  has_bg <- vapply(inner[is_gtable], function(x) "background" %in% x$layout$name, logical(1))
  expect_false(any(has_bg))
  # each background sits exactly in its plot's box
  for (i in 1:3) {
    expect_equal(format(kids[[i]]$vp$x), format(kids[[i + 3]]$vp$x))
    expect_equal(format(kids[[i]]$vp$width), format(kids[[i + 3]]$vp$width))
  }
})

test_that("split_background leaves gtables without background untouched", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  gt <- ggplot2::ggplotGrob(mtcars_plot())
  gt <- gt[, ]  # copy
  keep <- gt$layout$name != "background"
  gt$grobs <- gt$grobs[keep]
  gt$layout <- gt$layout[keep, , drop = FALSE]
  out <- tidylayouts:::split_background(gt)
  expect_null(out$background)
  expect_identical(out$plot, gt)
})
