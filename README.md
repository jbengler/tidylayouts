
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidylayouts <img src="man/figures/logo.svg" align="right" height="139" alt="" />

<!-- badges: start -->

<!-- badges: end -->

The goal of `tidylayouts` is to streamline the creation of multi-plot
layouts for scientific papers. It allows to gradually expand and adjust
layouts using a consistent and intuitive syntax.

`tidylayouts` is built around the pipe and aims to provide seamless
support for plots with absolute dimensions, such as those created with
`tidyplots`.

## ⚠️ Disclaimer ⚠️

This package is not yet functional. It is **not intended for production
use** at this stage. If you would like to stay informed, feel free to
follow me on social media ([@jbengler](https://jbengler.de)).

<!--
&#10;## Installation
&#10;You can install the released version of tidyplots from [CRAN](https://cran.r-project.org/) with:
``` r
install.packages("tidylayouts")
```
&#10;And the development version from [GitHub](https://github.com/) with:
``` r
# install.packages("pak")
pak::pak("jbengler/tidylayouts")
```
&#10;-->

## Usage

``` r
library(tidylayouts)

row(p1, p2) |> 
  add_below(row(p3, p4)) |> 
  add_right(p5, p6) |> 
  add_below(p7)
```

<img src="man/figures/README-unnamed-chunk-3-1.png" alt="" width="100%" style="display: block; margin: auto;" />

Now lets try with some real absolutely sized plots.

``` r
tidyplots_options(
  width = 25,
  height = 25,
  my_style = function(x) { x |> remove_legend()}
  )

p1 <- study |>
  tidyplot(x = group, y = score, color = dose) |>
  add_mean_bar(alpha = 0.3) |>
  add_sem_errorbar() |>
  add_data_points() |>
  add_test_asterisks(hide_info = TRUE)
p2 <- time_course |>
  tidyplot(x = day, y = score, color = treatment, dodge_width = 0) |>
  add_mean_line() |>
  add_sem_ribbon()
p3 <- energy_week |>
  tidyplot(x = date, y = power, color = energy_source) |>
  add_areastack_relative()
p4 <- energy |>
  tidyplot(y = energy, color = energy_source) |>
  add_donut()
p5 <- climate |>
  tidyplot(x = month, y = year, color = max_temperature) |>
  add_heatmap() |> 
  adjust_size(height = 55)
p6 <- gene_expression |> 
  tidyplot(x = sample, y = external_gene_name, color = expression) |> 
  add_heatmap(scale = "row") |>
  sort_y_axis_labels(direction, -padj) |> 
  adjust_legend_title("Row Z-score") |> 
  adjust_size(height = 55) |> 
  remove_x_axis_title() |> 
  remove_y_axis_title() |> 
  remove_legend()
p7 <- gene_expression |> 
  head(100) |> 
  tidyplot(x = sample_type, y = expression, color = condition) |> 
  add_violin() |> 
  add_data_points_beeswarm(white_border = TRUE) |> 
  adjust_x_axis_title("") |> 
  remove_legend() |> 
  add_test_asterisks(hide_info = TRUE, bracket.nudge.y = 0.3) |> 
  adjust_y_axis_title("Gene expression") |> 
  split_plot(by = external_gene_name, nrow = 1)

tidyplots_options()
```

``` r
row(p1, p2) |> 
  add_below(row(p3, p4)) |> 
  add_right(p5, p6) |> 
  add_below(p7) |> 
  layout_tags("A")
```

<img src="man/figures/README-unnamed-chunk-5-1.png" alt="" width="100%" style="display: block; margin: auto;" />

Of note, there are several alignment issues 🙃

1.  `E/F` neither align with the upper edge of `A/B` nor with the lower
    edge of `C/D`
2.  `C` does not align with the left edge of `A`
3.  `G` does not align with the left edge of `A/C`
4.  The tags of `A/B` and `C/D` are not on the same height

Can we have a global alignment that is based on the plot panels? This
would allow for plots to be aligned `top left` or `bottom left`.

More extensively, one could offer:

- Horizontal alignment: `left`, `right`, `center`, `justified`
- Vertical alignment: `top`, `bottom`, `center`, `justified`

Can this maybe achieved with spacers?

- `left` : `(A, B, C, NULL)`
- `right` : `(NULL, A, B, C)`
- `center` : `(NULL, A, B, C, NULL)`
- `justified` : `(A, NULL, B, NULL, C)`

In the meantime, we can fix the layout by “freeing” plots that span
multiple rows or columns, and adding a spacer to push `C/D` to the left.

``` r
row(p1, p2) |> 
  add_below(row(p3, p4, NULL)) |> 
  add_right(p5 |> adjust_size(height = NA), 
            p6 |> adjust_size(height = NA)) |> 
  add_below(p7 |> adjust_size(width = NA)) |> 
  layout_tags("A")
```

<img src="man/figures/README-unnamed-chunk-6-1.png" alt="" width="100%" style="display: block; margin: auto;" />

## More examples

### Nested style

``` r
row(
  column(p1, p1, p1),
  column(p2, p2, p2)
)
```

<img src="man/figures/README-unnamed-chunk-8-1.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

column(
  row(p1, p1, p1),
  row(p2, p2, p2)
)
```

<img src="man/figures/README-unnamed-chunk-8-2.png" alt="" width="100%" style="display: block; margin: auto;" />

### Piped style

``` r
column(p1, p2) |> 
  add_right(p3) |> 
  add_below(p4)
```

<img src="man/figures/README-unnamed-chunk-9-1.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

column(p1, p1, p1) |> 
  add_right(column(p2, p2, p2))
```

<img src="man/figures/README-unnamed-chunk-9-2.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

row(p1, p1, p1) |> 
  add_below(row(p2, p2, p2))
```

<img src="man/figures/README-unnamed-chunk-9-3.png" alt="" width="100%" style="display: block; margin: auto;" />

### Grid system

``` r
row(p1, p1, p1) |> 
  add_below(row(p1, p2, p1))
```

<img src="man/figures/README-unnamed-chunk-11-1.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

grid(p1, p1, p1, p1, p2, p1)
```

<img src="man/figures/README-unnamed-chunk-11-2.png" alt="" width="100%" style="display: block; margin: auto;" />

### Layout adjustments

``` r
# tags
grid(p1, p1, p1, p1, p1, p1) |> layout_tags("A")
```

<img src="man/figures/README-unnamed-chunk-12-1.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

# title
grid(p1, p1, p1, p1, p1, p1) |> layout_title("My title")
```

<img src="man/figures/README-unnamed-chunk-12-2.png" alt="" width="100%" style="display: block; margin: auto;" />

### Placeholders

``` r
dummy()
```

<img src="man/figures/README-unnamed-chunk-13-1.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
dummy(name = "p1")
```

<img src="man/figures/README-unnamed-chunk-13-2.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
dummy(name = "p1", color = "purple")
```

<img src="man/figures/README-unnamed-chunk-13-3.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r

grid(p1, p1, p1, p1, p1, p1)
```

<img src="man/figures/README-unnamed-chunk-13-4.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
grid(p1, spacer(), p1, spacer(), p1, p1)
```

<img src="man/figures/README-unnamed-chunk-13-5.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
grid(p1, spacer(), p1, spacer(width = 50), p1, p1)
```

<img src="man/figures/README-unnamed-chunk-13-6.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
grid(p1, spacer(), p1, spacer(height = 50), p1, p1)
```

<img src="man/figures/README-unnamed-chunk-13-7.png" alt="" width="100%" style="display: block; margin: auto;" />

``` r
grid(p1, spacer(), p1, spacer(width = 50, height = 50), p1, p1)
```

<img src="man/figures/README-unnamed-chunk-13-8.png" alt="" width="100%" style="display: block; margin: auto;" />
