# Panel sizes and margins in a layout

A plot often has more space in a layout than its panel needs, e.g. a
plot below a row of plots, or next to a taller plot. These functions
decide how a plot uses that space:

## Usage

``` r
auto_width(...)

auto_height(...)

auto_margins(..., x = TRUE, y = TRUE)

set_size(..., width = NULL, height = NULL)
```

## Arguments

- ...:

  ggplots, layouts, or lists of them.

- x, y:

  Center horizontally / vertically.

- width, height:

  Panel width and height in mm. `NULL` leaves a dimension unchanged.

## Value

The modified plot or layout if one object was supplied, otherwise a
list. Layout functions such as
[`new_row()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
splice such lists, so `new_column(auto_height(p1, p2))` works.

## Details

- `auto_width()` and `auto_height()` let the layout decide the panel
  size: the panel takes exactly the space the plot gets from its
  neighbours. It can become larger or smaller than before.

- `auto_margins()` keeps the panel at its size and centers the plot in
  the spare space, with equal room on both sides (like `margin: auto` in
  CSS). The tag stays at the edge of the space. Only spare space within
  the row, column or grid the plot sits in is used. Centering vertically
  (`y = TRUE`) moves the plot away from the row's shared bottom edge, so
  its x axis no longer lines up with its neighbours'.

- `set_size()` sets a fixed panel size in mm. For tidyplots it calls
  [`tidyplots::adjust_size()`](https://jbengler.github.io/tidyplots/reference/adjust_size.html);
  for plain ggplots it sets `theme(panel.widths, panel.heights)`, always
  per panel (also for facets).

If several plots in a row or column take spare space, they share it
equally. These functions work for tidyplots and plain ggplots. Layouts
are modified recursively, i.e. all plots inside them are changed.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73")
wide <- dummy(name = "wide", color = "#E69F00", width = 50)

new_column(p1, p2) |>
  new_column(auto_height(p3))


new_row(p1, p2) |>
  new_row(auto_width(p3))


# keep the panel size, center the plot in the spare width
new_row(wide, wide) |>
  new_row(p1, auto_margins(p2, y = FALSE)) |>
  layout_tags("A")


new_row(p1, set_size(p2, width = 45))

```
