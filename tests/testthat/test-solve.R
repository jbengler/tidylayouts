x_of <- function(pl, id) pl[[id]]$x
y_of <- function(pl, id) pl[[id]]$y

test_that("rows place children side by side with decorations in between", {
  pl <- solve_fake(row(fake(), fake()))
  expect_equal(x_of(pl, "leaf1")$start, 10)
  expect_equal(x_of(pl, "leaf2")$start, 10 + 30 + 2 + 10)
})

test_that("rows align panel bottoms by default and tops on request", {
  l <- row(fake(h = 30), fake(h = 50))
  pl <- solve_fake(l)
  expect_equal(y_of(pl, "leaf1")$start + 30, y_of(pl, "leaf2")$start + 50)
  pl <- solve_fake(row(fake(h = 30), fake(h = 50), vertical_align = "top"))
  expect_equal(y_of(pl, "leaf1")$start, y_of(pl, "leaf2")$start)
  pl <- solve_fake(row(fake(h = 30), fake(h = 50), vertical_align = "center"))
  expect_equal(y_of(pl, "leaf1")$start - y_of(pl, "leaf2")$start, 10)
})

test_that("columns align panel left edges despite different decorations", {
  pl <- solve_fake(column(fake(lead_x = 5), fake(lead_x = 15)))
  expect_equal(x_of(pl, "leaf1")$start, 15)
  expect_equal(x_of(pl, "leaf2")$start, 15)
})

test_that("free panels stretch to the space given by fixed neighbours", {
  l <- row(fake(), fake()) |> add_below(fake(w = NA))
  pl <- solve_fake(l)
  expect_equal(x_of(pl, "leaf3")$start, 10)
  expect_equal(x_of(pl, "leaf3")$span, 30 + 2 + 10 + 30)

  l <- column(fake(), fake()) |> add_right(fake(h = NA))
  pl <- solve_fake(l)
  top <- y_of(pl, "leaf1")$start
  bottom <- y_of(pl, "leaf2")$start + 30
  expect_equal(y_of(pl, "leaf3")$start, top)
  expect_equal(y_of(pl, "leaf3")$start + y_of(pl, "leaf3")$span, bottom)
})

test_that("nested blocks align by their outermost panel edges", {
  # README case: A/B over C/D, E beside, G below
  l <- row(fake(), fake()) |>
    add_below(row(fake(), fake())) |>
    add_right(fake(h = NA)) |>
    add_below(fake(w = NA))
  pl <- solve_fake(l)
  expect_equal(y_of(pl, "leaf5")$start, y_of(pl, "leaf1")$start)
  expect_equal(y_of(pl, "leaf5")$start + y_of(pl, "leaf5")$span, y_of(pl, "leaf3")$start + 30)
  expect_equal(x_of(pl, "leaf6")$start, x_of(pl, "leaf1")$start)
  expect_equal(x_of(pl, "leaf6")$start + x_of(pl, "leaf6")$span,
               x_of(pl, "leaf5")$start + x_of(pl, "leaf5")$span)
})

test_that("grids share column tracks, columns of rows don't", {
  wide <- fake(lead_x = 20)
  narrow <- fake(lead_x = 5)
  pl <- solve_fake(grid(fake(), narrow, fake(), wide, ncol = 2))
  expect_equal(x_of(pl, "leaf2")$start, x_of(pl, "leaf4")$start)
  pl <- solve_fake(column(row(fake(), narrow), row(fake(), wide)))
  expect_false(x_of(pl, "leaf2")$start == x_of(pl, "leaf4")$start)
})

test_that("slack is placed by alignment when nothing is free", {
  l <- row(fake(), fake())
  natural <- 30 + 2 + 10 + 30
  pl <- solve_fake(l, size = c(10 + natural + 2 + 20, NA))
  expect_equal(x_of(pl, "leaf1")$start, 10)
  pl <- solve_fake(row(fake(), fake(), horizontal_align = "right"), size = c(10 + natural + 2 + 20, NA))
  expect_equal(x_of(pl, "leaf1")$start, 30)
  pl <- solve_fake(row(fake(), fake(), horizontal_align = "justify"), size = c(10 + natural + 2 + 20, NA))
  expect_equal(x_of(pl, "leaf2")$start, 10 + 30 + 2 + 10 + 20)
})

test_that("flexible spacers absorb slack", {
  pl <- solve_fake(row(fake(), tidylayouts:::measure_leaf(spacer()), fake()), size = c(200, NA))
  expect_equal(x_of(pl, "leaf3")$start + 30 + 2, 200)
})

test_that("tag bands: a leaf at the top of a block uses the outer band", {
  l <- column(row(fake(lead_y = 2), fake(lead_y = 2)), row(fake(), fake())) |>
    add_right(fake(h = 40, lead_y = 8))
  pl <- solve_fake(l)
  expect_equal(y_of(pl, "leaf1")$band, y_of(pl, "leaf5")$band)
  expect_gt(y_of(pl, "leaf3")$band, y_of(pl, "leaf1")$band)
})

test_that("figure size follows layout_size and available space", {
  l <- row(fake(), fake(w = NA))
  sol <- tidylayouts:::solve_layout(l, available = c(300, 100))
  expect_equal(unname(sol$size["x"]), 300)
  sol <- tidylayouts:::solve_layout(l, size = c(150, NA))
  expect_equal(unname(sol$size["x"]), 150)
})

test_that("spacing adds gaps between tracks and outer adds a margin", {
  pl <- solve_fake(row(fake(), fake()), spacing = c(5, 0))
  expect_equal(x_of(pl, "leaf2")$start, 10 + 30 + 2 + 5 + 10)
  pl <- solve_fake(column(fake(), fake()), spacing = c(0, 7))
  expect_equal(y_of(pl, "leaf2")$start, 2 + 30 + 10 + 7 + 2)

  sol <- tidylayouts:::solve_layout(row(fake(), fake()), spacing = c(5, 0), outer = 3)
  expect_equal(unname(sol$size["x"]), 3 + 10 + 30 + 2 + 5 + 10 + 30 + 2 + 3)
  expect_equal(sol$placement$leaf1$x$start, 3 + 10)
  expect_equal(sol$placement$leaf1$y$start, 3 + 2)
})

test_that("free panels still match fixed neighbours with spacing", {
  l <- row(fake(), fake()) |> add_below(fake(w = NA))
  pl <- solve_fake(l, spacing = c(5, 5))
  expect_equal(x_of(pl, "leaf3")$span, 30 + 2 + 5 + 10 + 30)
})

test_that("nested containers fill their slot and use their own alignment", {
  top <- function() row(fake(), fake(w = 50))
  # top row panel span: 30 + 2 + 10 + 50 = 92, starting at 10; bottom row: 72
  starts <- function(l) {
    pl <- solve_fake(l)
    c(p3 = pl$leaf3$x$start, p4 = pl$leaf4$x$start)
  }
  expect_equal(starts(top() |> add_below(row(fake(), fake()))), c(p3 = 10, p4 = 52))
  expect_equal(
    starts(top() |> add_below(row(fake(), fake(), horizontal_align = "right"))),
    c(p3 = 30, p4 = 72)
  )
  expect_equal(
    starts(top() |> add_below(row(fake(), fake(), horizontal_align = "justify"))),
    c(p3 = 10, p4 = 72)
  )
  expect_equal(
    starts(top() |> add_below(row(fake(), fake(), horizontal_align = "center"))),
    c(p3 = 20, p4 = 62)
  )
  # the parent's alignment no longer moves a nested container ...
  expect_equal(
    starts(top() |> add_below(row(fake(), fake()), horizontal_align = "right")),
    c(p3 = 10, p4 = 52)
  )
})

test_that("a parent's alignment still places its direct plots", {
  pl <- solve_fake(column(fake(w = 50), fake(), horizontal_align = "right"))
  expect_equal(pl$leaf2$x$start + 30, pl$leaf1$x$start + 50)
  pl <- solve_fake(column(fake(w = 50), fake(), horizontal_align = "center"))
  expect_equal(pl$leaf2$x$start, pl$leaf1$x$start + 10)
})

test_that("nested containers fill vertically too", {
  # a short column next to a tall plot: by default its panels sit at the bottom
  l <- row(column(fake(h = 20), fake(h = 20)), fake(h = 100))
  pl <- solve_fake(l)
  expect_equal(pl$leaf2$y$start + 20, pl$leaf3$y$start + 100)
  # with its own vertical_align = "top", the column starts at the top
  l <- row(column(fake(h = 20), fake(h = 20), vertical_align = "top"), fake(h = 100))
  pl <- solve_fake(l)
  expect_equal(pl$leaf1$y$start, pl$leaf3$y$start)
  # "justify" spreads the column over the full height
  l <- row(column(fake(h = 20), fake(h = 20), vertical_align = "justify"), fake(h = 100))
  pl <- solve_fake(l)
  expect_equal(pl$leaf1$y$start, pl$leaf3$y$start)
  expect_equal(pl$leaf2$y$start + 20, pl$leaf3$y$start + 100)
})

test_that("a centered plot's slot takes the spare space", {
  # top row panel span 92 (from 10 to 102), bottom row natural 72
  l <- row(fake(), fake(w = 50)) |>
    add_below(row(fake(), centered(fake())))
  pl <- solve_fake(l)
  expect_equal(pl$leaf4$x$start, 52)
  expect_equal(pl$leaf4$x$span, 30 + 20)
  # slot extent includes the track's decorations; the plot box (10 + 30 + 2)
  # is centered in it
  slot <- tidylayouts:::slot_extent(pl$leaf4$x)
  expect_equal(slot, c(42, 104))
  box_left <- slot[1] + (diff(slot) - 42) / 2
  expect_equal(box_left, 52)
})

test_that("free and centered plots share the spare space equally", {
  l <- row(fake(), fake(w = 50)) |>
    add_below(row(fake(w = NA), centered(fake())))
  pl <- solve_fake(l)
  # spare: 92 - (0 + 2 + 10 + 30) = 50, 25 each
  expect_equal(pl$leaf3$x$span, 25)
  expect_equal(pl$leaf4$x$span, 30 + 25)
})

test_that("several centered plots share the spare space", {
  l <- row(fake(), fake(w = 50)) |>
    add_below(row(centered(fake()), centered(fake())))
  pl <- solve_fake(l)
  expect_equal(pl$leaf3$x$span, 40)
  expect_equal(pl$leaf4$x$span, 40)
})

test_that("centering works vertically in the cross direction", {
  l <- row(centered(fake(h = 20), "y"), fake(h = 60))
  pl <- solve_fake(l)
  expect_equal(pl$leaf1$y$start, pl$leaf2$y$start)
  expect_equal(pl$leaf1$y$span, 60)
})

test_that("centering without spare space changes nothing", {
  pl <- solve_fake(row(fake(), centered(fake())))
  expect_equal(pl$leaf2$x$span, 30)
})

test_that("a centered plot only takes space within its own container", {
  # grid with a centered plot, next to another plot, below a much wider plot:
  # the row's spare width must not flow into the grid
  l <- row(grid(fake(), fake(), fake(), centered(fake()), ncol = 2), fake()) |>
    add_below(fake(w = 300))
  pl <- solve_fake(l)
  expect_equal(pl$leaf4$x$span, 30)
  # the plot next to the grid follows it directly
  expect_equal(pl$leaf5$x$start, pl$leaf2$x$start + 30 + 2 + 10)
})

test_that("a centered plot still gets the spare space of its own row", {
  # the nested row fills the column's width, the centered plot takes the rest
  l <- row(fake(), fake(w = 50)) |>
    add_below(row(fake(), centered(fake())))
  pl <- solve_fake(l)
  expect_equal(pl$leaf4$x$span, 50)
})
