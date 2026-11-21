
library(tidyplots)

tidyplots_options(
  width = 25,
  height = 25,
  my_style = function(x) x |> remove_legend()
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
  adjust_size(height = 55) |>
  remove_x_axis_title() |>
  remove_y_axis_title()
p7 <- gene_expression |>
  head(100) |>
  tidyplot(x = sample_type, y = expression, color = condition) |>
  add_violin() |>
  add_data_points_beeswarm(white_border = TRUE) |>
  adjust_x_axis_title("") |>
  add_test_asterisks(hide_info = TRUE, bracket.nudge.y = 0.3) |>
  adjust_y_axis_title("Gene expression") |>
  split_plot(by = external_gene_name, nrow = 1)

tidyplots_options()

row(p1, p2) |>
  add_below(row(p3, p4)) |>
  add_right(p5, p6) |>
  add_below(p7) |>
  layout_tags("A")

tidyplayout() |>
  add_row(p1, p2) |>
  add_row(p3, p4) |>
  add_column(p5) |>
  add_column(p6) |>
  add_row(p7)


row(p1, p2) |>
  add_below(row(p3, p4)) |>
  add_right(stretch_y(p5, p6)) |>
  add_below(stretch_x(p7)) |>
  layout_tags("A")

row(p1, p2) |>
  add_below(row(p3, p4)) |>
  add_right(stretch_y(p5, p6)) |>
  add_below(stretch_x(p7)) |>
  layout_tags("A") |>
  layout_spacing(inner = 0)

row(p1, p2) |>
  add_below(row(p3, center_x(p4))) |>
  add_right(stretch_y(p5, p6)) |>
  add_below(stretch_x(p7)) |>
  layout_tags("A") |>
  layout_spacing(inner = 0)

layout_plots(
  p1, p2, p3, p4, p5, p6, p7,
  design = "
    ABEF
    CDEF
    GGGG
  ",
  center_x = "D",
  stretch_y = "EF",
  stretch_x = "G",
  tags = "A"
) |>
  layout_spacing(inner = 0)

# Nature
# Single column: 89 mm (sometimes cited as 86 mm to 90 mm)
# Double column: 183 mm (sometimes cited as 178 mm to 180 mm)
# Column-and-a-half: 120–136 mm

