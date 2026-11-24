# A non-ggplot object that renders to a gtable with absolute mm tracks:
# lead | panel | trail, on both axes.
local_box_method <- function(env = parent.frame()) {
  registerS3method(
    "as_layout_gtable", "fake_box",
    function(x, ...) {
      gt <- gtable::gtable(
        widths = grid::unit(c(x$lead, x$w, x$trail), "mm"),
        heights = grid::unit(c(x$lead, x$h, x$trail), "mm"),
        name = "fake_box"
      )
      gt <- gtable::gtable_add_grob(
        gt, grid::rectGrob(gp = grid::gpar(fill = "grey90")),
        t = 1, l = 1, b = 3, r = 3, name = "decoration"
      )
      gtable::gtable_add_grob(gt, grid::rectGrob(name = "box_panel"), t = 2, l = 2, name = "panel")
    },
    envir = asNamespace("tidylayouts")
  )
}

fake_box <- function(w = 40, h = 30, lead = 12, trail = 6) {
  structure(list(w = w, h = h, lead = lead, trail = trail), class = "fake_box")
}

test_that("objects with an as_layout_gtable() method become plot leaves", {
  local_box_method()
  node <- tidylayouts:::as_node(fake_box())
  expect_equal(node$type, "plot")
  expect_null(node$plot)
  expect_s3_class(node$object, "fake_box")
  expect_s3_class(new_row(dummy(), fake_box()), "tidylayout")
})

test_that("unsupported objects give a helpful error", {
  expect_error(new_row(dummy(), structure(list(), class = "no_method")),
               "<no_method>.*as_layout_gtable")
})

test_that("as_layout_gtable() output is checked", {
  registerS3method("as_layout_gtable", "bad_box", function(x, ...) grid::nullGrob(),
                   envir = asNamespace("tidylayouts"))
  registerS3method("as_layout_gtable", "no_panel_box",
                   function(x, ...) gtable::gtable(grid::unit(1, "mm"), grid::unit(1, "mm")),
                   envir = asNamespace("tidylayouts"))
  bad <- structure(list(), class = "bad_box")
  no_panel <- structure(list(), class = "no_panel_box")
  expect_error(solve_real(new_row(bad)), "must return a gtable")
  expect_error(solve_real(new_row(no_panel)), "no grob named \"panel\"")
})

test_that("the panel track is measured as span, the rest as decoration", {
  local_box_method()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  leaf <- tidylayouts:::measure_leaf(tidylayouts:::as_node(fake_box()))
  expect_equal(leaf$meas$x, list(lead = 12, span = 40, trail = 6, flex = FALSE))
  expect_equal(leaf$meas$y, list(lead = 12, span = 30, trail = 6, flex = FALSE))
})

test_that("objects are aligned on their panel, next to ggplots", {
  local_box_method()
  p <- fix(dummy(), width = 30, height = 25)
  res <- solve_real(new_row(p, fake_box()) |> new_row(fake_box(lead = 25)))
  ids <- names(res$leaves)
  pl <- res$sol$placement
  # in the row, panel bottoms line up
  bottom <- function(id) pl[[id]]$y$start + pl[[id]]$y$span
  expect_equal(bottom(ids[1]), bottom(ids[2]))
  expect_equal(pl[[ids[2]]]$x$span, 40)
  expect_equal(pl[[ids[2]]]$y$span, 30)
  # in the column, the box's panel lines up with the ggplot's panel (left edges)
  expect_equal(pl[[ids[3]]]$x$start, pl[[ids[1]]]$x$start)
})

test_that("objects are tagged, can share a tag and be centered", {
  local_box_method()
  res <- solve_real(new_row(dummy(), fake_box()) |> layout_tags("A"))
  expect_true(all(vapply(res$leaves, tidylayouts:::is_tagged, logical(1))))

  grouped <- tag_group(fake_box(), fake_box())
  expect_false(isTRUE(grouped[[1]]$no_tag))
  expect_true(grouped[[2]]$no_tag)

  centered <- auto_margins(fake_box(), y = FALSE)
  expect_true(centered$center$x)
  # resizing leaves such objects alone, but works on the ggplots around them
  layout <- auto_width(new_row(dummy(), fake_box()))
  expect_null(tidylayouts:::layout_leaves(layout)[[2]]$plot)
  expect_error(auto_width(fake_box()), "<fake_box>")
})

test_that("layouts with such objects draw and save", {
  local_box_method()
  layout <- new_row(dummy(), fake_box()) |>
    new_row(fake_box(), dummy()) |>
    layout_tags("A")
  path <- withr::local_tempfile(fileext = ".pdf")
  expect_no_error(save_layout(layout, path))
  expect_true(file.exists(path))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_no_error(print(layout))
  # the gtable is drawn, with the panel grob inside
  kids <- tidylayouts:::render_layout(tidylayouts:::build_gtables(layout), c(NA, NA))
  grob_names <- function(g) {
    c(g$name, unlist(lapply(c(g$children, g$grobs), grob_names)))
  }
  names <- unlist(lapply(kids, grob_names))
  expect_equal(sum(names == "box_panel"), 2)
})
