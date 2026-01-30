# Add more elements to a layout

Add more elements to a layout

## Usage

``` r
add_right(...)

add_below(...)
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
