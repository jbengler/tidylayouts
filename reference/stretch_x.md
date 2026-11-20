# Stretch or center plots in the available space

A plot often has more space in a layout than its panel needs, e.g. a
plot below a row of plots, or next to a taller plot. These functions let
the plot take that spare space:

## Usage

``` r
stretch_x(...)

stretch_y(...)

center_x(...)

center_y(...)
```

## Arguments

- ...:

  ggplots, layouts, or lists of them.

## Value

The modified plot or layout if one object was supplied, otherwise a
list. Layout functions such as
[`row()`](https://jbengler.github.io/tidylayouts/reference/row.md)
splice such lists, so `add_right(stretch_y(p1, p2))` works.

## Details

- `stretch_x()` and `stretch_y()` stretch the panel to fill the spare
  width or height.

- `center_x()` and `center_y()` keep the panel at its size and center
  the plot in the spare space, with equal room on both sides. Its tag
  stays at the edge of the space. Only spare space within the row,
  column or grid the plot sits in is used; a centered plot never makes
  that container wider or taller.

`x` and `y` refer to the horizontal and vertical direction of the
figure. For plots with flipped coordinates, `stretch_x()` therefore
stretches the plot's y axis. If several plots in a row or column take
spare space, they share it equally.

Panel sizes themselves are set on the plot: with
[`tidyplots::adjust_size()`](https://jbengler.github.io/tidyplots/reference/adjust_size.html)
for tidyplots, or with `theme(panel.widths, panel.heights)` for plain
ggplots (a single unit sets the total size of all facet panels; use e.g.
`unit(c(30, 30), "mm")` for 30 mm per panel). These functions work for
both. Layouts are modified recursively, i.e. all plots inside them are
changed.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73")
wide <- dummy(name = "wide", color = "#E69F00", width = 50)

column(p1, p2) |>
  add_right(stretch_y(p3))


row(p1, p2) |>
  add_below(stretch_x(p3))


# keep the panel size, center the plot in the spare width
row(wide, wide) |>
  add_below(row(p1, center_x(p2))) |>
  layout_tags("A")

```
