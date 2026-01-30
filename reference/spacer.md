# Placeholders

Placeholders

## Usage

``` r
spacer(width = NULL, height = NULL)

dummy(width = 30, height = 30, name = "dummy", color = "darkgrey")
```

## Arguments

- ...:

  tidyplots to layout.

## Value

A layout of tidyplots

## Examples

``` r
# dummy plots
dummy(name = "p1", color = "#0072B2")

dummy(name = "p2", color = "#D55E00")

dummy(height = NA, name = "p3", color = "#009E73")

dummy(width = NA, name = "p4", color = "#E69F00")

dummy(width = 40, height = 20, name = "p4", color = "#E69F00")

dummy(width = NA, height = NA, name = "p4", color = "#E69F00")


# empty spacers
p1 <- dummy(width = 30, height = 30, name = "p1", color = "#0072B2")
grid(p1, p1, p1, p1, p1, p1)

grid(p1, spacer(), p1, spacer(), p1, p1)

grid(p1, spacer(), p1, spacer(width = 50), p1, p1)

grid(p1, spacer(), p1, spacer(height = 50), p1, p1)

grid(p1, spacer(), p1, spacer(width = 50, height = 50), p1, p1)

```
