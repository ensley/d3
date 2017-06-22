library(mysportsfeedsR)
library(rvest)
library(stringr)


# authentication ----------------------------------------------------------


# authenticate_v1_0('username', 'password')


# functions ---------------------------------------------------------------


create_gameid <- function(entry) {
  paste0(str_replace_all(entry$date, '-', ''), '-', entry$awayTeam$Abbreviation, '-', entry$homeTeam$Abbreviation)
}

get_goals_in_period <- function(pd) {
  dat <- sapply(pd$scoring$goalScored, function(g) {
    vec <- c(pd$`@number`, g$time, g$teamAbbreviation,
             g$goalScorer$ID, g$goalScorer$LastName, g$goalScorer$FirstName,
             g$assist1Player$ID, g$assist1Player$LastName, g$assist1Player$FirstName,
             g$assist2Player$ID, g$assist2Player$LastName, g$assist2Player$FirstName)
    c(vec, rep(NA, 12 - length(vec)))
  })
  df <- data.frame(t(dat))
  if(ncol(df) == 0) return(NULL)
  names(df) <- c('pd', 'time', 'team', 'g_id', 'g_last', 'g_first', 'a1_id', 'a1_last', 'a1_first', 'a2_id', 'a2_last', 'a2_first')
  df
}

get_goals_in_game <- function(gm) {
  lists <- lapply(gm$gameboxscore$periodSummary$period, get_goals_in_period)
  df <- data.frame(date = gm$gameboxscore$game$date)
  df <- cbind(df, do.call(rbind.data.frame, c(lists, stringsAsFactors = FALSE)))
  numeric_cols <- which(names(df) %in% c('g_id', 'a1_id', 'a2_id'))
  df[numeric_cols] <- apply(df[numeric_cols], 2, as.numeric)
  df[-numeric_cols] <- apply(df[-numeric_cols], 2, as.character)
  df
}

get_all_goals <- function(gameids) {
  games <- lapply(gameids, function(id) {
    boxscore <- msf_get_results(league='nhl', season='2016-2017-regular', feed='game_boxscore', params=list(gameid=id))
    boxscore_content <- content(boxscore$response, 'parsed')
    get_goals_in_game(boxscore_content)
  })
  games
  do.call(rbind.data.frame, c(games, stringsAsFactors = FALSE))
}


# script ------------------------------------------------------------------


gamelogs <- msf_get_results(league='nhl',season='2016-2017-regular',feed='full_game_schedule',params=list(team='PIT'))
content <- content(gamelogs$response, 'parsed')

gameids <- sapply(game_entries, create_gameid)

allgoals <- get_all_goals(gameids)
write.csv(allgoals, 'data/allgoals.csv', row.names = FALSE)



players <- msf_get_results(league='nhl', season='2016-2017-regular', feed='active_players')
player_content <- content(players$response, 'parsed')
player_list <- lapply(player_content$activeplayers$playerentry, function(p) {
  list(id = p$player$ID,
       last = p$player$LastName,
       first = p$player$FirstName,
       pos = p$player$Position)
})
player_df <- bind_rows(player_list)
write_csv(player_df, 'data/allplayers.csv')
