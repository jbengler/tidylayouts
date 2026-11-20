# Changelog

## tidylayouts (development version)

- New layout engine built on ggplot2 and grid; no longer depends on
  ggalign. Plots are aligned by their panel edges, also across nested
  rows and columns.
- [`row()`](https://jbengler.github.io/tidylayouts/reference/row.md),
  [`column()`](https://jbengler.github.io/tidylayouts/reference/row.md)
  and
  [`grid()`](https://jbengler.github.io/tidylayouts/reference/row.md)
  gain `horizontal_align` and `vertical_align` (defaults `"left"` and
  `"bottom"`). They place the container’s direct plots; nested rows,
  columns and grids fill their space and use their own alignment.
  [`grid()`](https://jbengler.github.io/tidylayouts/reference/row.md)
  shares row and column tracks.
- New
  [`layout_plots()`](https://jbengler.github.io/tidylayouts/reference/layout_plots.md)
  builds a layout from a design string, e.g. `"ABEF\nCDEF\nGGGG"`.
  Letters place the plots; by default each design line becomes a row
  (`arrange_by = "row"`), alternatively a column or a grid. Tags are
  numbered in reading order, and
  [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md)
  works on its inputs. Plots keep their sizes; `stretch_x`, `stretch_y`,
  `center_x` and `center_y` change that for listed plots.
- [`add_right()`](https://jbengler.github.io/tidylayouts/reference/add_right.md)
  and
  [`add_below()`](https://jbengler.github.io/tidylayouts/reference/add_right.md)
  append to a row or column of the same direction and wrap everything
  else.
- New
  [`stretch_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  and
  [`stretch_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  let a plot’s panel stretch into the spare space next to it;
  [`center_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  and
  [`center_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  keep the panel size and center the plot in that space. Panel sizes are
  set on the plot with
  [`tidyplots::adjust_size()`](https://jbengler.github.io/tidyplots/reference/adjust_size.html)
  or `theme(panel.widths, panel.heights)`.
- New
  [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md)
  lets several plots share one panel tag.
- New
  [`save_layout()`](https://jbengler.github.io/tidylayouts/reference/save_layout.md)
  saves a figure at its exact physical size.
- [`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  aligns tags at the top of each row;
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
