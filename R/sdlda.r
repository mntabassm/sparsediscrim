library(plyr)

# Shrinkage-based Diagonal Linear Discriminant Analysis (SDLDA)
# The DLDA classifier is a modification to LDA, where the off-diagonal elements
# of the pooled sample covariance matrix are set to zero.
# We use a shrinkage method based on Pang, Tong, and Zhao (2009).
# We assume the first column is named "labels" and holds a factor vector,
# which contains the class labels.

# We assume the first column is named "labels" and holds a factor vector,
# which contains the class labels.
sdlda <- function(training.df, num.alphas = 5) {
	N <- nrow(training.df)
	num.classes <- nlevels(training.df$labels)
	
	training.x <- as.matrix(training.df[,-1])
	dimnames(training.x) <- NULL
	var.pooled <- apply(training.x, 2, function(col) {
		(N - 1) * var(col) / N
	})
	
	var.shrink <- var.shrinkage(N = N, K = num.classes, var.feature = var.pooled, num.alphas = num.alphas, t = -1)
	
	estimators <- dlply(training.df, .(labels), function(class.df) {
		class.x <- as.matrix(class.df[,-1])
		dimnames(class.x) <- NULL
		
		n.k <- nrow(class.df)
		p.hat <- n.k / N
		xbar <- as.vector(colMeans(class.x))
		list(xbar = xbar, var = var.shrink, n = n.k, p.hat = p.hat)
	})
	
	list(N = N, classes = levels(training.df$labels), estimators = estimators)
}

predict.sdlda <- function(object, newdata) {
	newdata <- as.matrix(newdata)
	dimnames(newdata) <- NULL
	
	predictions <- apply(newdata, 1, function(obs) {
		scores <- laply(object$estimators, function(class.est) {
			sum((obs - class.est$xbar)^2 * class.est$var) - 2 * log(class.est$p.hat)
		})
		predicted.class <- object$classes[which.min(scores)]
		predicted.class
	})
	
	predictions
}