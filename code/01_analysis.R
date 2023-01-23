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

# Remove ALL developments and place it in separate variable
#ALL_dev_stats <- df %>%
#  filter(Dev_Name == "All")
#
#df <- df %>%
#  filter(Dev_Name != "All")

df <- df %>%
  mutate(BORO = ifelse(Dev_Name == "All", "ALL",BORO),
         CD = ifelse(Dev_Name == "All", "ALL",CD),
         PACT_Project = ifelse(Dev_Name == "All", "ALL",PACT_Project))

# Clean up unused dfs
rm(connor_df,original_df)

# Create total variable per month and percentage variables
mod_df <- df %>%
  left_join(df %>%
              group_by(Dev_Name,`Month-Year`) %>%
              summarise(total_units = sum(Occupied,`Move-in Selected`,`Non-Dwelling`,Vacancies))
  ) %>%
  mutate(perc_Vacancies = Vacancies / total_units * 100)

#ALL_dev_stats <- ALL_dev_stats %>%
#  left_join(ALL_dev_stats %>%
#              group_by(`Month-Year`) %>%
#              summarise(total_units = sum(Occupied,`Move-in Selected`,`Non-Dwelling`,Vacancies))
#  ) %>%
#  mutate(perc_Vacancies = Vacancies / total_units * 100)

######
# SUMMARIZED STATS
######
# BORO
boro_df <- mod_df %>%
  group_by(BORO,`Month-Year`) %>%
  summarise(total_boro_units = sum(total_units),
            total_boro_occupied = sum(Occupied),
            total_boro_move_in = sum(`Move-in Selected`),
            total_boro_nondwelling = sum(`Non-Dwelling`),
            total_boro_vacancies = sum(Vacancies),
            total_boro_perc_occupied = total_boro_occupied/total_boro_units * 100,
            total_boro_perc_move_in = total_boro_move_in/total_boro_units * 100,
            total_boro_perc_nondwelling = total_boro_nondwelling/total_boro_units * 100,
            total_boro_perc_vacancies = total_boro_vacancies/total_boro_units * 100)

#write.csv(boro_df,"data/output/dev_stats_by_boro.csv",row.names = F)

ggplot(data = boro_df %>%
         filter(BORO != ""),
       aes(x = `Month-Year`,
           y = total_boro_perc_vacancies,
           color = BORO,
           linetype = BORO,
           group = BORO,
           size = BORO)) +
  geom_line() +
  geom_point() +
  scale_color_manual(values = c(ALL = "black",
                                BRONX = '#211183',
                                BROOKLYN = '#1d5fd6',
                                MANHATTAN = "#d6593f",
                                QUEENS = '#002e14',
                                `STATEN ISLAND` = '#9d9dff')) +
  scale_linetype_manual(values = c(2,1,1,1,1,1)) +
  scale_size_manual(values = c(1.25,0.5,0.5,0.5,0.5,0.5)) +
  ggtitle("Vacancies by BORO") +
  ylab("Average Vacancy Percentage (%)") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_bw()


# PACT Status
PACT_df <- mod_df %>%
  group_by(PACT_Project,`Month-Year`) %>%
  summarise(total_PACT_units = sum(total_units),
            total_PACT_occupied = sum(Occupied),
            total_PACT_move_in = sum(`Move-in Selected`),
            total_PACT_nondwelling = sum(`Non-Dwelling`),
            total_PACT_vacancies = sum(Vacancies),
            total_PACT_perc_occupied = total_PACT_occupied/total_PACT_units * 100,
            total_PACT_perc_move_in = total_PACT_move_in/total_PACT_units * 100,
            total_PACT_perc_nondwelling = total_PACT_nondwelling/total_PACT_units * 100,
            total_PACT_perc_vacancies = total_PACT_vacancies/total_units * 100)

#write.csv(PACT_df,"data/output/dev_stats_by_PACT.csv",row.names = F)

ggplot(data = PACT_df,
       aes(x = `Month-Year`,
           y = total_PACT_perc_vacancies,
           color = PACT_Project,
           linetype = PACT_Project,
           group = PACT_Project,
           size = PACT_Project)) +
  geom_line() +
  geom_point() +
  scale_color_manual(values = c(ALL = "black",
                                Y = '#211183',
                                N = '#1d5fd6')) +
  scale_linetype_manual(values = c(2,1,1)) +
  scale_size_manual(values = c(1.25,0.5,0.5)) +
  ggtitle("Vacancies by PACT Status") +
  ylab("Average Vacancy Percentage (%)") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_bw()

# Council District
CD_mod_df <- mod_df %>%
  rowwise() %>%
  mutate(new_CD = stringr::str_remove(strsplit(CD,", ")[[1]][1],"^0+")) %>%
  bind_rows(mod_df %>%
              slice(which(sapply(mod_df$CD,function(x) length(strsplit(x, ", ")[[1]]) >= 2))) %>%
              rowwise() %>%
              mutate(new_CD = stringr::str_remove(strsplit(CD,", ")[[1]][2],"^0+"))) %>%
  bind_rows(mod_df %>%
              slice(which(sapply(mod_df$CD,function(x) length(strsplit(x, ", ")[[1]]) >= 3))) %>%
              rowwise() %>%
              mutate(new_CD = strsplit(CD,", ")[[1]][3]))

CD_df <- CD_mod_df %>%
  group_by(new_CD,`Month-Year`) %>%
  summarise(total_CD_units = sum(total_units),
            total_CD_occupied = sum(Occupied),
            total_CD_move_in = sum(`Move-in Selected`),
            total_CD_nondwelling = sum(`Non-Dwelling`),
            total_CD_vacancies = sum(Vacancies),
            total_CD_perc_occupied = total_CD_occupied/total_CD_units * 100,
            total_CD_perc_move_in = total_CD_move_in/total_CD_units * 100,
            total_CD_perc_nondwelling = total_CD_nondwelling/total_CD_units * 100,
            total_CD_perc_vacancies = total_CD_vacancies/total_CD_units * 100,
            BORO = first(BORO)) %>%
  filter(new_CD != "")

#write.csv(CD_df,"data/output/dev_stats_by_CD.csv",row.names = F)

ggplot(data = CD_df,
       aes(x = `Month-Year`,
           y = total_CD_perc_vacancies,
           color = new_CD,
           group = new_CD)) +
  geom_line() +
  geom_point() +
  ggtitle("Vacancies by Council District") +
  ylab("Average Vacancy Percentage (%)") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_bw() +
  facet_wrap(.~BORO)
