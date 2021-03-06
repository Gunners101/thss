###### CLEAR PREVIOUS RUN 
sink()
sink()
sink()
cat("\014") #clear console
rm(list = ls()) #clear global environment

###### CHOOSE A FILEPATH - DIFFERENT FOR DIFFERENT COMPUTERS
fp_set <- .

###### FILE PATHS USED IN OPTIMISER
## !!Adjust these paths to the folder where EFS is running!!
## !!First Start DIAS then Run this in RStudio!!
if (fp_set == 0){
  Rcode_path  <- file.path("H:\\R code - Marc\\thss") 
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 1){
  Rcode_path  <- file.path("C:\\Users\\17878551\\Desktop\\EFS APP\\Rcode") 
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 2){
  Rcode_path  <- file.path("H:\\R code - Marc2") 
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 3){
  Rcode_path  <- file.path("H:\\R code - Marc3") 
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 4){
  Rcode_path  <- file.path("H:\\R code - Marc4") 
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 5){
  Rcode_path  <- file.path("C:\\Users\\MarcHatton\\Desktop\\EFS APP\\Rcode") 
  THEPATH  <-  "C:\\Users\\MarcHatton\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\MarcHatton\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 6){
  Rcode_path  <- file.path("C:\\Users\\15720314\\Desktop\\EFS APP\\Rcode") 
  THEPATH  <-  "C:\\Users\\15720314\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\15720314\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}else if(fp_set == 7){
  Rcode_path  <- file.path("C:\\Users\\17090792\\Desktop\\EFS APP\\Rcode") 
  THEPATH  <-  "C:\\Users\\17090792\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17090792\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
}


print(paste("Using computer",fp_set))
print(Rcode_path)
print(THEPATH)
print(THEDBPATH)

if (!(exists("Rcode_path") && exists("THEPATH") && exists("THEDBPATH"))) {
  stop("For the optimiser (and estimator) to work, filepaths must be set!") 
}

###### LOAD ESTIMATOR & OPTIMISER
source(paste(Rcode_path,"main_estimates.R", sep=.Platform$file.sep), local=TRUE)
source(paste(Rcode_path,"main_optimiser.R", sep=.Platform$file.sep), local=TRUE)
source(paste(Rcode_path,"point_estimator.R", sep=.Platform$file.sep), local=TRUE)
source(paste(Rcode_path,"main_pem.R", sep=.Platform$file.sep), local=TRUE)

#************* RUN OPTIMISER ******************
optimser.csps(out.stat=., d.scen=., load_shedding=., ls.id=.)
# optimser.csps(maxIterations=20, N=30)
# pem.csps(maxIterations=10, rand.seed=FALSE)
# optimser.csps(fp_set=1, maxIterations=2, N=2, options.ps=99, options.dv=3, options.eval=1, option.halfwidth=FALSE)
