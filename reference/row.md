# Arrange plots in rows, columns and grids

`row()` places plots side by side, `column()` stacks them, and `grid()`
arranges them in a table with shared row and column tracks.

## Usage

``` r
row(..., horizontal_align = "left", vertical_align = "bottom")

column(..., horizontal_align = "left", vertical_align = "bottom")

grid(
  ...,
  ncol = NULL,
  nrow = NULL,
  horizontal_align = "left",
  vertical_align = "bottom"
)
```

## Arguments

- ...:

  ggplots (including tidyplots), grobs or layouts. Lists are spliced, so
  the output of
  [`stretch_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  can be passed directly. In `row()` and `column()`, `NULL` is ignored;
  in `grid()`, `NULL` leaves an empty cell.

- horizontal_align:

  Where leftover horizontal space in this container goes: `"left"`
  (default), `"right"`, `"center"` or `"justify"` (between its plots).

- vertical_align:

  Where leftover vertical space in this container goes: `"bottom"`
  (default), `"top"`, `"center"` or `"justify"` (between its plots).

- ncol, nrow:

  Number of grid columns and rows. Cells are filled row-wise.

## Value

A layout.

## Details

Plots are aligned by their panel edges, not by their outer boxes. Within
a row, panel bottoms line up by default (so do the x axes); within a
column, panel left edges line up (so do the y axes).

**Alignment.** When plots have a fixed size, a container often has more
space than its plots need. `horizontal_align` and `vertical_align`
decide where that space goes *inside this container*: they place its
direct plots and spread space between them. Nested rows, columns and
grids always fill the space they are given and arrange their own
contents with their own alignment. For example, in
`row(p1, p2) |> add_below(row(p3, p4, horizontal_align = "justify"))`
the lower row spans the full width of the upper row, with the extra
space between `p3` and `p4`.

`column(row(p1, p2), row(p3, p4))` is not the same as
`grid(p1, p2, p3, p4, ncol = 2)`: in the column of rows, each row is
laid out independently, so `p2` and `p4` need not line up. In the grid,
every grid column is as wide as its widest panel, so `p2` sits exactly
above `p4`.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73", width = 45)

row(p1, p2)

column(p1, p3)

column(p1, p3, horizontal_align = "center")

grid(p1, p2, p3, p1, ncol = 2)


# nested rows fill the available width and use their own alignment
row(p3, p3) |> add_below(row(p1, p2, horizontal_align = "justify"))

```
