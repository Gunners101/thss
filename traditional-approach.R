setwd("~/MEGA/Thesis/WriteUp/ORSSA2014/Presentation")
getwd()

library(ggplot2)
library(RColorBrewer)
library(extrafont)

# extrafont settings
loadfonts(quiet=TRUE)
Sys.setenv(R_GSCMD = "C:\\Program Files\\gs\\gs9.15\\bin\\gswin64c.exe") # Adjust the path to match your installation of Ghostscript

#colour blind palette
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")


ps.names <- LETTERS[1:14]

# traditional  <- data.frame(Powerstation=rep(ps.names,2), 
#                            StockpileDays=c(rep(20,14), rep(42,14)),
#                            Key=c(rep("Pre 2008", 14), rep("Post 2008", 14))
#   )
# 
# ggplot(data=traditional, aes(x=Powerstation, y=StockpileDays, fill=Key)) + 
#   geom_bar(stat="identity", width=0.6, position=position_dodge(width=0.7)) +
#   ylab("Stockpile Days") +
#   scale_x_discrete(limits=ps.names) +
#   scale_y_continuous(breaks=seq(0, 50, 5), limits=c(0,50)) +
#   scale_fill_discrete(breaks=c("Pre 2008", "Post 2008"))
# ggsave(file="Traditional-approach.pdf",height=6,width=9)
# 
# 
# 
# possible  <- data.frame(Powerstation=rep(ps.names), 
#                            StockpileDays=c(25,27,20,32,35,45,30,31,18,28,34,40,31,21)
#   )
# 
# ggplot(data=possible, aes(x=Powerstation, y=StockpileDays)) + 
#   geom_bar(stat="identity", position=position_dodge(width=0.7)) +
#   ylab("Stockpile Days") +
#   scale_x_discrete(limits=ps.names) +
#   scale_y_continuous(breaks=seq(0, 50, 5), limits=c(0,50)) 
# ggsave(file="possible-solution.pdf",height=6,width=9)


possible2  <- data.frame(Powerstation=rep(ps.names,3), 
                        StockpileDays=c(rep(20,14), rep(42,14), 
                                        25,27,16,32,35,45,12,31,18,28,34,40,31,21),
                        Key=c(rep("Pre 2008", 14), rep("Post 2008", 14), rep("Possible solution",14)))


ggplot(data=possible2, aes(x=Powerstation, y=StockpileDays, fill=Key)) + 
  geom_bar(stat="identity", width=0.6, position=position_dodge(width=0.7)) +
  ylab("Stockpile days") +
  xlab("Coal-fired power station") +
  scale_x_discrete(limits=ps.names) +
  scale_y_continuous(breaks=seq(0, 50, 5), limits=c(0,50)) +
  theme_bw() +
  scale_fill_manual(values=cbPalette[c(8,3,4)],
                    name="Policy", breaks=c("Pre 2008", "Post 2008", "Possible solution")) +
  theme(text = element_text(size=20, family="CM Roman"))
ggsave(file="possible-solution2.pdf",height=6,width=10) 
embed_fonts("possible-solution2.pdf")
