flags <- function(l) {
  vapply(tidylayouts:::layout_leaves(l), function(x) isTRUE(x$no_tag), logical(1))
}

rendered_tags <- function(l) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  g <- tidylayouts:::layout_grob(l)
  kids <- tidylayouts:::render_layout(g$layout, c(NA, NA))
  vapply(Filter(function(k) inherits(k, "text"), kids), function(k) k$label, "")
}

test_that("tag_group keeps the tag of the first plot only", {
  p <- dummy()
  expect_equal(flags(tag_group(row(p, p, p))), c(FALSE, TRUE, TRUE))
  out <- tag_group(p, p)
  expect_type(out, "list")
  expect_false(isTRUE(out[[1]]$tidylayouts$no_tag))
  expect_true(isTRUE(out[[2]]$tidylayouts$no_tag))
  expect_equal(flags(row(tag_group(p, p), p)), c(FALSE, TRUE, FALSE))
})

test_that("spacers don't count as the first plot of a group", {
  p <- dummy()
  expect_equal(flags(tag_group(row(spacer(), p, p))), c(FALSE, FALSE, TRUE))
})

test_that("nested groups and grobs", {
  p <- dummy()
  l <- tag_group(row(p, tag_group(column(p, p))))
  expect_equal(flags(l), c(FALSE, TRUE, TRUE))
  g <- tag_group(grid::rectGrob(), p)
  expect_s3_class(g[[1]], "tidylayout")
  expect_true(isTRUE(g[[2]]$tidylayouts$no_tag))
  expect_error(tag_group(1), "numeric")
})

test_that("the flag survives later changes to the plot", {
  out <- tag_group(dummy(), dummy())
  p <- fix(out[[2]] + ggplot2::theme_bw(), width = 40)
  expect_true(isTRUE(p$tidylayouts$no_tag))
  expect_true(isTRUE(row(p)$children[[1]]$no_tag))
})

test_that("grouped plots share one tag and the sequence continues", {
  p <- dummy()
  l <- tag_group(row(p, p)) |>
    add_below(row(p, p)) |>
    layout_tags("A")
  expect_equal(rendered_tags(l), c("A", "B", "C"))
  l <- row(p, tag_group(p, p), p) |> layout_tags("a")
  expect_equal(rendered_tags(l), c("a", "b", "c"))
})

test_that("untagged plots don't reserve space for a tag", {
  p <- fix(ggplot2::ggplot(), width = 30, height = 30)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  res <- solve_real(row(tag_group(p, p)) |> layout_tags("A"))
  expect_gt(res$leaves$leaf1$tag_height, 0)
  expect_equal(res$leaves$leaf2$tag_height, 0)
})
