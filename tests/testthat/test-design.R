plots <- function(n) lapply(seq_len(n), function(i) dummy(name = paste0("p", i)))

structure_of <- function(node) {
  if (!tidylayouts:::is_container(node)) {
    if (node$type == "spacer") return("#")
    return(node$plot$layers[[1]]$aes_params$label)
  }
  inner <- vapply(node$children, structure_of, character(1))
  extra <- if (node$type == "grid") paste0("[", node$ncol, "]") else ""
  paste0(node$type, extra, "(", paste(inner, collapse = ", "), ")")
}

test_that("designs are built line by line by default", {
  d <- "
    ABEF
    CDEF
    GGGG
  "
  expect_equal(
    structure_of(layout_plots(plots(7), design = d)),
    "column(row(column(row(p1, p2), row(p3, p4)), p5, p6), p7)"
  )
  expect_equal(structure_of(layout_plots(plots(2), design = "AB")), "row(p1, p2)")
  expect_equal(structure_of(layout_plots(plots(2), design = "A\nB")), "column(p1, p2)")
  expect_equal(
    structure_of(layout_plots(plots(3), design = "AAB\nCCB")),
    "row(column(p1, p3), p2)"
  )
})

test_that("line-by-line designs match the pipe API", {
  p <- plots(7)
  piped <- row(p[[1]], p[[2]]) |>
    add_below(row(p[[3]], p[[4]])) |>
    add_right(p[[5]], p[[6]]) |>
    add_below(p[[7]])
  expect_equal(
    structure_of(layout_plots(p, design = "ABEF\nCDEF\nGGGG")),
    structure_of(piped)
  )
})

test_that("arrange_by = 'column' builds one column per design column", {
  d <- "ABEF\nCDEF\nGGGG"
  expect_equal(
    structure_of(layout_plots(plots(7), design = d, arrange_by = "column")),
    "column(row(column(p1, p3), column(p2, p4), p5, p6), p7)"
  )
  expect_equal(
    structure_of(layout_plots(plots(4), design = "AB\nCD", arrange_by = "column")),
    "row(column(p1, p3), column(p2, p4))"
  )
})

test_that("arrange_by = 'grid' shares rows and columns", {
  d <- "ABEF\nCDEF\nGGGG"
  expect_equal(
    structure_of(layout_plots(plots(7), design = d, arrange_by = "grid")),
    "column(row(grid[2](p1, p2, p3, p4), p5, p6), p7)"
  )
  expect_error(layout_plots(plots(2), design = "AB", arrange_by = "lines"), "should be one of")
})

test_that("plots are assigned alphabetically, uppercase before lowercase", {
  l <- layout_plots(plots(4), design = "
    bA
    Ba
  ")
  # order: A = p1, B = p2, a = p3, b = p4
  expect_equal(structure_of(l), "column(row(p4, p1), row(p2, p3))")
})

test_that("tags are numbered in reading order", {
  l <- layout_plots(plots(3), design = "CA\nBB", tags = "A")
  expect_equal(l$opts$tags$tags, "A")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  g <- tidylayouts:::layout_grob(l)
  kids <- tidylayouts:::render_layout(g$layout, c(NA, NA))
  labels <- vapply(Filter(function(k) inherits(k, "text"), kids), function(k) k$label, "")
  expect_equal(labels, c("A", "B", "C"))
  expect_null(layout_plots(plots(2), design = "AB")$opts$tags)
})

test_that("tag_group() inputs share one tag", {
  p <- plots(4)
  l <- layout_plots(tag_group(p[[1]], p[[2]]), p[[3]], p[[4]], design = "ABC\nD##")
  leaves <- Filter(function(x) x$type == "plot", tidylayouts:::layout_leaves(l))
  no_tag <- vapply(leaves, function(x) isTRUE(x$no_tag), logical(1))
  expect_equal(no_tag, c(FALSE, TRUE, FALSE, FALSE))
})

test_that("spanning keeps sizes, modifiers stretch or center", {
  l <- layout_plots(plots(7), design = "ABEF\nCDEF\nGGGG",
                    stretch_x = "A", center_x = "D", center_y = "F")
  leaves <- tidylayouts:::layout_leaves(l)
  names(leaves) <- vapply(leaves, function(x) x$plot$layers[[1]]$aes_params$label, "")
  theme_of <- function(id, el) leaves[[id]]$plot$theme[[el]]
  expect_null(theme_of("p1", "panel.widths"))                       # stretch_x = "A"
  expect_true(isTRUE(leaves$p4$center[["x"]]))                      # center_x = "D"
  expect_false(is.null(theme_of("p5", "panel.heights")))            # E spans rows, kept
  expect_false(isTRUE(leaves$p5$center[["y"]]))
  expect_false(is.null(theme_of("p6", "panel.heights")))            # F centered
  expect_true(isTRUE(leaves$p6$center[["y"]]))
  expect_false(is.null(theme_of("p7", "panel.widths")))             # G spans columns, kept
  expect_false(is.null(theme_of("p2", "panel.widths")))             # B unchanged
})

test_that("spanning plots stretch when listed", {
  l <- layout_plots(plots(7), design = "ABEF\nCDEF\nGGGG",
                    stretch_x = "G", stretch_y = "EF")
  leaves <- tidylayouts:::layout_leaves(l)
  names(leaves) <- vapply(leaves, function(x) x$plot$layers[[1]]$aes_params$label, "")
  expect_null(leaves$p5$plot$theme$panel.heights)
  expect_null(leaves$p6$plot$theme$panel.heights)
  expect_null(leaves$p7$plot$theme$panel.widths)
})

test_that("layouts can be used as plots", {
  inner <- row(dummy(name = "i1"), dummy(name = "i2"))
  l <- layout_plots(inner, dummy(name = "x"), design = "AB")
  expect_equal(structure_of(l), "row(row(i1, i2), x)")
  l <- layout_plots(tag_group(inner), dummy(name = "x"), design = "AB")
  leaves <- tidylayouts:::layout_leaves(l)
  expect_equal(vapply(leaves, function(x) isTRUE(x$no_tag), logical(1)), c(FALSE, TRUE, FALSE))
})

test_that("invalid designs give clear errors", {
  expect_error(layout_plots(plots(2), design = "AB\nA"), "same number of cells")
  expect_error(layout_plots(plots(2), design = "A-B"), "only contain letters")
  expect_error(layout_plots(plots(2), design = "AB\nBA"), "rectangle")
  expect_error(layout_plots(plots(1), design = "AB"), "2 plots")
  expect_error(layout_plots(plots(2), design = "AB", stretch_x = "Z"), "not in the design")
  expect_error(
    layout_plots(plots(2), design = "AB", stretch_x = "A", center_x = "A"),
    "both stretched and centered"
  )
  # pinwheel: no full cut in either direction
  expect_error(
    layout_plots(plots(5), design = "AAB\nDEB\nDCC"),
    "can't be split"
  )
})

test_that("design layouts render", {
  l <- layout_plots(tag_group(plots(2)), plots(2), design = "AB\nCD",
                    tags = "A", center_x = "C")
  file <- withr::local_tempfile(fileext = ".png")
  expect_no_error(save_layout(l, file))
})
