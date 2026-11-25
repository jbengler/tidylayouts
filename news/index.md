# Changelog

## tidylayouts 0.0.0.9000

- New layout engine built on ggplot2 and grid; no longer depends on
  ggalign. Plots are aligned by their panel edges, also across nested
  rows and columns.
- Removed [`row()`](https://rdrr.io/r/base/row.html), `column()` and
  [`grid()`](https://rdrr.io/r/graphics/grid.html); use
  [`new_row()`](https://jbengler.github.io/tidylayouts/reference/new_row.md),
  [`new_column()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  and
  [`new_grid()`](https://jbengler.github.io/tidylayouts/reference/new_row.md).
  Their `horizontal_align` and `vertical_align` (defaults `"left"` and
  `"bottom"`) place the plots of that row, column or grid; nested rows,
  columns and grids fill their space and use their own alignment. A grid
  shares row and column tracks.
- New
  [`new_layout()`](https://jbengler.github.io/tidylayouts/reference/new_layout.md)
  builds a layout from a design string, e.g. `"ABEF\nCDEF\nGGGG"`.
  Letters place the plots; by default each design line becomes a row
  (`arrange_by = "row"`), alternatively a column or a grid. Tags are
  numbered in reading order, and
  [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md)
  works on its inputs. Plots keep their sizes; `auto_width`,
  `auto_height`, `auto_margins_x` and `auto_margins_y` change that for
  listed plots.
- New
  [`new_row()`](https://jbengler.github.io/tidylayouts/reference/new_row.md),
  [`new_column()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  and
  [`new_grid()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  build a layout step by step: each call adds a row below, a column to
  the right, or a grid below everything built so far. They replace
  `add_right()` and `add_below()`. `new_row(..., wrap = <mm>)` breaks a
  long row into lines, like text in a word processor;
  `new_column(..., wrap = <mm>)` breaks a tall column into several
  columns; `new_grid(..., wrap = <mm>)` picks as many grid columns as
  fit.
- New
  [`auto_width()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  and
  [`auto_height()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  let the layout decide a plot’s panel size;
  [`auto_margins()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  keeps the panel size and centers the plot in the spare space next to
  it.
  [`set_size()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  sets a fixed panel size in mm for tidyplots and plain ggplots.
- New
  [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md)
  lets several plots share one panel tag.
- New
  [`save_layout()`](https://jbengler.github.io/tidylayouts/reference/save_layout.md)
  saves a figure at its exact physical size.
- [`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  aligns tags at the top of each row and at the left edge of each
  column;
  [`layout_size()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  sets the figure size in mm.
- [`spacer()`](https://jbengler.github.io/tidylayouts/reference/dummy.md)
  without a size now absorbs leftover space.
- Plot backgrounds are drawn before all plots, so axis labels sticking
  out past a plot are no longer covered by the neighbouring plot’s
  background.
- `layout_spacing(inner, outer)` now sets the gaps between plots in mm
  (one value, or `c(horizontal, vertical)`), replacing the plots’ own
  margins, plus an optional `outer` margin around the figure.
- Removed `layout_alignment()`; use `horizontal_align` and
  `vertical_align`.
