beta_calibration <- function(p, y, parameters){
  p <- pclip(p)
  if (parameters == "abm"){
    d <- data.frame(y)
    d$lp <- log(p)
    d$l1p <- -log(1-p)

    fit <- glm(y~lp+l1p,family=binomial(link='logit'),data=d)

    a <- as.numeric(fit$coefficients['lp'])
    b <- as.numeric(fit$coefficients['l1p'])
    if (a < 0){
      fit <- glm(y~l1p,family=binomial(link='logit'),data=d)
      a <- 0
      b <- as.numeric(fit$coefficients['l1p'])
    }else if (b < 0){
      fit <- glm(y~lp,family=binomial(link='logit'),data=d)
      a <- as.numeric(fit$coefficients['lp'])
      b <- 0
    }
    inter <- as.numeric(fit$coefficients['(Intercept)'])
    print(-b*log(1-1e-16)+a*log(1e-16)-inter)
    print(-b*log(1e-16)+a*log(1-1e-16)-inter)
    m <- uniroot(function(mh) b*log(1-mh)-a*log(mh)-inter,c(1e-16,1-1e-16))$root

    calibration <- list("map" = c(a,b,m), "model" = fit, "parameters" = parameters)
    return(calibration)

  }else if (parameters == "am"){
    d <- data.frame(y)
    d$lp <- log(p / (1 - p))

    fit <- glm(y~lp,family=binomial(link='logit'), data=d)

    inter = as.numeric(fit$coefficients['(Intercept)'])
    a <- as.numeric(fit$coefficients['lp'])
    b <- a
    m <- 1.0 / (1.0 + exp(inter / a))

    calibration <- list("map" = c(a,b,m), "model" = fit, "parameters" = parameters)
    return(calibration)

  }else if (parameters == "ab"){
    d <- data.frame(y)
    d$lp <- log(2 * p)
    d$l1p <- log(2*(1-p))

    fit = glm(y~lp+l1p-1,family=binomial(link='logit'), data=d)

    a <- as.numeric(fit$coefficients['lp'])
    b <- -as.numeric(fit$coefficients['l1p'])
    m = 0.5

    calibration <- list("map" = c(a,b,m), "model" = fit, "parameters" = parameters)
    return(calibration)
  }else{
    stop("Unknown parameters. Expected abm, am or ab.")
  }
}

beta_predict <- function(p, calib){
  p <- pclip(p)
  d <- data.frame(p)
  if (calib$parameters == "abm"){
    d$lp <- log(p)
    d$l1p <- -log(1-p)
  }else if (calib$parameters == "am"){
    d$lp <- log(p / (1 - p))
  }else if (calib$parameters == "ab"){
    d$lp <- log(2 * p)
    d$l1p <- log(2*(1-p))
  }
  return(predict(calib$model, newdata=d, type="response"))
}

pclip <- function(vec, LB=1e-16, UB=1-1e-16) pmax(LB, pmin( vec, UB))