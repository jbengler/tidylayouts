test_that("stretch_x and stretch_y remove fixed panel sizes of plain ggplots", {
  p <- fix(ggplot2::ggplot(), width = 40, height = 20)
  expect_equal(as.numeric(p$theme$panel.widths), c(40, 40))
  expect_null(stretch_x(p)$theme$panel.widths)
  expect_equal(as.numeric(stretch_x(p)$theme$panel.heights), c(20, 20))
  expect_null(stretch_y(p)$theme$panel.heights)
  expect_null(stretch_x(stretch_y(p))$theme$panel.widths)
})

test_that("stretch functions return lists for several inputs and recurse into layouts", {
  p <- dummy()
  out <- stretch_y(p, p)
  expect_type(out, "list")
  expect_length(out, 2)
  l <- stretch_y(row(p, p))
  expect_null(l$children[[1]]$plot$theme$panel.heights)
  expect_error(stretch_x(1), "numeric")
  expect_error(center_x(1), "numeric")
})

test_that("tidyplots keep their size bookkeeping", {
  skip_if_not_installed("tidyplots")
  tp <- tidyplots::tidyplot(data.frame(x = 1, y = 1), x = x, y = y)
  out <- stretch_y(tp)
  expect_true(is.na(out$tidyplot$height))
  out <- fix(tp, width = 40)
  expect_equal(out$tidyplot$width, 40)
  expect_equal(out$tidyplot$unit, "mm")
})

test_that("center_x and center_y flag plots and keep their size", {
  p <- dummy(width = 30, height = 30)
  q <- center_x(p)
  expect_true(isTRUE(q$tidylayouts$center[["x"]]))
  expect_false(isTRUE(q$tidylayouts$center[["y"]]))
  expect_equal(as.numeric(q$theme$panel.widths), c(30, 30))
  q <- center_y(q)
  expect_true(isTRUE(q$tidylayouts$center[["y"]]))

  out <- center_x(p, p)
  expect_type(out, "list")
  expect_length(out, 2)

  node <- row(center_x(p))$children[[1]]
  expect_true(isTRUE(node$center[["x"]]))

  l <- center_y(row(p, p))
  expect_true(all(vapply(l$children, function(x) isTRUE(x$center[["y"]]), logical(1))))
})

test_that("stretching drops centering in the same direction", {
  p <- center_x(dummy())
  q <- stretch_x(p)
  expect_null(q$theme$panel.widths)
  expect_false(isTRUE(q$tidylayouts$center[["x"]]))
})

test_that("the center flag survives later changes to the plot", {
  p <- center_x(dummy()) + ggplot2::theme_bw()
  expect_true(isTRUE(p$tidylayouts$center[["x"]]))
  p <- fix(p, width = 40)
  expect_true(isTRUE(p$tidylayouts$center[["x"]]))
})
