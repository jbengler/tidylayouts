# Package index

## Create

Create a new layout by combining rows, columns and grids, or start from
a design string.

- [`new_row()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  [`new_column()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  [`new_grid()`](https://jbengler.github.io/tidylayouts/reference/new_row.md)
  : Build a layout row by row
- [`new_layout()`](https://jbengler.github.io/tidylayouts/reference/new_layout.md)
  : Lay out plots from a design string

## Size and margins

Modify sizes a margins of individual plots.

- [`auto_width()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  [`auto_height()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  [`auto_margins()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  [`set_size()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)
  : Panel sizes and margins in a layout

## Adjust

Adjust layout properties.

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

## Extending

Place objects from other packages in a layout.

- [`as_layout_gtable()`](https://jbengler.github.io/tidylayouts/reference/as_layout_gtable.md)
  : Render an object to a gtable for a layout
