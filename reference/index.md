# Package index

## Create

To create a layout, first assign your plots to variables such as `p1`,
`p2`, and `p3`. Then, define a base layout and progressively expand and
adjust it. Plots are aligned by their panels.

- [`row()`](https://jbengler.github.io/tidylayouts/reference/row.md)
  [`column()`](https://jbengler.github.io/tidylayouts/reference/row.md)
  [`grid()`](https://jbengler.github.io/tidylayouts/reference/row.md) :
  Arrange plots in rows, columns and grids
- [`layout_plots()`](https://jbengler.github.io/tidylayouts/reference/layout_plots.md)
  : Lay out plots from a design string

## Extend

Add plots to the right of or below a layout.

- [`add_right()`](https://jbengler.github.io/tidylayouts/reference/add_right.md)
  [`add_below()`](https://jbengler.github.io/tidylayouts/reference/add_right.md)
  : Extend a layout

## Stretch and center

Panel sizes are set on the plot
([`tidyplots::adjust_size()`](https://jbengler.github.io/tidyplots/reference/adjust_size.html)
or `theme(panel.widths)`). A plot can take the spare space next to it,
either stretching its panel or staying centered.

- [`stretch_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  [`stretch_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  [`center_x()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  [`center_y()`](https://jbengler.github.io/tidylayouts/reference/stretch_x.md)
  : Stretch or center plots in the available space

## Adjust

Options for the whole figure.

- [`layout_plots()`](https://jbengler.github.io/tidylayouts/reference/layout_plots.md)
  : Lay out plots from a design string
- [`layout_size()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  [`layout_spacing()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  [`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  [`layout_title()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md)
  : Layout options
- [`tag_group()`](https://jbengler.github.io/tidylayouts/reference/tag_group.md)
  : Share one tag among several plots

## Save

- [`save_layout()`](https://jbengler.github.io/tidylayouts/reference/save_layout.md)
  : Save a layout

## Placeholders

- [`dummy()`](https://jbengler.github.io/tidylayouts/reference/dummy.md)
  [`spacer()`](https://jbengler.github.io/tidylayouts/reference/dummy.md)
  : Placeholders
