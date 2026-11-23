# Build a layout row by row

`new_row()` adds a row of plots below everything built so far,
`new_column()` adds a column of plots to the right of it, and
`new_grid()` adds a grid of plots below it. Together they build a figure
step by step:

## Usage

``` r
new_row(..., wrap = NULL, horizontal_align = "left", vertical_align = "bottom")

new_column(..., wrap = NULL, horizontal_align = "left", vertical_align = NULL)

new_grid(
  ...,
  ncol = NULL,
  nrow = NULL,
  wrap = NULL,
  horizontal_align = "left",
  vertical_align = "bottom"
)
```

## Arguments

- ...:

  A layout (optional, first) followed by ggplots (including tidyplots),
  grobs or layouts. Lists are spliced, so the output of
  [`auto_height()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  can be passed directly.

- wrap:

  Maximum width in mm (maximum height for `new_column()`), axis labels,
  legends and gaps included. `NULL` (default) never wraps.

  - In `new_row()`, a row that doesn't fit is broken into several lines,
    like text in a word processor: each line takes as many plots as fit
    and is laid out on its own. `horizontal_align` applies to every
    line; with `"justify"` all lines but the last are spread to the
    width of the widest line. Best for plots of different widths.

  - In `new_grid()`, the number of columns is chosen as large as
    possible while the grid fits. All rows share the same columns, so
    this is best for plots of similar widths (small multiples). Can't be
    combined with `ncol` or `nrow`.

  - In `new_column()`, a column that is too tall is broken into several
    columns side by side, like newspaper columns. `vertical_align`
    (default `"top"` here) applies within every column; with `"justify"`
    all columns but the last are spread to the height of the tallest
    one. Tags run down each column before moving to the next.

  A plot larger than `wrap` gets a line (column) of its own.

- horizontal_align:

  Where leftover horizontal space in the new row (column, grid) goes:
  `"left"` (default), `"right"`, `"center"` or `"justify"` (between its
  plots).

- vertical_align:

  Where leftover vertical space goes: `"bottom"` (default), `"top"`,
  `"center"` or `"justify"` (between its plots). For `new_column()` with
  `wrap`, the default is `"top"`.

- ncol, nrow:

  Number of grid columns and rows. Cells are filled row-wise.

## Value

A layout.

## Details

    new_row(p1, p2) |>
      new_row(p3, p4) |>
      new_column(p5) |>
      new_column(p6) |>
      new_row(p7)

**Starting and adding.** If the first argument is a layout, the new row
(column, grid) is added to it. Otherwise, a new layout is started, so
`new_row(p1, p2)` is simply a row of `p1` and `p2`. To start a new row
with an existing layout as its first element, wrap it in a list:
`new_row(list(inner), p3)`. Several plots in one call form one row
(column): `new_column(p5, p6)` is a single column with `p6` below `p5`,
whereas `new_column(p5) |> new_column(p6)` gives two columns side by
side. Layouts can also be passed as elements, e.g.
`new_column(new_grid(...))` puts a grid to the right.

**Panel alignment.** Plots are aligned by their panel edges, not by
their outer boxes. Within a row, panel bottoms line up by default (so do
the x axes); within a column, panel left edges line up (so do the y
axes).

**Rows vs. grids.** Each row is laid out on its own: in
`new_row(p1, p2) |> new_row(p3, p4)`, the rows line up at the left edge
of their outermost panels, but `p2` and `p4` need not line up. In
`new_grid(p1, p2, p3, p4, ncol = 2)`, every grid column is as wide as
its widest panel, so `p2` sits exactly above `p4`. In a grid, `NULL`
leaves an empty cell.

**Spare space.** When plots have a fixed size, a row (column, grid)
often has more space than its plots need. `horizontal_align` and
`vertical_align` decide where that space goes *inside this row*: they
place its plots and spread space between them. Nested rows, columns and
grids always fill the space they are given and arrange their own
contents with their own alignment. For example, in
`new_row(p1, p2) |> new_row(p3, p4, horizontal_align = "justify")` the
lower row spans the full width of the upper row, with the extra space
between `p3` and `p4`.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73")
p4 <- dummy(name = "p4", color = "#E69F00")
p5 <- dummy(name = "p5", color = "#56B4E9", height = NA)
p6 <- dummy(name = "p6", color = "#F5C710", height = NA)
p7 <- dummy(name = "p7", color = "#DD227D", width = NA)
wide <- dummy(name = "wide", color = "#009E73", width = 45)

new_row(p1, p2) |>
  new_row(p3, p4) |>
  new_column(p5) |>
  new_column(p6) |>
  new_row(p7)


new_grid(p1, p2, p3, p4, ncol = 2) |>
  new_column(p5) |>
  new_row(p7)


# break a long row into lines of at most 100 mm
new_row(p1, p2, p3, p4, p1, p2, wrap = 100)


# as many grid columns as fit into 100 mm
new_grid(p1, p2, p3, p4, p1, p2, wrap = 100)


# columns of at most 80 mm height
new_column(p1, p2, p3, p4, p1, wrap = 80)


# alignment inside a row or column
new_column(wide, p1, horizontal_align = "center")

new_row(wide, wide) |>
  new_row(p1, p2, horizontal_align = "justify")

```
