test_that("auto_width and auto_height remove fixed panel sizes of plain ggplots", {
  p <- fix(ggplot2::ggplot(), width = 40, height = 20)
  expect_equal(as.numeric(p$theme$panel.widths), c(40, 40))
  expect_null(auto_width(p)$theme$panel.widths)
  expect_equal(as.numeric(auto_width(p)$theme$panel.heights), c(20, 20))
  expect_null(auto_height(p)$theme$panel.heights)
  expect_null(auto_width(auto_height(p))$theme$panel.widths)
})

test_that("auto size functions return lists for several inputs and recurse into layouts", {
  p <- dummy()
  out <- auto_height(p, p)
  expect_type(out, "list")
  expect_length(out, 2)
  l <- auto_height(tl_row(p, p))
  expect_null(l$children[[1]]$plot$theme$panel.heights)
  expect_error(auto_width(1), "numeric")
  expect_error(auto_margins(1, y = FALSE), "numeric")
})

test_that("tidyplots keep their size bookkeeping", {
  skip_if_not_installed("tidyplots")
  tp <- tidyplots::tidyplot(data.frame(x = 1, y = 1), x = x, y = y)
  out <- auto_height(tp)
  expect_true(is.na(out$tidyplot$height))
  out <- fix(tp, width = 40)
  expect_equal(out$tidyplot$width, 40)
  expect_equal(out$tidyplot$unit, "mm")
})

test_that("auto_margins flags plots and keeps their size", {
  p <- dummy(width = 30, height = 30)
  q <- auto_margins(p, y = FALSE)
  expect_true(isTRUE(q$tidylayouts$center[["x"]]))
  expect_false(isTRUE(q$tidylayouts$center[["y"]]))
  expect_equal(as.numeric(q$theme$panel.widths), c(30, 30))
  q <- auto_margins(q, x = FALSE)
  expect_true(isTRUE(q$tidylayouts$center[["y"]]))

  out <- auto_margins(p, p, y = FALSE)
  expect_type(out, "list")
  expect_length(out, 2)

  node <- tl_row(auto_margins(p, y = FALSE))$children[[1]]
  expect_true(isTRUE(node$center[["x"]]))

  l <- auto_margins(tl_row(p, p), x = FALSE)
  expect_true(all(vapply(l$children, function(x) isTRUE(x$center[["y"]]), logical(1))))
})

test_that("auto size drops automatic margins in the same direction", {
  p <- auto_margins(dummy(), y = FALSE)
  q <- auto_width(p)
  expect_null(q$theme$panel.widths)
  expect_false(isTRUE(q$tidylayouts$center[["x"]]))
})

test_that("the center flag survives later changes to the plot", {
  p <- auto_margins(dummy(), y = FALSE) + ggplot2::theme_bw()
  expect_true(isTRUE(p$tidylayouts$center[["x"]]))
  p <- fix(p, width = 40)
  expect_true(isTRUE(p$tidylayouts$center[["x"]]))
})

test_that("auto_margins centers both directions by default", {
  q <- auto_margins(dummy())
  expect_true(isTRUE(q$tidylayouts$center[["x"]]))
  expect_true(isTRUE(q$tidylayouts$center[["y"]]))
  q <- auto_margins(dummy(), dummy(), x = FALSE)
  expect_length(q, 2)
  expect_false(isTRUE(q[[2]]$tidylayouts$center[["x"]]))
  expect_true(isTRUE(q[[2]]$tidylayouts$center[["y"]]))
  expect_error(auto_margins(dummy(), x = FALSE, y = FALSE), "At least one")
  expect_error(auto_margins(dummy(), x = NA), "TRUE or FALSE")
})

test_that("set_size sets fixed panel sizes", {
  p <- set_size(ggplot2::ggplot(), width = 40)
  expect_equal(as.numeric(p$theme$panel.widths), c(40, 40))
  expect_null(p$theme$panel.heights)
  p <- set_size(auto_width(dummy()), width = 25, height = 20)
  expect_equal(as.numeric(p$theme$panel.widths), c(25, 25))
  expect_equal(as.numeric(p$theme$panel.heights), c(20, 20))
  out <- set_size(dummy(), dummy(), height = 10)
  expect_length(out, 2)
  l <- set_size(new_row(dummy(), dummy()), width = 15)
  expect_equal(as.numeric(l$children[[1]]$plot$theme$panel.widths), c(15, 15))
  expect_error(set_size(dummy(), width = NA), "auto_width")
  expect_error(set_size(dummy(), width = -1), "positive")
})

test_that("set_size keeps tidyplots' bookkeeping", {
  skip_if_not_installed("tidyplots")
  tp <- tidyplots::tidyplot(data.frame(x = 1, y = 1), x = x, y = y)
  out <- set_size(tp, width = 40)
  expect_equal(out$tidyplot$width, 40)
  expect_equal(out$tidyplot$unit, "mm")
})
