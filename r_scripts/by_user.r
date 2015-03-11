# I'd like to know:
# - how many PRs "user_x" has opened?
# - which one was the longest?
# - how many comments, commits were there on average?
# - what's the cycle time?

# load data from csv
data <- read.csv("data/rails_rails_prs.csv", header=TRUE, stringsAsFactors = FALSE)
data$created_at <- as.POSIXct(data$created_at)

require(lubridate)
data$created_at_week  <- week(data$created_at)
data$created_at_year  <- year(data$created_at)

require("dplyr")
# pick a user
contributor = 'steveklabnik'

user_data <- data %>% 
  filter(merged_in == "true", user_login == contributor) 

# summary data:
user_data.summary <- user_data %>%
  summarise(pr_count = n(), mean_commits=mean(commits), mean_comments=mean(comments), mean_cycle=mean(cycle_time_in_days),
            median_comments = median(comments),  medeian_commits=median(commits), median_cycle=median(cycle_time_in_days))

# the longest
user_data.longest <- user_data %>%
  filter(cycle_time_in_days > 5) %>%
  arrange(desc(cycle_time_in_seconds))
