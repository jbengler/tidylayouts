
devtools::load_all()
devtools::load_all("../tidyplots/")

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
  add_heatmap() |> adjust_size(height = NA)
p6 <- gene_expression |>
  tidyplot(x = sample, y = external_gene_name, color = expression) |>
  add_heatmap(scale = "row") |>
  adjust_size(height = NA) |>
  sort_y_axis_labels(direction, -padj) |>
  adjust_legend_title("Row Z-score") |>
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

row(p1, p2) |>
  below(row(p3, p4)) |>
  beside(p5, p6) |>
  below(p7) |>
  layout_tags("A")

grid(p1, p2, p3, p4) |>
  beside(p5, p6) |>
  below(p7) |>
  layout_tags("A") +
  ggalign::layout_design(
    widths = ggplot2::unit(183, "mm")
  )

tidyplots_options()


tidyplots_options(
  width = NA,
  height = 35,
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
  add_heatmap() |> adjust_size(height = NA)
p6 <- gene_expression |>
  tidyplot(x = sample, y = external_gene_name, color = expression) |>
  add_heatmap(scale = "row") |>
  adjust_size(height = NA) |>
  sort_y_axis_labels(direction, -padj) |>
  adjust_legend_title("Row Z-score") |>
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

row(p1, p2) |>
  below(row(p3, p4)) |>
  beside(row(p5, p6)) |>
  below(p7) |>
  layout_tags("A")

row(p1, p2) |>
  below(row(p3, p4)) |>
  beside(row(p5, p6)) |>
  below(p7) |>
  layout_tags("A") +
  ggalign::layout_design(
    widths = ggplot2::unit(183, "mm")
    )

grid(p1, p2, p3, p4) |>
  beside(row(p5, p6)) |>
  below(p7) |>
  layout_tags("A") +
  ggalign::layout_design(
    widths = ggplot2::unit(183, "mm")
  )

tidyplots_options()

# Nature
# Single column: 89 mm (sometimes cited as 86 mm to 90 mm)
# Double column: 183 mm (sometimes cited as 178 mm to 180 mm)
# Column-and-a-half: 120–136 mm


library(patchwork)

((p1 | p2) / ( p3 | p4 ) | (p5 | p6)) / p7 +
  plot_layout(widths = ggplot2::unit(150, "mm"))

((p1 + p2 +  p3 + p4 ) | (p5 | p6)) / p7 +
  plot_layout(widths = ggplot2::unit(150, "mm"))

((p1 + p2 +  p3 + p4 ) | (p5 | p6)) / p7 +
  plot_layout(
    widths = ggplot2::unit(150, "mm"),
    heights = c(2,1)
    )


