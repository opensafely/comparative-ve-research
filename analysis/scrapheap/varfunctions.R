sdfsf

get_varp <- function(model, vcov, newdata){
  ## function to get (some of the) variance of the cumulative incidence
  ## this only works because the treatment variable is numeric (0/1)
  ## if it were a factor, then model.matrix would throw an error about contrasts (because treatment var is set to all one variable)

  # # select only rows for given patient ID and day
  # newdata <- newdata %>%
  #   filter(
  #     tstop <= day,
  #     patient_id == patient_idd
  #   )

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms, data=newdata) # t x k
  m.coef <- model$coef # 1 x k

  len <- dim(m.mat)[1]

  nu <- m.coef%*%t(m.mat) # t x 1

  logit2nu <- (exp(nu)/((1+exp(nu))^2)) # t x 1

  deriv_nu <- t(m.mat) %*% c(logit2nu)  # k x n

  stopifnot("term indices are not aligned" = rownames(vcov)==names(deriv_nu))

  var <- as.vector(t(deriv_nu) %*% vcov %*% deriv_nu)
  var
}


get_partialderiv <- function(model, vcov, newdata){
  ## function to get the partial derivative of the cumulative incidence for a single patient

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms, data=newdata) # t x k
  m.coef <- model$coef # 1 x k

  # max follow up time
  len <- dim(m.mat)[1] # scalar

  # log-odds, nu_t, at time t
  nu <- m.coef %*% t(m.mat) # T x 1
  # part of partial derivative
  pdc <- (exp(nu)/((1+exp(nu))^2)) # T x 1
  # partial derivative for P_t(theta_t), for time t and term k
  pderiv_nu <- t(m.mat) %*% c(pdc)  # k x T

  pderiv_nu

  # # "covariance" of var[P_t(theta_t), P_t(theta_t)]
  # vcovP <- (pderiv_nu %*% vcov) %*% t(pderiv_nu) # T x T
  # # variance of cumulative product, VAR[cumsum(P_t(theta_t))]
  # cml_partial <- rep(0,4)
  # for(i in 1:4){
  #   # sum of the "frontier" of the upper-left triangle
  #   cml_partial[i] <- sum(vcovP[1:i,i]) + sum(vcovP[i,1:i]) - vcovP[i,i]
  # }
  # cumulative_variance <- cumsum(cml_partial)
}



get_partialderiv_mat <- function(model, vcov, newdata){
  ## function to get the summand of partial derivative of the cumulative incidence

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)  # 1 x k
  m.mat <- model.matrix(Terms, data=newdata) # (t_i * i) x k
  m.coef <- model$coef # 1 x k

  # log-odds, nu_t, at time t
  nu <- m.coef %*% t(m.mat) # (t_i * i) x 1
  # part of partial derivative
  pdc <- (exp(nu)/((1+exp(nu))^2)) # (t_i * i) x 1
  # partial derivative for P_t(theta_t), for time t and term k
  pderiv_nu <- t(m.mat) %*% diag(pdc) # (t_i * i) x k

  pderiv_nu
}





get_partialderiv <- function(model, vcov, newdata){
  ## function to get the partial derivative of the P at time t for patient i

  tt <- terms(model) # this helpfully grabs the correct spline basis from the model, rather than recalculating based on `newdata`
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms, data=newdata) # 1 x k
  m.coef <- model$coef # 1 x k

  # log-odds, nu_t, at time t
  nu <- sum(m.coef * m.mat) # scalar
  # part of partial derivative
  pdc <- exp(nu)/((1+exp(nu))^2) # scalar
  # partial derivative for p_t(theta_t), for time t and term k
  pderiv_nu <- as.vector(m.mat * pdc)  # 1 x k

  pderiv_nu
}



combine_partialderiv <- function(list_pderiv, vcov, weight){
  ## function to combine partial derivatives of the cumulative incidence, and obtain variance
  mean_pderiv <- Reduce(`+`, list_pderiv)*weight / sum(weight)

  t(mean_pderiv) %*% vcov %*% mean_pderiv
}
