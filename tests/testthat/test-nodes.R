p <- dummy()

test_that("containers build the expected tree", {
  l <- row(p, p)
  expect_s3_class(l, "tidylayout")
  expect_equal(l$type, "row")
  expect_length(l$children, 2)
  expect_equal(l$align, list(x = "start", y = "end"))
})

test_that("NULL is dropped in rows and kept as empty cell in grids", {
  expect_length(row(p, NULL, p)$children, 2)
  g <- grid(p, NULL, p, ncol = 2)
  expect_length(g$children, 4)
  expect_equal(vapply(g$children, `[[`, "", "type"), c("plot", "spacer", "plot", "spacer"))
  expect_equal(c(g$ncol, g$nrow), c(2L, 2L))
})

test_that("lists are spliced", {
  expect_length(row(list(p, list(p, p)))$children, 3)
  expect_length(row(stretch_y(p, p))$children, 2)
})

test_that("pipe verbs append to the same direction and wrap otherwise", {
  l <- row(p, p) |> add_right(p)
  expect_equal(l$type, "row")
  expect_length(l$children, 3)

  l <- row(p, p) |> add_below(p)
  expect_equal(l$type, "column")
  expect_equal(l$children[[1]]$type, "row")

  l <- grid(p, p, p, p) |> add_right(p)
  expect_equal(l$type, "row")
  expect_equal(l$children[[1]]$type, "grid")

  expect_equal(add_right(p, p)$type, "row")
})

test_that("alignment arguments are validated and updated on append", {
  expect_error(row(p, vertical_align = "left"), "vertical_align")
  expect_error(column(p, horizontal_align = "top"), "horizontal_align")
  l <- column(p) |> add_below(p, horizontal_align = "right")
  expect_equal(l$align$x, "end")
  expect_equal(l$align$y, "end")
})

test_that("layout options stay with the root when wrapping", {
  l <- row(p, p) |> layout_tags("a") |> add_below(p)
  expect_equal(l$opts$tags$tags, "a")
  expect_null(l$children[[1]]$opts)
})

test_that("non-plot input errors", {
  expect_error(row(p, 1), "numeric")
})
