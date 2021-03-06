################################################# SETTINGS
sink()
sink()
sink()
cat("\014") #clear console
rm(list = ls()) #clear global environment

###### Make sure these R packages are installed
library(lubridate)
library(ggplot2)
library(reshape2)
library(zoo)
library(reshape2)

###settings

maxIterations <- 1
N <- 1
fp_set <- 5

###### START STOPWATCH
tic <- Sys.time() #begin stopwatch

###### FILE PATHS USED IN OPTIMISER
## !!Adjust these paths to the folder where EFS is running!!
## First Start DIAS then Run this in RStudio
if (fp_set == 0){
  Rcode_path  <- file.path("H:\\R code - Marc\\thss") #where to source Rcode
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
}else if(fp_set == 1){
  Rcode_path  <- file.path("C:\\Users\\17878551\\Desktop\\EFS APP\\Rcode") #where to source Rcode
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
}else if(fp_set == 2){
  Rcode_path  <- file.path("H:\\R code - Marc2") #where to source Rcode
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
}else if(fp_set == 3){
  Rcode_path  <- file.path("H:\\R code - Marc3") #where to source Rcode
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
}else if(fp_set == 4){
  Rcode_path  <- file.path("H:\\R code - Marc4") #where to source Rcode
  THEPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\17878551\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
}else if(fp_set == 5){
  Rcode_path  <- file.path("C:\\Users\\MarcHatton\\Desktop\\EFS APP\\Rcode") #where to source Rcode
  THEPATH  <-  "C:\\Users\\MarcHatton\\Desktop\\EFS APP"
  THEDBPATH  <-  "C:\\Users\\MarcHatton\\Desktop\\EFS APP\\e-breadboard\\resources\\za.co.enerweb_energy-flow-simulator3-var\\dbs" 
  print(fp_set)
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

###### set variable for the character to be used as a separator in paste(...,sep=sep_). Dependant on Operating System.
sep_ <- .Platform$file.sep #for the sake of laziness

###### Range for reading to and writing from the database
#Define the startdate and enddate range, for reading from and writing to the database
startdate <- as.POSIXct('2013-08-01')
enddate <- as.POSIXct('2014-03-01')   
interval <- 'month' #Month
if (interval=='month'){
  interval_num  <- round((as.yearmon(enddate) - as.yearmon(startdate))*12) + 1
}else if (interval=='month'){
  interval_num <- enddate - startdate + 1
}
dates <- seq(startdate,enddate,interval)

optPath <- file.path(paste(THEPATH,"CSPS_optimiser_output",sep=sep_)) 
#optimiser estimate path. Used for baseline delivery.
optEstPath <- file.path(paste(optPath, "estimates",sep=sep_))

###### create directories to store results
#create optimser directory
dir.create(optPath, showWarnings = FALSE) 
#create optimser estimate directory
dir.create(optEstPath, showWarnings = FALSE)

compare.path <- paste(optPath, "final-results", "compare-last-iter", sep=sep_)
dir.create(compare.path, showWarnings = FALSE)

dates.formatted <- format(dates, "%Y-%m")
psc_tot <- 14
# SPday.ave <- c(17.37026, 14.59808, 25.62025, 10.94664, 17.03563, 51.92641, 39.03720, 43.67920,  9.14883, 11.85286, 37.52245, 30.37924, 27.31237, 10.00592) #@

###### estimator names
est_names <- c("est_delvin", "est_delvout", "est_burnin", "est_burnout")

###### Use estimator's ave burnout to set delvin (baseline deliveries). Only set in the beginning, doesnt change thereafter. 
est_ave_burnout <- read.csv(paste(paste(optEstPath, est_names[4], sep=sep_) ,".csv",sep=""), 
                            header = TRUE, sep = ",", quote = "\"", dec = ".", 
                            fill = TRUE, comment.char = "")
est_ave_burnout[,1] <- NULL # clean dataframe
est_ave_burnout <- apply(est_ave_burnout,2,mean)
dv_delv_base <- est_ave_burnout
dv_delv <- data.frame(matrix(rep(NA, 14*8), ncol=14, nrow=8))
dv_delv[,]  <- dv_delv_base

days.sim_range <- sum(days_in_month(dates))
SPday.ave <- as.numeric(apply(dv_delv,2,sum)/days.sim_range)

dv_SPinitial <- SPday.ave*100 

############################################## MAIN

confidential=FALSE

filename <- paste("pem.csv", sep="")

graphname <- "pem-"


results <- read.csv(text=readLines(paste(optEstPath, "/", filename, sep=sep_))[-1])
results <- results[-1,] #remove first row (all the initialised values)
row.names(results) <- results[,1]
results <- results[,-2] # remove first 2 columns

ts <- nrow(results)

results <- results[,428:ncol(results)]
results["Iteration"] <- 1:ts
results.sp <- results[,c(1:112,ncol(results))]
results.delv <- results[,c(1:112 + 112,ncol(results))]
results.burn <- results[,c(1:112 +112+112,ncol(results))]

results.sp <- melt(results.sp, id.vars="Iteration")
results.delv <- melt(results.delv, id.vars="Iteration")
results.burn <- melt(results.burn, id.vars="Iteration")

if (confidential==FALSE){
  ps.names <- c("Arnot", "Camden", "Duvha", "Grootvlei", "Hendrina", "Kendal", "Komati", 
                "Kriel_OC", "Kriel_UG", "Majuba", "Matimba", "Matla", "Tutuka", "Lethabo")
}else if (confidential==TRUE){
  ps.names <- LETTERS[1:psc_tot]
}

results.sp["Powerstation"] <- rep(rep(ps.names, each=interval_num), each=ts)
results.sp["Month"] <- rep((rep(dates, each=ts)), times=psc_tot)
results.sp$variable <- NULL
results.delv["Powerstation"] <- rep(rep(ps.names, each=interval_num), each=ts)
results.delv["Month"] <- rep((rep(dates, each=ts)), times=psc_tot)
results.delv$variable <- NULL
results.burn["Powerstation"] <- rep(rep(ps.names, each=interval_num), each=ts)
results.burn["Month"] <- rep((rep(dates, each=ts)), times=psc_tot)
results.burn$variable <- NULL

results.sp <- rbind(results.sp, 
                    data.frame(Iteration=rep(1:ts, times=psc_tot),
                               Powerstation=rep(ps.names, each=ts),
                               Month=rep(rep(dates[1]-months(1), 
                                             times=ts), times=psc_tot),
                               value=rep(SPday.ave*100, each=ts)
                               )) 

results.sp_wide <- dcast(results.sp, Powerstation + Iteration ~ Month)

results.sp_wide1 <- results.sp_wide[,-11]
colnames(results.sp_wide1) <- colnames(results.sp_wide)[-3]
results.sp_wide2 <- results.sp_wide[,-3]

results.sp_dif <- cbind(results.sp_wide[,1:2] ,
                        -(results.sp_wide[,1:interval_num +2] 
                          - results.sp_wide[,1:interval_num +3])
                        )

results.sp_dif_long <- melt(results.sp_dif, id.vars=c("Powerstation", "Iteration"))


##des
p.mus.des <- ggplot(data=results.sp_dif, aes(x=Iteration, y=Desired, colour=Powerstation)) + 
  geom_line() +
  geom_point(aes(shape=Powerstation),
             fill = "white",    
             size = 2)  +       
  scale_shape_manual(values=(1:psc_tot -1)) +
  ylab("Target (stockpile days)") +
  scale_y_continuous(#limit=c(0,max(results.mus$Desired)), 
    breaks=seq(0, max(results.mus$Desired), by=2)) +  
  scale_x_continuous(breaks=seq(0, 100, length.out=11)) +
  theme_bw()
p.mus.des
ggsave(file=paste(optEstPath,"\\", graphname, "mus-des.pdf",sep=""),height=6,width=9)



p.results.emer <- ggplot(results.emercanc_last[, c(1,2,3)], aes(x=Month, y=Emer)) + 
  geom_bar(colour="black", stat="identity") +
  facet_wrap( ~ Powerstation, ncol=3) +
  ylab("Stockpile days") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.4))
p.results.emer
ggsave(file=paste(optEstPath,"\\", graphname, "final-emer", ".pdf",sep=""),height=9,width=6)
ggsave(file=paste(compare.path,"\\", "final-emer-", graphname, ".pdf",sep=""),height=9,width=6)

