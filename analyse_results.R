################################################# SETTINGS
sink()
sink()
sink()
cat("\014") #clear console
rm(list = ls()) #clear global environment

maxIterations <- 1
N <- 1
fp_set <- 6

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


###### Make sure these R packages are installed
library(lubridate)
library(ggplot2)
library(reshape2)
library(zoo)


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


psc_tot <- 14



############################################################ MAIN

Analyse.Results <- function(res.choose=1, confidential=FALSE){
  ###### results - analyse
#   if (res.choose == 1){
#     filename <- "CEM_results1.csv"
#     title_ <- paste("Powerstation = 1.  Decision variable = desired SP", sep="")  
#     graphname <- "ps1-dv1_"
#   }else if (res.choose == 2){
#     filename <- "CEM_results2.csv"
#     title_ <- paste("Powerstation = 14.  Decision variable= desired SP", sep="")  
#     graphname <- "ps14-dv1_"
#   } else if (res.choose == 3){
#     filename <- "CEM_results3.csv"
#     title_ <- paste("Powerstation = 1.  Decision variables = LWL, desired SP, UWL", sep="")  
#     graphname <- "ps1-dv3_"
#   } else if (res.choose == 4){
#     filename <- "CEM_results4.csv"
#     title_ <- paste("Powerstation = 14.  Decision variables = LWL, desired SP, UWL", sep="")  
#     graphname <- "ps14-dv3_"
#   } 
  
  sensivity.costs <- data.frame(ec=c(rep(c(1.75,0.75),4) , rep(1.25,4)),
                                cc=c(rep(c(0.8,0.2),times=2, each=2) , rep(0.5,4)),
                                hc=c(rep(c(0.0875,0.0775), each=4) , rep(0.0825,4))
  ) 
  
  experiments <- c(paste("s",1:8,sep=""),
                   "b1","b2",
                   "5p","95p")
  filename <- paste(experiments[res.choose], ".csv", sep="")
  
  FRpath <- paste(optPath, "final-results", experiments[res.choose], sep=sep_)
  
  title_ <- paste("ec=", sensivity.costs$ec[res.choose], 
                  ". cc=", sensivity.costs$cc[res.choose], 
                  ". hc=", sensivity.costs$hc[res.choose],
                  ".", sep="")
  graphname <- experiments[res.choose]
    
  parameters_ <- read.csv(text=readLines(paste(FRpath, "/", filename, sep=sep_))[1:8], header=F)[,1:2]
  options.ps2 <- as.vector(parameters_$V2)[2]
  options.ps2 <- ifelse(options.ps2=="all", options.ps2, as.numeric(options.ps2))
  options.dv2 <- as.numeric(as.vector(parameters_$V2)[3])
  options.eval2 <- as.numeric(as.vector(parameters_$V2)[4])
  
  results <- read.csv(text=readLines(paste(FRpath, "/", filename, sep=sep_))[-(1:9)])
  results <- results[-1,] #remove first row (all the initialised values)
  row.names(results) <- results[,1]
  results <- results[,-2] # remove first 2 columns
  
  # dec.var <- ifelse(options.dv2==1, "DES", 
  #                   ifelse(options.dv2==3, "LWL, DES & UWL", NA))
  ts <- results[nrow(results), 1]
  
  if (confidential==FALSE){
    ps.names <- c("Arnot", "Camden", "Duvha", "Grootvlei", "Hendrina", "Kendal", "Komati", 
                  "Kriel_OC", "Kriel_UG", "Majuba", "Matimba", "Matla", "Tutuka", "Lethabo")
  }else if (confidential==TRUE){
    ps.names <- LETTERS[1:psc_tot]
  }
  
  
  results.costs <- results[, c(1, 2:7)]
  colnames(results.costs) <- c("Iteration", "Overall.mu", "Holding", 
                               "Shortage", "Emergency", "Cancellation", "Overall.quantile")
  if (options.dv2==1){
    results.costs <- results.costs[, -c(5,6)]
  }
  
  
  results.mus <- data.frame(Iteration=rep(results[,1],psc_tot))
  results.mus["Desired"] <- melt(results[, c(1:14 +7)], id.vars=)[,2]
  results.mus["LWL"] <- melt(results[, c(1:14 +7+14)])[,2]
  results.mus["UWL"] <- melt(results[, c(1:14 +7+14+14)])[,2]
  results.mus["Powerstation"] <- rep(ps.names, 
                                     each=ts)
  
  results.sigmas <- data.frame(Iteration=rep(results[,1],psc_tot))
  results.sigmas["Desired"] <- melt(results[, c(1:14 +7+42)])[,2]
  results.sigmas["LWL"] <- melt(results[, c(1:14 +7+14+42)])[,2]
  results.sigmas["UWL"] <- melt(results[, c(1:14 +7+14+14+42)])[,2]
  results.sigmas["Powerstation"] <- rep(ps.names, 
                                        each=ts)
  
  results.emer <- data.frame(Iteration=results[,1])
  for (i in 1:14){
    results.emer[ps.names[i]] <- rowSums(results[ ,c(7+42+42 + ((i-1)*8 + 1):(i*8)) ])
  }
  
  results.canc <- data.frame(Iteration=results[,1])
  for (i in 1:14){
    results.canc[ps.names[i]] <- rowSums(results[ ,c(7+42+42 + 14*8 + ((i-1)*8 + 1):(i*8)) ])
  } 
  

  results.emercanc_last <- data.frame(Powerstation = rep(ps.names, each=8),
                                      Month = rep(1:8, 14),
                                      Emer = as.numeric(results[nrow(results) ,c(7+42+42 + 1:(14*8)) ]),
                                      Canc = as.numeric(results[nrow(results) ,c(7+42+42 + 14*8 + 1:(14*8)) ]) )
                                    
  
  
  #only use specified functions
  if (options.ps2!="all"){
    results.mus <- results.mus[results.mus$Powerstation==ps.names[options.ps2], ]
    results.sigmas <- results.sigmas[results.sigmas$Powerstation==ps.names[options.ps2], ]
  }
  
  ###mus
  head(results.mus)
  
  ##des
  p.mus.des <- ggplot(data=results.mus[, -c(3,4)], aes(x=Iteration, y=Desired, colour=Powerstation)) + 
    geom_line() +
    geom_point(aes(shape=Powerstation),
               fill = "white",    
               size = 2)  +       
    scale_shape_manual(values=(1:psc_tot -1)) +
    ylab("Target (ktons)") +
    scale_y_continuous(breaks=seq(0, 1000,50)) +  
    scale_x_continuous(breaks=seq(0, 100, 10)) 
  p.mus.des
  ggsave(file=paste(FRpath,"\\", graphname, "mus-des.pdf",sep=""),height=6,width=9)
  
  ##lwl
    p.mus.lwl <- ggplot(data=results.mus[, -c(2,4)], aes(x=Iteration, y=LWL, colour=Powerstation)) + 
      geom_line() +
      geom_point(aes(shape=Powerstation),
                 fill = "white",    
                 size = 2)  +       
      scale_shape_manual(values=(1:psc_tot -1)) +
      ylab("LWL (ktons)") +
      scale_y_continuous(breaks=seq(0, 1000,25)) + 
      scale_x_continuous(breaks=seq(0, 100, 10))
    p.mus.lwl
    ggsave(file=paste(FRpath,"\\", graphname, "mus-lwl.pdf",sep=""),height=6,width=9)

  
  ##uwl
    p.mus.uwl <- ggplot(data=results.mus[, -c(2,3)], aes(x=Iteration, y=UWL, colour=Powerstation)) + 
      geom_line() +
      geom_point(aes(shape=Powerstation),
                 fill = "white",    
                 size = 2)  +       
      scale_shape_manual(values=(1:psc_tot -1)) +
      scale_y_continuous(breaks=seq(0, 2000, 100)) + 
      scale_x_continuous(breaks=seq(0, 100, 10)) + 
      ylab("UWL (ktons)") 
    p.mus.uwl
    ggsave(file=paste(FRpath,"\\", graphname, "mus-uwl.pdf",sep=""),height=6,width=9)
  
  
  ###sigmas
  head(results.sigmas)
  
  ##des
  p.sigmas.des <- ggplot(data=results.sigmas[, -c(3,4)], aes(x=Iteration, y=Desired, colour=Powerstation)) + 
    geom_line() +
    geom_point(aes(shape=Powerstation),
               fill = "white",    
               size = 2)  +       
    scale_shape_manual(values=(1:psc_tot -1)) +
    scale_y_continuous(breaks=seq(0, 2000, 25)) + 
    scale_x_continuous(breaks=seq(0, 100, 10)) + 
    ylab("Target (ktons)") 
  p.sigmas.des
  ggsave(file=paste(FRpath,"\\", graphname, "sigmas-des.pdf",sep=""),height=6,width=9)
  
  ##lwl
    p.sigmas.lwl <- ggplot(data=results.sigmas[, -c(2,4)], aes(x=Iteration, y=LWL, colour=Powerstation)) + 
      geom_line() +
      geom_point(aes(shape=Powerstation),
                 fill = "white",    
                 size = 2)  +       
      scale_shape_manual(values=(1:psc_tot -1)) +
      scale_y_continuous(breaks=seq(0, 2000, 25)) + 
      scale_x_continuous(breaks=seq(0, 100, 10)) + 
      ylab("LWL (ktons)") 
    p.sigmas.lwl
    ggsave(file=paste(FRpath,"\\", graphname, "sigmas-lwl.pdf",sep=""),height=6,width=9)
  
  
  ##uwl
    p.sigmas.uwl <- ggplot(data=results.sigmas[, -c(2,3)], aes(x=Iteration, y=UWL, colour=Powerstation)) + 
      geom_line() +
      geom_point(aes(shape=Powerstation),
                 fill = "white",    
                 size = 2)  +       
      scale_shape_manual(values=(1:psc_tot -1)) +
      scale_y_continuous(breaks=seq(0, 2000, 25)) + 
      scale_x_continuous(breaks=seq(0, 100, 10)) + 
      ylab("UWL (ktons)") 
    p.sigmas.uwl
    ggsave(file=paste(FRpath,"\\", graphname, "sigmas-uwl.pdf",sep=""),height=6,width=9)
  
  
  
  ###plot stockpile ribbon function
  Stockpile.Ribbon <- function(ps_chosen=1){
    # #create custom palette
    #myColors <- colorRampPalette(brewer.pal(9,"Set1"))(psc_tot)
    #names(myColors) <- levels(ps.names)
    #colScale <- scale_colour_manual(name = "Powerstation",values = myColors)
    
    ps_chosen.name <- ps.names[ps_chosen]
    results.mus.chosen <- results.mus[results.mus[,5]==ps_chosen.name, ]
    head(results.mus)
    
    p.mus.chosen <- ggplot(data=results.mus.chosen, aes(x=Iteration, y=Desired, ymin=LWL, ymax=UWL)) + 
      geom_line() +
      geom_ribbon(alpha=0.6) +
      geom_point(fill = "white",    
                 size = 2)  +       
      scale_shape_manual(values=(1:psc_tot -1)) + 
      scale_y_continuous(breaks=seq(0, 2000, 50)) + 
      scale_x_continuous(breaks=seq(0, 100, 10)) + 
      ylab("Stockpile level (ktons)") 
  
    p.mus.chosen
    ggsave(file=paste(FRpath,"\\", graphname, "stockpile.ribbon-", ps_chosen.name, ".pdf",sep=""),height=6,width=9)
  }
  
  ###loop through stockpile ribbon function
  if ((options.ps2>0) && (options.ps2<=psc_tot)){
    Stockpile.Ribbon(options.ps2)
  }else if(options.ps2=="all"){
    draw.count <- 0
    while (draw.count<psc_tot){
      draw.count <- draw.count+1
      Stockpile.Ribbon(draw.count)
    }
  }
  
  results.costs <- melt(results.costs, id.vars="Iteration")
  colnames(results.costs) <- c("Iteration", "Cost", "value")
  
  p.costs.all <- ggplot(data=results.costs, aes(x=Iteration, y=value, colour=Cost)) + 
    geom_line() +
    geom_point(aes(shape=Cost),
               fill = "white",    
               size = 2)  +       
    scale_shape_manual(values=(1:length(levels(results.costs$Cost)) -1))
  p.costs.all
  ggsave(file=paste(FRpath,"\\", graphname, "costs-all.pdf",sep=""),height=6,width=9)
  
  p.costs.quan <- ggplot(data=results.costs[results.costs["Cost"]=="Overall.quantile",], aes(x=Iteration, y=value)) + 
    geom_line() +
    geom_point()
  p.costs.quan
  ggsave(file=paste(FRpath,"\\", graphname, "costs-Zquan.pdf",sep=""),height=6,width=9)
  
  #@@
  results.costs["cost.x10.6"] <- results.costs$value/1000000
  p.costs.mu <- ggplot(data=results.costs[results.costs["Cost"]=="Overall.mu",], aes(x=Iteration, y=cost.x10.6)) + 
    geom_line() +
    geom_point(size=3) +
    xlab("Iteration") +
    ylab("Rands (million) x 10^9") +
    scale_y_continuous(breaks=seq(0, (max(results.costs$cost.x10.6)+100),100), limits=c(0,max(results.costs["cost.x10.6"])))
  p.costs.mu
  ggsave(file=paste(FRpath,"\\", graphname, "costs-Zmu.pdf",sep=""),height=6,width=9)
  
  SP1day.ave2 <- c(17.37026, 14.59808, 25.62025, 10.94664, 17.03563, 51.92641, 39.03720, 43.67920,  9.14883, 11.85286, 37.52245, 30.37924, 27.31237, 10.00592)
  
  ## plot last iteration
  iter.last <- max(results.mus$Iteration)
  results_SPdays.iter.last <- results.mus[results.mus$Iteration==iter.last, ]
  results_SPdays.iter.last[, 2:4] <- results_SPdays.iter.last[, 2:4] / SP1day.ave2 #*1.2 +10 #@@
  
  p.mus.chosen <- ggplot(results_SPdays.iter.last, aes(x=Powerstation)) + 
         geom_boxplot(aes(lower=LWL, 
                          upper=UWL, 
                          middle=Desired,
                          ymin=LWL,
                          ymax=UWL), stat="identity", width=0.6) +
    scale_y_continuous(breaks=seq(0, 50, 5), limits=c(0,50)) + 
    ylab("Stockpile level (days)") 
#   +
#     theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.4), axis.title.x=element_blank(), axis.title.y=element_blank())
     
  p.mus.chosen
  ggsave(file=paste(FRpath,"\\", graphname, "final-results", ".pdf",sep=""),height=6,width=9)
#   
# 
#   results.emer2 <- melt(results.emer, id.vars="Iteration")
#   colnames(results.emer2) <- c("Iteration", "Powerstation", "Emer")
# 
#   results.canc2 <- melt(results.canc, id.vars="Iteration")
#   colnames(results.canc2) <- c("Iteration", "Powerstation", "Canc")
# 
#   results.emercanc <- merge(results.emer2,results.canc2)



p.results.emer <- ggplot(results.emercanc_last[, c(1,2,3)], aes(x=Month, y=Emer)) + 
  geom_bar(colour="black", stat="identity") +
  facet_wrap( ~ Powerstation, ncol=4)
p.results.emer
ggsave(file=paste(FRpath,"\\", graphname, "final-emer", ".pdf",sep=""),height=6,width=9)


p.results.canc <- ggplot(results.emercanc_last[, c(1,2,4)], aes(x=Month, y=Canc)) + 
  geom_bar(colour="black", stat="identity") +
  facet_wrap( ~ Powerstation, ncol=4)
p.results.canc
ggsave(file=paste(FRpath,"\\", graphname, "final-canc", ".pdf",sep=""),height=6,width=9)

}


Analyse.Results(1)
Analyse.Results(2)
Analyse.Results(3)
Analyse.Results(4)
Analyse.Results(5)
Analyse.Results(6)
Analyse.Results(7)
Analyse.Results(8)
Analyse.Results(9)
Analyse.Results(10)
# Analyse.Results(11)
# Analyse.Results(12)




# Analyse.Results(1)
# Analyse.Results(2)
# Analyse.Results(3)
# Analyse.Results(4)
