# Layout options

Options that apply to the whole figure.

## Usage

``` r
layout_size(layout, width = NULL, height = NULL)

layout_spacing(layout, inner = NULL, outer = NULL)

layout_tags(layout, tags = "A", fontsize = 10, fontface = "bold")

layout_title(layout, title, fontsize = 12, fontface = "bold")
```

## Arguments

- layout:

  A layout, ggplot, grob or other object with an
  [`as_layout_gtable()`](https://jbengler.github.io/tidylayouts/reference/as_layout_gtable.md)
  method.

- width, height:

  Figure size in mm. `NULL` leaves it unchanged, `NA` unsets it.

- inner:

  Gap between plots in mm. One value for both directions, or
  `c(horizontal, vertical)`. `NULL` leaves it unchanged, `NA` returns to
  the plot margins (also per direction, e.g. `c(NA, 5)`).

- outer:

  Margin around the whole figure in mm (default 0). `NULL` leaves it
  unchanged, `NA` resets it.

- tags:

  `"A"`, `"a"`, `"1"`, `"I"`, `"i"`, or a character vector of labels.

- fontsize, fontface:

  Text style.

- title:

  Title text.

## Value

A layout.

## Details

- `layout_size()` sets the figure size in mm, e.g. a journal column
  width (Nature: 89 mm single column, 183 mm double column). Free panels
  absorb the extra space; if there are none, it becomes slack placed
  according to the containers' alignment.

- `layout_spacing()` sets the gaps between neighbouring plots in mm,
  measured between their outer boxes (axis labels, legends and tags
  included). It replaces the plots' own `plot.margin`, so gaps are even
  when plots use different themes. Without it, the gaps come from the
  plot margins. `outer` adds a margin around the whole figure. Note that
  axis labels can stick out past their panel (e.g. the last tick label);
  ggplot2 normally relies on the plot margin for that space. With small
  gaps, such labels may overlap neighbouring plots, and at the figure's
  edge they can be cut off; use a small `outer` margin (1-2 mm) then.

- `layout_tags()` adds panel tags. Tags are aligned at the top of their
  row, even when plots in that row have different heights, and plots
  stacked at the left edge of a column share one tag line, even when
  their axis labels differ in width. To let several plots share one tag,
  use
  [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md).

- `layout_title()` adds a title above the figure.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00", height = 45)
p3 <- dummy(name = "p3", color = "#009E73", width = NA)

new_row(p1, p2) |>
  new_row(p3) |>
  layout_tags("A") |>
  layout_title("My figure") |>
  layout_size(width = 120)


new_row(p1, p2) |>
  new_row(p3) |>
  layout_spacing(inner = 2, outer = 5)


new_row(p1, p2) |>
  new_row(p3) |>
  layout_spacing(inner = c(2, 6))

```
