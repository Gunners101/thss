sen.anal=9
maxIterations=100
options.ps=99
options.dv=3
options.eval=1
option.halfwidth=FALSE

point_est.csps <- function (sen.anal=9, maxIterations=50, options.ps=99, options.dv=3, options.eval=1, option.halfwidth=FALSE){
  
  ############################ INITIALISATION ################################
  
  # calculate estimated completion time
  print(paste("estimated completion time ", round(maxIterations*18/60/60,2), " hours.", sep="")) 
    
  # begin stopwatch
  tic <- Sys.time() 
  
  ###### NECESSARY INITIAL VALUES USED IN "main_settings.R"
  func_name <- "CEM"
  t <- 1 # time-step counter
  
  ###### SENSITIVITY ANALYSIS
  sensivity.costs <- data.frame(ec=c(rep(c(1.75,0.75),4) , 1.25),
                                cc=c(rep(c(0.8,0.2),times=2, each=2) , 0.5),
                                hc=c(rep(c(0.0875,0.0775), each=4) , 0.0825)
  )  
  
  ###### MAIN SETTINGS. MUST CHANGE FILEPATHS IF RUNNING ON A DIFFERENT COMPUTER. MUST ALSO INSTALL PACKAGES LISTED THEREIN.
  source(paste(Rcode_path,"main_settings.R",sep=.Platform$file.sep), local=TRUE)
  
  ###### IF OPTIONS.PS = 99 (all powerstations), then we let PS = a sequence of 1-to-psc_tot
  if (options.ps == 99){
    options.ps_write <- "all"
    options.ps <- 1:psc_tot
    print("all powerstations will be optimised")
  } else {
    print(paste("powerstation ", options.ps," (", colnames(psc_template)[options.ps], ") ",  "will be optimised", sep=""))
  }
  

  ###### CHECK THAT ESTIMATED VALUES EXIST
  # Stop the optimiser if the estimator has not been run initially.
  # If file doesnt exist, stop the optimiser. Estimates are required for the optimiser's planned deliveries.
  if (!file.exists(paste(optPath,"/final-results/base1/result.csv",sep=sep_))) {
    stop("For the optimiser to work, optimiser must first be run.") 
  }
  
  ###### GET INITIAL VALUES FROM EFS DATABASE
  # !when using getDBvalues() be aware of all the optional parameters!
  # the default values are: name_='psc_delvin', param_='COAL_DELIVERY_IN', paramkind_='INP', type_='COAL_PS', ent_='POWERSTATION'
  psc_SPinitial <- getDBvalues(param_ = 'INITIALSTOCK', paramkind_='INP')
  psc_delvin    <- getDBvalues(param_ = 'COAL_DELIVERY_IN', paramkind_='INP')
  psc_delvout   <- getDBvalues(param_ = 'COAL_DELIVERY_OUT', paramkind_ = 'RES')
  psc_burnin    <- getDBvalues(param_ = 'COAL_BURN_IN', paramkind_='INP')
  psc_burnout   <- getDBvalues(param_ = 'COAL_BURN_OUT', paramkind_ = 'RES')
  psc_SPvol     <- getDBvalues(param_ = 'STOCKPILE_VOL', paramkind_ = 'RES')
  psc_cost      <- getDBvalues(param_ = 'COSTOFSUPPLY', paramkind_='INP')
  psc_heatrate  <- getDBvalues(param_ = 'HEATRATE', paramkind_ = 'INP')
  psc_cv        <- getDBvalues(param_ = 'CV', paramkind_ = 'INP')
  
  #simulation settings
  changeSimSet(seed=10, iter=1000)
  print(paste("simulation seed =", CM_sim_settings()$SEED))
  print(paste("simulation iter =", CM_sim_settings()$ITERATIONS))
  
  ###### Use estimator's ave burnout to set delvin (baseline deliveries). Only set in the beginning, doesnt change thereafter. 
  est_ave_burnout <- read.csv(paste(paste(optEstPath, est_names[4], sep=sep_) ,".csv",sep=""), 
                              header = TRUE, sep = ",", quote = "\"", dec = ".", 
                              fill = TRUE, comment.char = "")
  est_ave_burnout[,1] <- NULL # clean dataframe
  est_ave_burnout <- apply(est_ave_burnout,2,mean)
  dv_delv_base <- est_ave_burnout
  dv_delv <- psc_template
  dv_delv[,]  <- dv_delv_base
  
  setDBvalues(values_ = dv_delv, param_ = 'COAL_DELIVERY_IN')
  psc_delvin <- getDBvalues(param_ = 'COAL_DELIVERY_IN', paramkind_='INP')
  
  
  ######
  results <- read.csv(text=readLines(paste(optPath, "/final-results/base1/result.csv", sep=sep_))[-(1:9)])
  results <- results[nrow(results),]
  results.mu <- as.numeric(results[, 1:42 + 8])
  results.sigma <- as.numeric(results[, 1:42 + 8 +42])
  
  
  ###### NUMBER OF DECISION VARIABLES
  numVar <- 3*psc_tot
  
  ###### SET PARAMETERS FOR CEM (CROSS ENTROPY METHOD)
  rho <- 0.2 #0<=rho<=1. Percentage of solutions to keep (elite %)
  epsNum <- 5 #Maximum error (a.k.a required accuracy)
  epsErr  <- 10 #try make it as close to zero as possible.
  alpha <- 0.75 #convergence rate, typical varies between 0.6 & 0.9
  
  ###### INITIALISE DECISION VARIABLES & SET CONSTRAINTS
  ### DELIVERY CONSTRAINTS
  llim_delv <- rep(0,psc_tot)
  ulim_delv <- rep(3000,psc_tot)
  
  ### MIN SP level
  min_SPdays <- 5 #shortage
  
  ### DV = Stockpiles: Initial(desired), UpperWarningLimit & LowerWarningLimit.
  # initialise all mus and sigmas
  mus <- unlist(results.mu)
  sigmas <- unlist(results.sigma)
  # Calc 1 sp day average
  SP1day_ave <- apply(psc_burnout,2,mean)/30
  
  # Initial decision variables
  dv_SPinitial <- mus[1:psc_tot]
  
  ### INITIAL (DESIRED) SP
  # Constraints
  llim_init <- SP1day_ave*5
  ulim_init <- SP1day_ave*25
    
  ### LOWER WARNING LIMIT & UPPER WARNING LIMIT
  # Constraints: LWL & UWL
  llim_lower <- SP1day_ave*1
  ulim_lower <- 0.9 # It is a factor of each randomly generated initial (desired) stockpile level.
  llim_upper <- 1.1 # It is a factor of each randomly generated initial (desired) stockpile level.
  ulim_upper <- SP1day_ave*30
  
  ###### LOAD OBJECTIVE FUNCTION
  source(paste(Rcode_path,"main_obj_func.R",sep=.Platform$file.sep), local=TRUE)
  
  delv_emer <- psc_template
  delv_canc <- psc_template
  delv_emer[,] <- 0
  delv_canc[,] <- 0
  SPvar <- 0
  
  sigma_quantile <- matrix(NA,numVar,maxIterations)
  z_quantile <- rep(NA,maxIterations)
  
  ###### WRITE TO RESULTS FILE
  #print parameters
  write.row(c("opt_type",func_name), append=FALSE)
  write.row(c('options.ps',options.ps_write))
  write.row(c('options.dv',options.dv))
  write.row(c('options.eval',options.eval))
  write.row(c('rho',rho))
  write.row(c('N',0))
  write.row(c('maxIterations',maxIterations))
  write.row(c('alpha',alpha))
  write.row('')
  
  #print the header for the results
  header <- c("t","seed","Z(mus)","z.h", "z.s","z.e", "z.c", "Z(quan)",
              paste('mu_in', 1:psc_tot, sep=""), #mu of initial SP
              paste('mu_lo', 1:psc_tot, sep=""), #mu of upper warning
              paste('mu_up', 1:psc_tot, sep=""), #mu of lower warning
              paste('si_in', 1:psc_tot, sep=""), #sigma of initial SP
              paste('si_lo', 1:psc_tot, sep=""), #sigma of upper warning
              paste('si_up', 1:psc_tot, sep=""), #sigma of lower warning
              paste('emer', 1:(interval_num*psc_tot), sep=""), #emergency deliveries
              paste('canc', 1:(interval_num*psc_tot), sep=""), #cancellation of deliveries
              paste('base', 1:(interval_num*psc_tot), sep="") #baseline deliveries            
  )
  write.row(header)
  
  #print the initialised values (iteration = 0)
  write.row(c("0", rep("NA",times=7),
              mus,
              sigmas,
              rep(0,interval_num*psc_tot),
              rep(0,interval_num*psc_tot),
              dv_delv_base
  ))
  
  #################################### MAIN LOOP ######################################
  
  # while (ifelse(t<epsNum, TRUE, !all(abs(z_quantile[t-seq(0,length=epsNum)] - z_quantile[t]) <= epsErr)) && (t < maxIterations))
  # {   # @@@
  
  while (t <= maxIterations){

    dv_SPinitial <- mus[1:psc_tot]
    dv_SPlower   <- mus[1:psc_tot + psc_tot]
    dv_SPupper   <- mus[1:psc_tot + 2*psc_tot]
    source(paste(Rcode_path,"main_sim.R",sep=sep_), local=TRUE)
    
    # only calculate emer/canc if options.dv == 3
    if (options.dv == 3){
      
      # next 2 lines must go together!! and in that order!!
      mode <- "mu"
      source(paste(Rcode_path,"Calc_EmerOrCanc.R",sep=sep_), local=TRUE)
    }
    
    Z_mus <- sum(obj_func())
    
    # export results of algorithm iteration (t) to .csv
    write.row(c(t, CM_sim_settings()$SEED, Z_mus,obj_func(), z_quantile[t], mus, sigmas, unlist(delv_emer), unlist(delv_canc), unlist(dv_delv)))
    
    # only store each sorted population is interested in calculating the half.width. (OTHERWISE IGNORE)
    if (option.halfwidth==TRUE){
      write.csv(Z_x_sorted, file = paste(optPath,"\\Z_x_sorted", t, ".csv",sep=''))  
    }
    
    # increment algorithm iteration counter
    t <- t+1
  }
  
  ############################ END #################################
  
  #did the algorithm converge or were the max iterations reached?
#   if (ifelse(t<epsNum, TRUE, !all(abs(z_quantile[t-seq(0,length=epsNum)] - z_quantile[t]) <= epsErr))) {
#     print("Maximum number of iterations reached. Did not converge.")
#   }else{
#     print(paste("Winner winner chicken dinner. Successfully converged (to ",Z_mus, ")", sep=""))
#   }
  
  # display the time taken to run algorithm
  toc <- Sys.time() #end stopwatch
  print(toc-tic)
  
  # create a pop up dialog
  winDialog("ok", paste("Point estimator completed in ",round(print(toc-tic),1),units(toc-tic), sep=""))
    
}


