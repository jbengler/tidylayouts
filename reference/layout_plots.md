# Lay out plots from a design string

`layout_plots()` describes a whole figure in one call: a design string
shows where each plot goes.

## Usage

``` r
layout_plots(
  ...,
  design,
  arrange_by = c("row", "column", "grid"),
  tags = NULL,
  stretch_x = NULL,
  stretch_y = NULL,
  center_x = NULL,
  center_y = NULL
)
```

## Arguments

- ...:

  ggplots, grobs or layouts, in the order described above. Lists are
  spliced.

- design:

  A string with one line per row of cells.

- arrange_by:

  How blocks without spanning plots are built: `"row"` (default, one row
  per design line), `"column"` (one column per design column) or
  `"grid"` (shared rows and columns).

- tags:

  Panel tags, as in
  [`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md):
  `"A"`, `"a"`, `"1"`, `"I"`, `"i"` or a character vector. `NULL`
  (default) adds no tags.

- stretch_x, stretch_y:

  Letters of plots whose panel stretches to the available width or
  height (see
  [`stretch_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)),
  e.g. `"EF"`.

- center_x, center_y:

  Letters of plots that keep their panel size and are centered in the
  available width or height (see
  [`center_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)).

## Value

A layout.

## Details

**Design.** Each line of `design` is a row of cells, each character a
cell:

- Each letter is one plot. A plot may cover several cells, which must
  form a rectangle. Uppercase and lowercase letters are different plots.

- `#` is an empty cell.

The design describes the arrangement, not the size: plots keep their own
panel sizes, also when they span several cells. To let a plot fill the
space it spans, list it in `stretch_x` or `stretch_y` (or center it with
`center_x`/`center_y`). Designs that can't be split along full rows and
columns (e.g. a pinwheel) are not supported.

**Arrangement.** The design is split along full rows and columns that no
plot crosses. Blocks of plots without spanning plots are built according
to `arrange_by`. With `"row"` (default), each line of the design becomes
a [`row()`](https://jbengler.github.io/tidylayouts/reference/row.md), so
`"AB\nCD"` is the same as `row(A, B) |> add_below(row(C, D))`: each line
is laid out on its own. With `"column"`, each design column becomes a
[`column()`](https://jbengler.github.io/tidylayouts/reference/row.md).
With `"grid"`, the block becomes a
[`grid()`](https://jbengler.github.io/tidylayouts/reference/row.md), so
plots in the same row and column of the design share their lines.

**Plot order.** Plots in `...` are assigned in alphabetical order of the
letters: `A` to `Z`, then `a` to `z`.

**Tags.** The letters only place the plots. Tags are numbered in reading
order, as with
[`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md).
To let several plots share one tag, pass them through
[`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md),
e.g. `layout_plots(tag_group(p1, p2), p3, ...)`.

The result is a normal layout, so it can be extended and adjusted with
[`add_right()`](https://jbengler.github.io/tidylayouts/reference/add_right.md),
[`layout_spacing()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
etc.

## Examples

``` r
p <- lapply(paste0("p", 1:7), function(x) dummy(name = x))

layout_plots(
  p,
  design = "
    ABEF
    CDEF
    GGGG
  ",
  stretch_x = "G",
  stretch_y = "EF",
  tags = "A"
)


# the first two plots share tag A; # is an empty cell
layout_plots(
  tag_group(p[[1]], p[[2]]), p[[3]], p[[4]],
  design = "
    ABC
    D##
  ",
  tags = "A",
  center_x = "D"
)

```
