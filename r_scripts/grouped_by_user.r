# I'd like to know:
#   group pull requests by users
#   get top 100

data <- read.csv("data/rails_rails_prs.csv", header=TRUE, stringsAsFactors = FALSE)
data$created_at <- as.POSIXct(data$created_at)

require("dplyr")

top_users = data %>% 
  filter(merged_in == "true") %>% 
  group_by(user_login)  %>% 
  summarise(pr_count=n(), sum_deletions = sum(deletions), sum_additions = sum(additions))  %>%
  arrange(desc(pr_count)) %>%
  filter(pr_count>10)
