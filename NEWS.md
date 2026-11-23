# tidylayouts 0.0.0.9000

* New layout engine built on ggplot2 and grid; no longer depends on ggalign.
  Plots are aligned by their panel edges, also across nested rows and columns.
* Removed `row()`, `column()` and `grid()`; use `new_row()`, `new_column()`
  and `new_grid()`. Their `horizontal_align` and `vertical_align` (defaults
  `"left"` and `"bottom"`) place the plots of that row, column or grid;
  nested rows, columns and grids fill their space and use their own
  alignment. A grid shares row and column tracks.
* New `new_layout()` builds a layout from a design string, e.g.
  `"ABEF\nCDEF\nGGGG"`. Letters place the plots; by default each design line
  becomes a row (`arrange_by = "row"`), alternatively a column or a grid.
  Tags are numbered in reading order, and `tag_group()` works on its inputs.
  Plots keep their sizes; `auto_width`, `auto_height`, `auto_margins_x` and
  `auto_margins_y` change that for listed plots.
* New `new_row()`, `new_column()` and `new_grid()` build a layout step by
  step: each call adds a row below, a column to the right, or a grid below
  everything built so far. They replace `add_right()` and `add_below()`.
  `new_row(..., wrap = <mm>)` breaks a long row into lines, like text in a
  word processor; `new_column(..., wrap = <mm>)` breaks a tall column into
  several columns; `new_grid(..., wrap = <mm>)` picks as many grid columns as
  fit.
* New `auto_width()` and `auto_height()` let the layout decide a plot's panel
  size; `auto_margins()` keeps the panel size and centers the plot in the
  spare space next to it. `set_size()` sets a fixed panel size in mm for
  tidyplots and plain ggplots.
* New `tag_group()` lets several plots share one panel tag.
* New `save_layout()` saves a figure at its exact physical size.
* `layout_tags()` aligns tags at the top of each row; `layout_size()` sets the
  figure size in mm.
* `spacer()` without a size now absorbs leftover space.
* Plot backgrounds are drawn before all plots, so axis labels sticking out
  past a plot are no longer covered by the neighbouring plot's background.
* `layout_spacing(inner, outer)` now sets the gaps between plots in mm
  (one value, or `c(horizontal, vertical)`), replacing the plots' own margins,
  plus an optional `outer` margin around the figure.
* Removed `layout_alignment()`; use `horizontal_align` and `vertical_align`.
