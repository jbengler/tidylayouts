test_that("new_row and new_column start a layout from plots", {
  p <- named_dummies(3)
  expect_equal(structure_of(new_row(p[[1]], p[[2]])), "row(p1, p2)")
  expect_equal(structure_of(new_column(p[[1]], p[[2]])), "column(p1, p2)")
  expect_equal(structure_of(new_row(p[1:3])), "row(p1, p2, p3)")
})

test_that("new rows go below, new columns to the right", {
  p <- named_dummies(7)
  l <- new_row(p[[1]], p[[2]]) |>
    new_row(p[[3]], p[[4]]) |>
    new_column(p[[5]]) |>
    new_column(p[[6]]) |>
    new_row(p[[7]])
  expect_equal(
    structure_of(l),
    "column(row(column(row(p1, p2), row(p3, p4)), column(p5), column(p6)), row(p7))"
  )
})

test_that("several plots in one call form one row or column", {
  p <- named_dummies(3)
  expect_equal(
    structure_of(new_row(p[[1]]) |> new_column(p[[2]], p[[3]])),
    "row(p1, column(p2, p3))"
  )
  expect_equal(
    structure_of(new_row(p[[1]]) |> new_column(p[[2]]) |> new_column(p[[3]])),
    "row(p1, column(p2), column(p3))"
  )
})

test_that("an existing layout can start a new row when wrapped in a list", {
  p <- named_dummies(3)
  inner <- new_column(p[[1]], p[[2]])
  expect_equal(structure_of(new_row(list(inner), p[[3]])), "row(column(p1, p2), p3)")
  expect_equal(structure_of(new_row(inner, p[[3]])), "column(p1, p2, row(p3))")
})

test_that("alignment applies to the new row and options stay with the root", {
  p <- named_dummies(3)
  l <- new_row(p[[1]], p[[2]]) |>
    layout_tags("A") |>
    new_row(p[[3]], horizontal_align = "center")
  expect_equal(l$opts$tags$tags, "A")
  expect_equal(l$children[[2]]$align$x, "center")
  expect_equal(l$children[[1]]$align$x, "start")
})

test_that("new_row places plots like the equivalent nested layout", {
  l1 <- new_row(fake(), fake(w = 50)) |>
    new_row(fake(), fake()) |>
    new_column(fake(h = NA))
  l2 <- tl_row(fake(), fake(w = 50)) |>
    below(tl_row(fake(), fake())) |>
    beside(fake(h = NA))
  pl1 <- solve_fake(l1)
  pl2 <- solve_fake(l2)
  for (id in paste0("leaf", 1:5)) {
    expect_equal(pl1[[id]]$x[c("start", "span")], pl2[[id]]$x[c("start", "span")])
    expect_equal(pl1[[id]]$y[c("start", "span")], pl2[[id]]$y[c("start", "span")])
  }
})

test_that("new_row and new_column need plots", {
  expect_error(new_row(), "at least one plot")
  expect_error(new_row(new_row(dummy())), "at least one plot to add")
  expect_error(new_column(1), "numeric")
})

test_that("new_grid starts a grid or adds one below", {
  p <- named_dummies(5)
  expect_equal(structure_of(new_grid(p[1:4], ncol = 2)), "grid[2](p1, p2, p3, p4)")
  expect_equal(
    structure_of(new_row(p[[5]]) |> new_grid(p[1:4], ncol = 2)),
    "column(row(p5), grid[2](p1, p2, p3, p4))"
  )
  g <- new_grid(p[[1]], NULL, p[[2]], ncol = 2)
  expect_equal(structure_of(g), "grid[2](p1, #, p2, #)")
  g <- new_grid(p[1:2], ncol = 2, horizontal_align = "center")
  expect_equal(g$align$x, "center")
  expect_error(new_grid(), "at least one plot")
  expect_error(new_grid(new_row(p[[1]])), "at least one plot to add")
})
