# Placeholders

`dummy()` creates a placeholder plot, useful for sketching layouts.
`spacer()` creates an empty slot; with `NA` sizes it absorbs leftover
space, with a size in mm it is a fixed gap.

## Usage

``` r
dummy(width = 30, height = 30, name = "dummy", color = "darkgrey")

spacer(width = NA, height = NA)
```

## Arguments

- width, height:

  Panel size in mm. `NA` lets the layout decide (like
  [`auto_width()`](https://jbengler.github.io/tidylayouts/reference/auto_width.md)).

- name:

  Label shown in the panel.

- color:

  Color of the panel border and label.

## Value

`dummy()` returns a ggplot, `spacer()` a layout element.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")

new_row(p1, spacer(width = 20), p2)

new_row(p1, spacer(), p2) |> layout_size(width = 120)

```
