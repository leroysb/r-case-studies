# Load data
library(tidyverse)
library(dslabs)
library(caret)
library(rpart)
data("olive")
str(olive)

olive %>% as_tibble()
table(olive$region)
olive <- select(olive, -area) #Remove area as it is not used as a predictor

# Predict region using KNN
library(caret)
fit <- train(region ~ .,  method = "knn", 
             tuneGrid = data.frame(k = seq(1, 15, 2)), 
             data = olive)
ggplot(fit)

# Plot distribution of each predictor stratified by region
olive %>% gather(fatty_acid, percentage, -region) %>%
  ggplot(aes(region, percentage, fill = region)) +
  geom_boxplot() +
  facet_wrap(~fatty_acid, scales = "free") +
  theme(axis.text.x = element_blank())

# plot values for eicosenoic and linoleic
p <- olive %>% 
  ggplot(aes(eicosenoic, linoleic, color = region)) + 
  geom_point()

p + geom_vline(xintercept = 0.065, lty = 2) + 
  geom_segment(x = -0.2, y = 10.54, xend = 0.065, yend = 10.54, color = "black", lty = 2)

###
###

## 2008 POLLS DATA
# load data for regression tree
data("polls_2008")
qplot(day, margin, data = polls_2008)

library(rpart)
fit <- rpart(margin ~ ., data = polls_2008)

# visualize the splits 
plot(fit, margin = 0.1)
text(fit, cex = 0.75)

polls_2008 %>% 
  mutate(y_hat = predict(fit)) %>% 
  ggplot() +
  geom_point(aes(day, margin)) +
  geom_step(aes(day, y_hat), col="red")

# change parameters
fit <- rpart(margin ~ ., data = polls_2008, control = rpart.control(cp = 0, minsplit = 2))

polls_2008 %>% 
  mutate(y_hat = predict(fit)) %>% 
  ggplot() +
  geom_point(aes(day, margin)) +
  geom_step(aes(day, y_hat), col="red")

# use cross validation to choose cp
library(caret)
train_rpart <- train(margin ~ .,method = "rpart",tuneGrid = data.frame(cp = seq(0, 0.05, len = 25)),data = polls_2008)
ggplot(train_rpart)

# access the final model and plot it
plot(train_rpart$finalModel, margin = 0.1)
text(train_rpart$finalModel, cex = 0.75)

polls_2008 %>% 
  mutate(y_hat = predict(train_rpart)) %>% 
  ggplot() +
  geom_point(aes(day, margin)) +
  geom_step(aes(day, y_hat), col="red")

# prune the tree 
pruned_fit <- prune(fit, cp = 0.01)

###
###

## CLASSIFICATION TREE

data("mnist_27")
# fit a classification tree and plot it
train_rpart <- train(y ~ .,
                     method = "rpart",
                     tuneGrid = data.frame(cp = seq(0, 0.1, 0.01)),
                     data = mnist_27$train)
plot(train_rpart)

# compute accuracy
confusionMatrix(predict(train_rpart, mnist_27$test), mnist_27$test$y)$overall["Accuracy"]

###
###

### RANDOM FORESTS

## Apply random forest to the 2018 polls data
library(randomForest)
fit <- randomForest(margin~., data = polls_2008)
plot(fit)

polls_2008 %>%
  mutate(y_hat = predict(fit, newdata = polls_2008)) %>% 
  ggplot() +
  geom_point(aes(day, margin)) +
  geom_line(aes(day, y_hat), col="red")
# the final result is somewhat smooth.

## Apply random forest to the 2 and 7 dataset

library(randomForest)
train_rf <- randomForest(y ~ ., data=mnist_27$train)
confusionMatrix(predict(train_rf, mnist_27$test), mnist_27$test$y)$overall["Accuracy"]

# use cross validation to choose parameter
train_rf_2 <- train(y ~ .,
                    method = "Rborist",
                    tuneGrid = data.frame(predFixed = 2, minNode = c(3, 50)),
                    data = mnist_27$train)
confusionMatrix(predict(train_rf_2, mnist_27$test), mnist_27$test$y)$overall["Accuracy"]


###
###

library(rpart)
library(tidyverse)
n <- 1000
sigma <- 0.25
set.seed(1, sample.kind = "Rounding")
x <- rnorm(n, 0, 1)
y <- 0.75 * x + rnorm(n, 0, sigma)
dat <- data.frame(x = x, y = y)

fit <- rpart(y ~ . , data = dat)
# visualize the splits 
plot(fit, margin = 0.1)
text(fit, cex = 0.75)

# scatter plot of y versus x along with the predicted values based on the fit
dat %>% 
  mutate(y_hat = predict(fit)) %>% 
  ggplot() +
  geom_point(aes(x, y)) + geom_step(aes(x, y_hat), col=2)


## Now run Random Forests instead of a regression tree
library(randomForest)
fit <- randomForest(y ~ x, data = dat)
dat %>% 
  mutate(y_hat = predict(fit)) %>% 
  ggplot() +
  geom_point(aes(x, y)) +
  geom_step(aes(x, y_hat), col = 2)

# Use plot function to see if the Random Forest has converged or if we need more trees
plot(fit)
# It seems that the default values for the Random Forest result in an estimate that is too flexible (unsmooth).
# Re-run the Random Forest but this time with a node size of 50 and a maximum of 25 nodes
fit <- randomForest(y ~ x, data = dat, nodesize = 50, maxnodes = 25)
dat %>% 
  mutate(y_hat = predict(fit)) %>% 
  ggplot() +
  geom_point(aes(x, y)) +
  geom_step(aes(x, y_hat), col = 2)
plot(fit)

## Tuning Parameters with the CARET package
getModelInfo("knn")
modelLookup("knn")

train_knn <- train(y ~ ., method = "knn", data = mnist_27$train)
ggplot(train_knn, highlight = TRUE)

train_knn <- train(y ~ ., method = "knn", 
                   data = mnist_27$train,
                   tuneGrid = data.frame(k = seq(9, 71, 2)))
ggplot(train_knn, highlight = TRUE)

train_knn$bestTune

train_knn$finalModel

confusionMatrix(predict(train_knn, mnist_27$test, type = "raw"),
                mnist_27$test$y)$overall["Accuracy"]

control <- trainControl(method = "cv", number = 10, p = .9)
train_knn_cv <- train(y ~ ., method = "knn", 
                      data = mnist_27$train,
                      tuneGrid = data.frame(k = seq(9, 71, 2)),
                      trControl = control)
ggplot(train_knn_cv, highlight = TRUE)

train_knn$results %>% 
  ggplot(aes(x = k, y = Accuracy)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(x = k, 
                    ymin = Accuracy - AccuracySD,
                    ymax = Accuracy + AccuracySD))

plot_cond_prob <- function(p_hat=NULL){
  tmp <- mnist_27$true_p
  if(!is.null(p_hat)){
    tmp <- mutate(tmp, p=p_hat)
  }
  tmp %>% ggplot(aes(x_1, x_2, z=p, fill=p)) +
    geom_raster(show.legend = FALSE) +
    scale_fill_gradientn(colors=c("#F8766D","white","#00BFC4")) +
    stat_contour(breaks=c(0.5),color="black")
}

plot_cond_prob(predict(train_knn, mnist_27$true_p, type = "prob")[,2])
# the best-fitting knn model approximates the true condition of probability pretty well.
# However, we do see that the boundary is somewhat wiggly.
# This is because knn, like the basic bin smoother, does not use a smooth kernel.
# To improve this, we could try loess.

install.packages("gam")
modelLookup("gamLoess")
# From the modelLookup, we have two parameters to optimize if we use this particular method

# we'll keep the degree fixed at one. We won't try out degree two.
# But to try out different values for the span, we still have to include a column in the table with the named degree.
# This is a requirement of the caret package. So we would define a grid using the expand.grid function
grid <- expand.grid(span = seq(0.15, 0.65, len = 10), degree = 1)

train_loess <- train(y ~ ., 
                     method = "gamLoess",
                     tuneGrid=grid,
                     data = mnist_27$train)
# select the best-performing model
ggplot(train_loess, highlight = TRUE)

confusionMatrix(data = predict(train_loess, mnist_27$test), 
                reference = mnist_27$test$y)$overall["Accuracy"]
# now we can see the final result. It performs similarly to knn

# we can see that the conditional probability estimate is indeed smoother than what we get with knn.
p1 <- plot_cond_prob(predict(train_loess, mnist_27$true_p, type = "prob")[,2])
p1

####
####

library(dslabs)
library(caret)
library(rpart)
data("tissue_gene_expression")
set.seed(1991, sample.kind = "Rounding")

train_rpart <- train(tissue_gene_expression$x, tissue_gene_expression$y,
                     method = "rpart", 
                     tuneGrid = data.frame(cp = seq(0, 0.1, 0.01)),
                     control = rpart.control(minsplit = 0)
                     )
ggplot(train_rpart)
train_rpart$results
confusionMatrix(train_rpart)

plot(train_rpart$finalModel, margin = 0.1)
text(train_rpart$finalModel, cex = 0.75)

##OR

fit_rpart <- with(tissue_gene_expression, 
                  train(x, y, method = "rpart",
                        tuneGrid = data.frame(cp = seq(0, 0.10, 0.01)),
                        control = rpart.control(minsplit = 0)))
varImp(fit_rpart)
ggplot(fit_rpart)
confusionMatrix(fit_rpart)

tree_terms <- as.character(unique(fit_rpart$finalModel$frame$var[!(fit_rpart$finalModel$frame$var == "<leaf>")]))
tree_terms

# Can we predict the tissue type with even fewer genes using a Random Forest
library(dslabs)
library(caret)
library(rpart)
library(randomForest)
data("tissue_gene_expression")

set.seed(1991, sample.kind = "Rounding")

fit <- train(tissue_gene_expression$x, tissue_gene_expression$y,
                     method = "rf", nodesize = 1, ntree = 8,
             tuneGrid = data.frame(mtry = seq(0, 200, 50)))
ggplot(fit)
fit$bestTune
imp <- varImp(fit, scale = FALSE)
imp

##OR

set.seed(1991)
library(randomForest)
fit <- with(tissue_gene_expression, 
            train(x, y, method = "rf", 
                  nodesize = 1,
                  tuneGrid = data.frame(mtry = seq(50, 200, 25))))
fit$bestTune
imp <- varImp(fit)
imp