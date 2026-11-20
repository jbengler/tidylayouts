# Share one tag among several plots

`tag_group()` makes several plots share a single panel tag. The first
plot of the group (in reading order) gets the tag; the others get none
and don't use up a letter, so the next plot after the group continues
the sequence. Tags are added with
[`layout_tags()`](https://jbengler.github.io/tidylayouts/reference/layout_size.md).

## Usage

``` r
tag_group(...)
```

## Arguments

- ...:

  ggplots, grobs, layouts, or lists of them. All of them form one group.

## Value

The modified plot or layout if one object was supplied, otherwise a
list. Layout functions such as
[`row()`](https://jbengler.github.io/tidylayouts/reference/row.md)
splice such lists.

## Details

The plots of a group are usually arranged together, e.g.
`tag_group(row(p1, p2))`. Several plots can also be passed directly:
`row(tag_group(p1, p2), p3)`.

## Examples

``` r
p1 <- dummy(name = "p1", color = "#0072B2")
p2 <- dummy(name = "p2", color = "#D55E00")
p3 <- dummy(name = "p3", color = "#009E73")

# p1 and p2 share tag A, p3 gets B
tag_group(row(p1, p2)) |>
  add_below(p3) |>
  layout_tags("A")


row(tag_group(p1, p2), p3) |>
  layout_tags("A")

```
