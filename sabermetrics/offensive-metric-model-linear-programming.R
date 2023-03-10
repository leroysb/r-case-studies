# A way to actually pick the players for the team can be done using what computer scientists call linear programming.

library(reshape2)
library(lpSolve)

players <- players %>% filter(debut <= "1997-01-01" & debut > "1988-01-01")

constraint_matrix <- acast(players, POS ~ playerID, fun.aggregate = length)

npos <- nrow(constraint_matrix)

constraint_matrix <- rbind(constraint_matrix, salary = players$salary)

constraint_dir <- c(rep("==", npos), "<=")

constraint_limit <- c(rep(1, npos), 50*10^6)

lp_solution <- lp("max", players$R_hat, constraint_matrix, constraint_dir, constraint_limit, all.int = TRUE)

# This algorithm chooses these 9 players
our_team <- players %>%
  filter(lp_solution$solution == 1) %>%
  arrange(desc(R_hat))

our_team %>% select(nameFirst, nameLast, POS, salary, R_hat)

# We note that these players all have above average BB and HR rates while the same is not true for singles.
my_scale <- function(x) (x - median(x))/mad(x)

players %>% mutate(BB = my_scale(BB), 
                   singles = my_scale(singles),
                   doubles = my_scale(doubles),
                   triples = my_scale(triples),
                   HR = my_scale(HR),
                   AVG = my_scale(AVG),
                   R_hat = my_scale(R_hat)) %>%
  filter(playerID %in% our_team$playerID) %>%
  select(nameFirst, nameLast, BB, singles, doubles, triples, HR, AVG, R_hat) %>%
  arrange(desc(R_hat))



