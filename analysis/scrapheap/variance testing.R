





if(missing(newdata)){ newdata <- model$model }
tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
Terms <- delete.response(tt)
m.mat <- model.matrix(Terms, data=newdata)
m.coef <- model$coef


id <- c(1,1,1,1,2,2,2)
time <- c(1,2,3,4,1,2,3)
weights <- c(1,1,1,1,2,2,2)

m.mat <- cbind(
  time,
  c(1,1,1,1,2,2,2),
  c(3,3,3,3,2,2,2)
)
m.coef <- c(1,0.4,0.5)

vcov <- cbind(
  c(1,0.3,0.3),
  c(0.2,0.5,0.2),
  c(0.7,0.3,0.7)
)


N <- nrow(m.mat)
K <- length(m.coef)

# log-odds, nu_t, at time t
nu <- m.coef %*% t(m.mat) # t_i x 1
# part of partial derivative
pdc <- (exp(nu)/((1+exp(nu))^2)) # t_i x 1
# summand for partial derivative of P_t(theta_t | X_t), for each time t and term k

#summand <- crossprod(diag(as.vector(pdc)), m.mat)    # t_i  x k
summand <- matrix(0, nrow=N, ncol=K)
for (k in seq_len(K)){
  summand[,k] <- m.mat[,k] * as.vector(pdc)
}

# cumulative sum of summand, by patient_id  # t_i x k
cmlsum <- matrix(0, nrow=N, ncol=K)
for (k in seq_len(K)){
  cmlsum[,k] <- ave(summand[,k], id, FUN=cumsum)
}

## multiply by model weights (weights are normalised here so we can use `sum` later, not `weighted.mean`)
normweights <- weights / ave(weights, time, FUN=sum) # t_i x 1

#wgtcmlsum <- crossprod(diag(normweights), cmlsum ) # t_i x k
wgtcmlsum <- matrix(0, nrow=N, ncol=K)
for (k in seq_len(K)){
  wgtcmlsum[,k] <- cmlsum[,k] * normweights
}

# partial derivative of cumulative incidence at t
partial_derivative <- rowsum(wgtcmlsum, time)

variance <- rowSums(crossprod(t(partial_derivative), vcov) * partial_derivative) # t x 1
#variance <- (diag(partial_derivative%*%vcov%*%t(partial_derivative)))
#variance <- rowSums(partial_derivative * (partial_derivative %*% vcov))

variance



# explicit walkthrough

nu1 <- m.coef %*% m.mat[1,]
pdc1 <- exp(nu1)/((1+exp(nu1))^2)
summand1k <- m.mat[1,]*as.vector(pdc1)

nu2 <- m.coef %*% m.mat[2,]
pdc2 <- exp(nu2)/((1+exp(nu2))^2)
summand2k <- m.mat[2,]*as.vector(pdc2)

nu3 <- m.coef %*% m.mat[3,]
pdc3 <- exp(nu3)/((1+exp(nu3))^2)
summand3k <- m.mat[3,]*as.vector(pdc3)

nu3 <- m.coef %*% m.mat[3,]
pdc3 <- exp(nu3)/((1+exp(nu3))^2)
summand3k <- m.mat[3,]*as.vector(pdc3)

nu4 <- m.coef %*% m.mat[4,]
pdc4 <- exp(nu4)/((1+exp(nu4))^2)
summand4k <- m.mat[4,]*as.vector(pdc4)

nu5 <- m.coef %*% m.mat[5,]
pdc5 <- exp(nu5)/((1+exp(nu5))^2)
summand5k <- m.mat[5,]*as.vector(pdc5)

nu6 <- m.coef %*% m.mat[6,]
pdc6 <- exp(nu6)/((1+exp(nu6))^2)
summand6k <- m.mat[6,]*as.vector(pdc6)

nu7 <- m.coef %*% m.mat[7,]
pdc7 <- exp(nu7)/((1+exp(nu7))^2)
summand7k <- m.mat[7,]*as.vector(pdc7)

cmla1k <- summand1k
cmla2k <- summand1k + summand2k
cmla3k <- summand1k + summand2k  + summand3k
cmla4k <- summand1k + summand2k  + summand3k + summand4k

cmlb1k <- summand5k
cmlb2k <- summand5k + summand6k
cmlb3k <- summand5k + summand6k + summand7k


normweights <- weights/ave(weights, time, FUN=sum)

cmla1k_weight <- cmla1k*normweights[1]
cmla2k_weight <- cmla2k*normweights[2]
cmla3k_weight <- cmla3k*normweights[3]
cmla4k_weight <- cmla4k*normweights[4]

cmlb1k_weight <- cmlb1k*normweights[5]
cmlb2k_weight <- cmlb2k*normweights[6]
cmlb3k_weight <- cmlb3k*normweights[7]

mean1 <- (cmla1k_weight + cmlb1k_weight)
mean2 <- (cmla2k_weight + cmlb2k_weight)
mean3 <- (cmla3k_weight + cmlb3k_weight)
mean4 <- cmla4k_weight


var1 <- t(mean1) %*% vcov %*% mean1
var2 <- t(mean2) %*% vcov %*% mean2
var3 <- t(mean3) %*% vcov %*% mean3
var4 <- t(mean4) %*% vcov %*% mean4

vartrue <- c(var1, var2, var3, var4)



