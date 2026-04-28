library(dplyr)
library(ggplot2)
library(plotly)
library(tidyr)
library(stringr)

# --- Load data ---
connor_df <- read.csv("data/input/modified/Vacancy Data.csv")
raw_df    <- read.csv("data/output/all_dev_data_(pulled_2026-04-07).csv")

# Join BORO, CD, PACT metadata from wide input file
df <- raw_df |>
  left_join(
    connor_df |> select(X, X.2, X.5, X.6),
    by = c("Dev_Name" = "X.2")
  ) |>
  rename(
    pact        = X,
    boro        = X.5,
    cd          = X.6,
    month       = Month...Year,
    move_in     = Move.In.Selected,
    nondwelling = Non.Dwelling
  ) |>
  mutate(
    pact = case_when(is.na(pact) | pact == "" ~ "N", TRUE ~ "Y"),
    boro = ifelse(Dev_Name == "All", "ALL", boro),
    cd   = ifelse(Dev_Name == "All", "ALL", cd),
    pact = ifelse(Dev_Name == "All", "ALL", pact)
  )

# Chronological month factor
month_levels <- unique(df$month)
month_levels <- month_levels[order(as.Date(paste0("01-", month_levels), format = "%d-%b-%Y"))]
df$month <- factor(df$month, levels = month_levels)

# Per-development per-month totals and percentages
mod_df <- df |>
  left_join(
    df |>
      group_by(Dev_Name, month) |>
      summarise(total = sum(Occupied, move_in, nondwelling, Vacancies), .groups = "drop"),
    by = c("Dev_Name", "month")
  ) |>
  mutate(
    pct_occupied    = Occupied    / total * 100,
    pct_move_in     = move_in     / total * 100,
    pct_nondwelling = nondwelling / total * 100,
    pct_vacancies   = Vacancies   / total * 100
  )

# Borough aggregation (exclude unmatched rows)
boro_df <- mod_df |>
  filter(!is.na(boro), boro != "") |>
  group_by(boro, month) |>
  summarise(
    units       = sum(total),
    vacancies   = sum(Vacancies),
    nondwelling = sum(nondwelling),
    pct_vac     = vacancies   / units * 100,
    pct_nd      = nondwelling / units * 100,
    .groups     = "drop"
  )

# Council district aggregation (split multi-CD developments)
cd_base <- mod_df |> filter(!is.na(cd), cd != "", cd != "ALL")

cd_mod_df <- cd_base |>
  rowwise() |>
  mutate(new_cd = str_remove(strsplit(cd, ", ")[[1]][1], "^0+")) |>
  ungroup() |>
  bind_rows(
    cd_base |>
      filter(sapply(cd, function(x) length(strsplit(x, ", ")[[1]]) >= 2)) |>
      rowwise() |>
      mutate(new_cd = str_remove(strsplit(cd, ", ")[[1]][2], "^0+")) |>
      ungroup()
  ) |>
  bind_rows(
    cd_base |>
      filter(sapply(cd, function(x) length(strsplit(x, ", ")[[1]]) >= 3)) |>
      rowwise() |>
      mutate(new_cd = strsplit(cd, ", ")[[1]][3]) |>
      ungroup()
  )

cd_df <- cd_mod_df |>
  group_by(new_cd, month) |>
  summarise(
    units       = sum(total),
    vacancies   = sum(Vacancies),
    nondwelling = sum(nondwelling),
    pct_vac     = vacancies / units * 100,
    boro        = first(boro),
    .groups     = "drop"
  ) |>
  filter(!is.na(new_cd), new_cd != "")

# Notable developments: >=3pp vacancy increase in a single month, >=100 units
diff_df <- mod_df |>
  filter(!is.na(boro), boro != "", boro != "ALL", Dev_Name != "All") |>
  group_by(Dev_Name) |>
  arrange(month, .by_group = TRUE) |>
  mutate(vac_diff = pct_vacancies - lag(pct_vacancies)) |>
  ungroup()

notable_devs <- diff_df |>
  filter(vac_diff >= 3, total >= 100) |>
  distinct(Dev_Name) |>
  pull(Dev_Name)

# Shared color palette (colorblind-friendly)
boro_colors <- c(
  "ALL"           = "#6c757d",
  "BRONX"         = "#3A0CA3",
  "BROOKLYN"      = "#4361EE",
  "MANHATTAN"     = "#F72585",
  "QUEENS"        = "#2D6A4F",
  "STATEN ISLAND" = "#F4A261"
)

# Shared plotly layout helper
plotly_theme <- function(p) {
  p |>
    layout(
      font   = list(family = "sans-serif", size = 12),
      margin = list(t = 40, b = 80, l = 60, r = 20),
      legend = list(orientation = "h", x = 0, y = -0.2,
                    bgcolor = "rgba(255,255,255,0.8)")
    ) |>
    config(displayModeBar = FALSE)
}

######
# SUMMARIZED STATS
######
# all-vacancies
all_df <- mod_df |>
  filter(Dev_Name == "All") |>
  select(month, Vacancies, move_in, nondwelling) |>
  pivot_longer(
    cols      = c(Vacancies, move_in, nondwelling),
    names_to  = "category",
    values_to = "units"
  ) |>
  mutate(
    category = recode(category,
                      Vacancies   = "Vacant",
                      move_in     = "Move-In / Selected",
                      nondwelling = "Non-Dwelling"
    ),
    category = factor(category,
                      levels = c("Vacant", "Move-In / Selected", "Non-Dwelling")
    ),
    tooltip = paste0(
      "<b>", category, "</b><br>",
      month, "<br>",
      "Units: <b>", format(units, big.mark = ","), "</b>"
    )
  )

cat_colors <- c(
  "Vacant"             = "#2F56A6",
  "Move-In / Selected" = "#F4A261",
  "Non-Dwelling"       = "#6c757d"
)

p <- ggplot(all_df, aes(
  x = month, y = units,
  color = category, group = category,
  text = tooltip
)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(name = NULL, values = cat_colors) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = NULL, y = "Units",
       title = "Vacancy Trends (Feb 2025 – Feb 2026)") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 13),
    legend.position  = "bottom"
  )

ggplotly(p, tooltip = "text") |> plotly_theme()

# boro-vacancy
p <- boro_df |>
  filter(boro != "ALL") |>
  mutate(tooltip = paste0(
    "<b>", boro, "</b><br>",
    month, "<br>",
    "Vacancy Rate: <b>", round(pct_vac, 2), "%</b><br>",
    "Vacant Units: ", format(vacancies, big.mark = ",")
  )) |>
  ggplot(aes(
    x = month, y = pct_vac,
    color = boro, group = boro,
    text = tooltip
  )) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  scale_color_manual(name = "Borough", values = boro_colors) +
  scale_y_continuous(labels = scales::percent_format(scale = 1), limits = c(0, NA)) +
  labs(x = NULL, y = "Vacancy Rate (%)",
       title = "Vacancy Rate by Borough (Feb 2025 – Feb 2026)") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 13),
    legend.position  = "bottom"
  )

ggplotly(p, tooltip = "text") |> plotly_theme()

# boro-nondwelling
nd_plot_df <- boro_df |>
  mutate(
    label   = ifelse(boro == "ALL", "All City", boro),
    tooltip = paste0(
      "<b>", ifelse(boro == "ALL", "All City", boro), "</b><br>",
      month, "<br>",
      "Non-Dwelling Rate: <b>", round(pct_nd, 2), "%</b><br>",
      "Non-Dwelling Units: ", format(nondwelling, big.mark = ",")
    )
  )

# cd-vacancy
boros_keep <- c("BRONX","BROOKLYN","MANHATTAN","QUEENS","STATEN ISLAND")

# Notable = any consecutive month-to-month change >= 3pp
cd_change <- cd_df |>
  filter(boro %in% boros_keep) |>
  group_by(new_cd) |>
  arrange(month) |>
  summarise(max_change = max(abs(diff(pct_vac)), na.rm = TRUE), .groups = "drop")

notable_cds <- cd_change |> filter(max_change >= 3) |> pull(new_cd)

cd_plot_df <- cd_df |>
  filter(boro %in% boros_keep) |>
  left_join(cd_change, by = "new_cd") |>
  mutate(notable = new_cd %in% notable_cds)

cd_list <- cd_plot_df |>
  distinct(new_cd, boro, notable, max_change) |>
  arrange(boro, new_cd)

# Precompute per-trace color vectors for both button states
boro_col_per_trace <- unname(boro_colors[cd_list$boro])

all_colors     <- as.list(boro_col_per_trace)
all_opacities  <- as.list(rep(1, nrow(cd_list)))

dim_colors     <- as.list(ifelse(cd_list$notable, boro_col_per_trace, "#cccccc"))
dim_opacities  <- as.list(ifelse(cd_list$notable, 1, 0.1))

fig <- plot_ly()

for (i in seq_len(nrow(cd_list))) {
  cd_i  <- cd_list$new_cd[i]
  col_i <- boro_col_per_trace[i]
  df_i  <- cd_plot_df |> filter(new_cd == cd_i) |> arrange(month)
  
  fig <- add_trace(fig,
                   data       = df_i,
                   x          = ~month,
                   y          = ~pct_vac,
                   type       = "scatter",
                   mode       = "lines+markers",
                   name       = paste0("CD ", cd_i),
                   line       = list(color = col_i, width = 1.2),
                   marker     = list(color = col_i, size  = 4),
                   opacity    = 1,
                   showlegend = FALSE,
                   text       = ~paste0(
                     "<b>CD ", new_cd, "</b> (", boro, ")<br>",
                     month, "<br>",
                     "Vacancy Rate: <b>", round(pct_vac, 2), "%</b><br>",
                     "Vacant Units: ", format(vacancies, big.mark = ","), "<br>",
                     "Max monthly change: ", round(max_change, 1), "pp"
                   ),
                   hoverinfo = "text"
  )
}

fig |>
  layout(
    title = list(
      text = "<b>Vacancy Rate by Council District (Feb 2025 – Feb 2026)</b>",
      font = list(size = 13, family = "sans-serif"),
      x    = 0
    ),
    xaxis = list(
      title         = "",
      tickangle     = -45,
      categoryorder = "array",
      categoryarray = levels(cd_plot_df$month)
    ),
    yaxis  = list(title = "Vacancy Rate (%)", ticksuffix = "%"),
    font   = list(family = "sans-serif", size = 12),
    margin = list(t = 50, b = 120, l = 60, r = 20),
    updatemenus = list(list(
      type        = "buttons",
      direction   = "left",
      x           = 0, xanchor = "left",
      y           = -0.22, yanchor = "top",
      bgcolor     = "#f8f9fa",
      bordercolor = "#dee2e6",
      font        = list(size = 12),
      buttons     = list(
        list(
          method = "restyle",
          args   = list(list(
            opacity        = all_opacities,
            "line.color"   = all_colors,
            "marker.color" = all_colors
          )),
          label  = "All CDs"
        ),
        list(
          method = "restyle",
          args   = list(list(
            opacity        = dim_opacities,
            "line.color"   = dim_colors,
            "marker.color" = dim_colors
          )),
          label  = "Notable Only (≥3pp change)"
        )
      )
    ))
  ) |>
  config(displayModeBar = FALSE)

# notable devs
if (length(notable_devs) > 0) {
  p <- mod_df |>
    filter(Dev_Name %in% notable_devs) |>
    mutate(
      dev_label = str_to_title(Dev_Name),
      tooltip   = paste0(
        "<b>", str_to_title(Dev_Name), "</b><br>",
        month, "<br>",
        "Vacancy Rate: <b>", round(pct_vacancies, 2), "%</b><br>",
        "Vacant: ", Vacancies, " of ", format(total, big.mark = ","), " units"
      )
    ) |>
    ggplot(aes(
      x = month, y = pct_vacancies,
      group = Dev_Name, text = tooltip
    )) +
    geom_line(color = "#2F56A6", linewidth = 0.9) +
    geom_point(color = "#2F56A6", size = 2.5) +
    facet_wrap(~ dev_label, scales = "free_y") +
    scale_y_continuous(labels = scales::percent_format(scale = 1)) +
    labs(x = NULL, y = "Vacancy Rate (%)") +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x      = element_text(angle = 45, hjust = 1, size = 8),
      strip.text       = element_text(face = "bold", size = 8),
      panel.grid.minor = element_blank()
    )
  
  ggplotly(p, tooltip = "text") |>
    layout(showlegend = FALSE,
           margin     = list(t = 20, b = 80)) |>
    config(displayModeBar = FALSE)
} else {
  cat("No developments met the threshold in this data period.")
}