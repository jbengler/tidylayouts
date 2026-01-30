# Layout adjustments

Layout adjustments

## Usage

``` r
layout_tags(layout, ...)

layout_alignment(
  layout,
  horizontal = c("left", "right", "center", "justified"),
  vertical = c("top", "bottom", "center", "justified")
)

layout_spacing(layout, spacing = NULL)

layout_title(layout, ...)

layout_size(layout, overall_width = NULL, overall_height = NULL)
```

## Arguments

- ...:

  tidyplots to layout.

## Value

A layout of tidyplots

## Examples

``` r
study |>
  tidyplot(x = treatment, y = score) |>
  add_boxplot()
#> Error in add_boxplot(tidyplot(study, x = treatment, y = score)): could not find function "add_boxplot"
```
