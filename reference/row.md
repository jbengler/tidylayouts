# Create a new layout

Create a new layout

## Usage

``` r
row(...)

column(...)

grid(...)
```

## Arguments

- ...:

  tidyplots to layout.

## Value

A layout of tidyplots

## Examples

``` r
library(tidyplots)

study |>
  tidyplot(x = treatment, y = score) |>
  add_boxplot()

```
