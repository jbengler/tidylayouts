# Extend a layout

`add_right()` places plots to the right of a layout, `add_below()`
places them below.

## Usage

``` r
add_right(layout, ..., horizontal_align = NULL, vertical_align = NULL)

add_below(layout, ..., horizontal_align = NULL, vertical_align = NULL)
```

## Arguments

- layout:

  A layout, ggplot or grob.

- ...:

  ggplots (including tidyplots), grobs or layouts. Lists are spliced, so
  the output of
  [`stretch_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  can be passed directly. In
  [`row()`](https://jbengler.github.io/tidylayouts/reference/row.md) and
  [`column()`](https://jbengler.github.io/tidylayouts/reference/row.md),
  `NULL` is ignored; in
  [`grid()`](https://jbengler.github.io/tidylayouts/reference/row.md),
  `NULL` leaves an empty cell.

- horizontal_align, vertical_align:

  Alignment of the resulting row or column, i.e. where it places its
  direct plots (see
  [`row()`](https://jbengler.github.io/tidylayouts/reference/row.md)).
  To align the plots inside a nested row or column, set the alignment on
  that row or column instead. `NULL` keeps the current alignment when
  appending, and uses the default (`"left"`, `"bottom"`) when wrapping.

## Value

A layout.

## Details

If the layout is already a row (for `add_right()`) or a column (for
`add_below()`), the plots are appended to it. Otherwise, including for
grids, the layout is wrapped in a new row or column together with the
new plots.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73", height = NA)
p4 <- dummy(name = "p4", color = "#E69F00", width = NA)

row(p1, p2) |>
  add_right(p3) |>
  add_below(p4)

```
