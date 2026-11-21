p <- dummy()

test_that("new_row builds the expected tree", {
  l <- new_row(p, p)
  expect_s3_class(l, "tidylayout")
  expect_equal(l$type, "row")
  expect_length(l$children, 2)
  expect_equal(l$align, list(x = "start", y = "end"))
})

test_that("NULL is dropped in rows and kept as empty cell in grids", {
  expect_length(new_row(p, NULL, p)$children, 2)
  g <- new_grid(p, NULL, p, ncol = 2)
  expect_length(g$children, 4)
  expect_equal(vapply(g$children, `[[`, "", "type"), c("plot", "spacer", "plot", "spacer"))
  expect_equal(c(g$ncol, g$nrow), c(2L, 2L))
})

test_that("lists are spliced", {
  expect_length(new_row(list(p, list(p, p)))$children, 3)
  expect_length(new_row(auto_height(p, p))$children, 2)
})

test_that("new rows, columns and grids append or wrap", {
  l <- new_row(p, p) |> new_row(p)
  expect_equal(l$type, "column")
  expect_equal(vapply(l$children, `[[`, "", "type"), c("row", "row"))

  l <- new_row(p, p) |> new_row(p) |> new_row(p)
  expect_length(l$children, 3)

  l <- new_grid(p, p, p, p) |> new_column(p)
  expect_equal(l$type, "row")
  expect_equal(l$children[[1]]$type, "grid")
})

test_that("alignment arguments are validated", {
  expect_error(new_row(p, vertical_align = "left"), "vertical_align")
  expect_error(new_column(p, horizontal_align = "top"), "horizontal_align")
  expect_error(new_row(p, horizontal_align = "top"), "horizontal_align")
})

test_that("layout options stay with the root when wrapping", {
  l <- new_row(p, p) |> layout_tags("a") |> new_column(p)
  expect_equal(l$opts$tags$tags, "a")
  expect_null(l$children[[1]]$opts)
})

test_that("non-plot input errors", {
  expect_error(new_row(p, 1), "numeric")
})
