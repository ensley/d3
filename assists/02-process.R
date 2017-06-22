library(tidyverse)
library(jsonlite)


goals <- read_csv('data/allgoals.csv', col_types = cols(time = col_character()))
pitgoals <- goals %>%
  filter(team == 'PIT')

goalscorers <- pitgoals %>%
  group_by(id = g_id, last = g_last, first = g_first) %>%
  summarize(count = n()) %>% 
  select(-count)

assist1 <- pitgoals %>%
  group_by(id = a1_id, last = a1_last, first = a1_first) %>%
  summarize(count = n()) %>% 
  select(-count) %>% 
  filter(!is.na(id))

assist2 <- pitgoals %>%
  group_by(id = a2_id, last = a2_last, first = a2_first) %>%
  summarize(count = n()) %>% 
  select(-count) %>% 
  filter(!is.na(id))

allplayers <- union(goalscorers, assist1) %>% union(assist2)


player_df <- read_csv('data/allplayers.csv')
allplayers <- left_join(allplayers, player_df)

colors <- data_frame(pos = c('C', 'LW', 'RW', 'D', 'G'),
                     posgrp = c('F', 'F', 'F', 'D', 'G'),
                     color = c('#ffcc33', '#ffcc33', '#ffcc33', '#040707', '#377EB8'))
allplayers <- left_join(allplayers, colors)
allplayers$posgrp <- ordered(allplayers$posgrp, levels = c('F', 'D', 'G'))
allplayers <- arrange(allplayers, posgrp, last)

create_adjacency_matrix <- function(df, allplayers) {
  # initialize matrix
  adj <- diag(0, nrow = nrow(allplayers), ncol = nrow(allplayers))
  
  for(i in seq_along(df$date)) {
    gi <- which(allplayers$id == df$g_id[i])
    a1i <- which(allplayers$id == df$a1_id[i])
    a2i <- which(allplayers$id == df$a2_id[i])
    
    adj[a1i,gi] <- adj[a1i,gi] + 1
    adj[a2i,gi] <- adj[a2i,gi] + 1
  }
  
  rownames(adj) <- colnames(adj) <- allplayers$last
  adj
}

adj <- create_adjacency_matrix(allgoals, allplayers)

write_json(adj, 'data/matrix.json')
write_csv(allplayers, 'data/roster.csv')
