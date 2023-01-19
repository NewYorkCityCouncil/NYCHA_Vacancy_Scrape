library(dplyr)
library(ggplot2)

connor_df <- read.csv("data/input/modified/Vacancy Data.csv")
original_df <- read.csv("data/output/all_dev_data.csv")

# Use connor's modified csv to modify our original csv
df <- original_df %>%
  left_join(connor_df %>%
              select(X,`X.2`,`X.5`,`X.6`),
            by = c("Dev_Name" = "X.2")) %>%
  rename("PACT_Project" = "X",
         "BORO" = "X.5",
         "CD" = "X.6",
         "Month-Year" = `Month...Year`,
         "Move-in Selected" = `Move.In.Selected`,
         "Non-Dwelling" = `Non.Dwelling`) %>%
  mutate(PACT_Project = case_when(
    is.na(PACT_Project) | PACT_Project == "" ~ "N",
    TRUE ~ "Y"
  ),
  `Month-Year` = factor(`Month-Year`,
                        levels = c("Nov-2021","Dec-2021","Jan-2022","Feb-2022","Mar-2022","Apr-2022","May-2022",
                                   "Jun-2022","Jul-2022","Aug-2022","Sep-2022","Oct-2022","Nov-2022","Dec-2022")))

# Remove ALL developments and place it in seperate variable
ALL_dev_stats <- df %>%
  filter(Dev_Name == "All")

df <- df %>%
  filter(Dev_Name != "All")

# Clean up unused dfs
rm(connor_df,original_df)

######
# SUMMARIZED STATS
######

