library(tidyverse)
library(stringr)
library(dbscan)

DATE_REGEX = "\\d{4}\\/\\d{2}\\/\\d{2}"
PAGE_NUMBER_REGEX = "\\d{3}\\.xml$"

titles_original <- read_csv("titles.csv")

titles <- titles_original |> 
  mutate(date_str = unlist(str_extract(file, DATE_REGEX))) |> 
  mutate(date =  as.Date(gsub("/", "", date_str), format = "%Y%m%d")) |> 
  mutate(page_number = as.integer(gsub("\\.xml$", "", unlist(str_extract(file, PAGE_NUMBER_REGEX)))))

pages <- titles |> 
  select(file, graph_part, graph_elements_count, page_number) |> 
  distinct() 

db <-
  pages |>
  select(-file, -page_number) |>
  scale() |>
  dbscan(eps = 0.1, minPts = 100)

# db <-
#   pages |>
#   select(-file, -page_number) |>
#   scale() |> 
#   kmeans( centers = 5, nstart = 25)

pages$cluster <- as.character(db$cluster)

pages_stat <- pages |> 
  filter(page_number <= 24) |> 
  group_by(page_number) |> 
  summarise(m_gr_p = mean(graph_part), m_gr_n = mean(graph_elements_count))

# BW graph
bw_graph <- pages |> 
  ggplot(aes(x = graph_part, y = graph_elements_count)) +
  geom_point(alpha = 0.15) +
  theme_minimal(base_size = 15, base_family = "Ubuntu") + 
  xlim(0, 1.2)  +
  ylim(0, 300) +
  labs(title = "Graphical content of pages") +
theme(
  plot.title = element_text(
    size = 18, face = "bold"
  )) +
  labs(x = "Part of a page size with graphics", 
       y = "Number of graphical elements on page") 

dbscan <- 
  pages |> 
    ggplot(aes(x = graph_part, y = graph_elements_count, color = cluster)) +
    geom_point(alpha = 0.7) +
    theme_minimal(base_size = 15, base_family = "Ubuntu") + 
    xlim(0, 1.2)  +
    ylim(0, 300) +
    ggtitle("Dbscan clustering results for pages", 
            subtitle = "Eps = 0.1, minimal number of points = 100") +
    theme(
      plot.title = element_text(
        size = 18, face = "bold"
      )) +
    labs(x = "Part of a page size with graphics", 
         y = "Number of graphical elements on page") 




pages_original <- read_csv("pages.csv")

pages_count <- pages_original |> 
  mutate(date_str = unlist(str_extract(file, DATE_REGEX))) |> 
  mutate(date =  as.Date(gsub("/", "", date_str), format = "%Y%m%d")) |> 
  group_by(date) |> 
  count() |> 
  rename( n_pages = n)
  




titles_with_clusters <- 
  titles |> 
  inner_join(pages) |> 
  inner_join(pages_count) |> 
  mutate(professor = unlist(str_detect(title_str, "Prof")))


overall_dynamic <- 
  titles_with_clusters|> 
  #filter(unlist(str_detect(title_str, "Prof"))) |> 
  #filter(page_number <= 3) |> 
  #filter(cluster == "3") |> 
  mutate(week = floor_date(date, "3 month")) |> 
  group_by(week) |> 
  summarise(number_of_title_mentions = n(), pages_in_period = sum(page_number)) |> 
  mutate(mention_per_page = number_of_title_mentions / pages_in_period) |> 

  ggplot(aes(x = week, y = mention_per_page)) +
  geom_line(color = "steelblue") +
  theme_minimal() +
  ggtitle("Titles mentions over the years: first 3 pages", 
          subtitle = "Aggregated by 3 months, avertisiment included") +
  theme(
    plot.title = element_text(
      size = 18, face = "bold"
    )) +
  labs(x = "Date", 
       y = "Mentions per page") 


first3pages <- 
  titles_with_clusters|> 
  #filter(unlist(str_detect(title_str, "Prof"))) |> 
  filter(page_number <= 3) |> 
  #filter(cluster == "3") |> 
  mutate(week = floor_date(date, "3 month")) |> 
  group_by(week) |> 
  summarise(number_of_title_mentions = n(), pages_in_period = sum(page_number)) |> 
  mutate(mention_per_page = number_of_title_mentions / pages_in_period) |> 
  
  ggplot(aes(x = week, y = mention_per_page)) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  theme_minimal() +
  ggtitle("Titles mentions over the years: first 3 pages", 
          subtitle = "Aggregated by 3 months") +
  theme(
    plot.title = element_text(
      size = 18, face = "bold"
    )) +
  labs(x = "Date", 
       y = "Mentions per page") 

clusters_by_years <- 
  titles_with_clusters|> 
  #filter(unlist(str_detect(title_str, "Prof"))) |> 
  #filter(page_number <= 3) |> 
  #filter(cluster == "3") |> 
  mutate(week = floor_date(date, "1 year")) |> 
  group_by(week, cluster) |> 
  summarise(number_of_title_mentions = n(), pages_in_period = sum(page_number)) |> 
  mutate(mention_per_page = number_of_title_mentions / pages_in_period) |> 
  
  ggplot(aes(x = week, y = mention_per_page, color = cluster)) +
  geom_line() +
  theme_minimal() +
  ggtitle("Titles mentions over the years: clustering", 
          subtitle = "Aggregated by years") +
  theme(
    plot.title = element_text(
      size = 18, face = "bold"
    ))

titles_with_clusters |> 
  group_by(title_str, cluster) |> 
  count() 

titles_with_clusters_for_graph <- 
  titles_with_clusters|> 
  #filter(unlist(str_detect(title_str, "Prof"))) |> 
  #filter(page_number <= 3) |> 
  #filter(cluster == "3") |> 
  mutate(week = floor_date(date, "3 month")) |> 
  group_by(week) |> 
  summarise(number_of_title_mentions = n(), pages_in_period = sum(page_number)) |> 
  mutate(mention_per_page = number_of_title_mentions / pages_in_period) |> 
  pivot_longer(cols = number_of_title_mentions:pages_in_period)

titles_with_clusters_for_graph |> 

  
  ggplot(aes( x = week, y = value, color = name)) +
  geom_line() +
  theme_minimal()

numbers_of_pages <- titles_with_clusters_for_graph |> 
  mutate(name = str_replace(name, "number_of_title_mentions", "Title mentions")) |> 
  mutate(name = str_replace(name, "pages_in_period", "Number of pages in period")) |>
  ggplot(aes(x = week, y = value, color = name)) +
  geom_line(linewidth = 1.2) +
  theme_minimal() +
  labs(title = "At some point, number of pages skyrocketed", 
       subtitle = "Aggregated by 3 months", 
       color = "")  + 
  theme(
         plot.title = element_text(
           size = 18, face = "bold"
         ))
