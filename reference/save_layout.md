# Save a layout

Saves a layout at its exact physical size. If all panels have a fixed
size, the figure size is computed from the layout. If some panels are
free, set the size with `width`/`height` or
[`layout_size()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md).

## Usage

``` r
save_layout(
  layout,
  filename,
  width = NULL,
  height = NULL,
  dpi = 300,
  bg = "white",
  ...
)
```

## Arguments

- layout:

  A layout.

- filename:

  File name; the extension determines the format.

- width, height:

  Figure size in mm. Overrides
  [`layout_size()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md).

- dpi:

  Resolution for raster formats.

- bg:

  Background colour.

- ...:

  Passed on to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The figure size in mm (invisibly).

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
file <- tempfile(fileext = ".pdf")
save_layout(new_row(p1, p2), file)
```
