# Anotated Code - Two documents in R


# PlotImmigResults.R -- FILE
#
# Make plots for Hill Hopkins Huber demographics paper.
#

rm(list=ls())
if (.Platform$OS == "windows") {
  
  # Set working directory in location of script.
  
  .doit <- function() { 
    
    # only works with R.exe; trap errors if using Rscript.exe
    
    f_f <- lapply(sys.frames(),function(x) x$ofile);
    f_f <- Filter(Negate(is.null),f_f) ; 
    PTH <- dirname(f_f[[length(f_f)]]); setwd(PTH) ; rm(PTH,f_f)
  }
  try(.doit(),silent=T)
}

# I think the first part of this code is setting up the computer and the working
# environment. I'm not sure what function x or x$ofile is, but it appears it is
# meant to be done in "silence" given the silent = TRUE. May need to look at
# this part with Preceptor and Alice to ensure I know what exactly it is doing.

if (!"bit64" %in% installed.packages()[, 1]) {
  install.packages("bit64")
}
library(bit64)
if (!"data.table" %in% installed.packages()[, 1]) {
  install.packages("data.table")
}
library(data.table)
options(stringsAsFactors=F)
library(RColorBrewer)
palette(brewer.pal(n=9,name="Set1")[c(1:5,7:9)]) 

# reset default colors

options(digits=4)


# This short loop indicated that if the libraries mentioned are not already in
# installed packages, then it should install them. After that, it loads the
# libraries necessary for the data analysis.
-----
  
  
# Scatter plots of change in GOP share on change in Hispanic population,
# variously measured.


# Outsheeted from AnalyzePooledPrecintLevelFiles.do
  
  # This piece of code appears to bring in data from stata and create a plot.
  # The plot seems to be fairly simple and it is for figure 1 in the paper.
  # Figure one plots show the change in Hispanic population share against change
  # in GOP share as well as the proportional change in Hispanic population
  # against GOP share. Points are random samples of 2,000 precincts. Loess lines
  # are generated from all observations. Points are shaded corresponding to
  # density, with darker colors indicating more precincts.
  
DT = fread("Figure01DataForR.csv")
.myPlot <- function(x,y,n.points=2e03,ylim=c(-.4,.4),...) {
  
  # Plot n.points sample of points.
  
  samp = sample(seq_len(length(x)),size=n.points)
  
  # Make the scatter as we like it. -- This was their comment and it made me
  # laugh!
  
  plot(x=x[samp],y=y[samp],type='n',axes=F,ylim=ylim,...)
  grid();axis(2,las=2);axis(1)
  points(x=x[samp],y=y[samp],col=rgb(0,0,0,alpha=.2),pch=19)
  
  # Smoother on interior 90% of data.
  #int.90 = x <= quantile(x,.95) & x >= quantile(x,.05)
  #lines(loess.smooth(y=y[int.90],x=x[int.90],span=.2),lwd=3,col=3,...)
  # Truncate top 5%.
  #int.90 = x <= quantile(x,.95) & x >= quantile(x,.05)
  
  lines(loess.smooth(y=y,x=x,span=.2),lwd=3,col=3)
}

# This is not our typical gov1005 kind of plot making, however, bringing a data
# file from stata, the authors create a function, indicate the sample they want,
# plot the function, and then edit the aesthetics of the grid and points.I may
# need to further study some of these commands.

# Here they create the (confidence) interval that they wish to show on their
# graph. They create it via a function with quantile commands inside.

int.90 <- function(x) {
  
  # Return boolean for data in the interior 90% of data.
  
  x <= quantile(x,.95,na.rm=T) & x >= quantile(x,.05,na.rm=T)
  
  # This specific part inside the function finds the 90% confidence interval.
  # They created a function to output the 90% interval
  
}



fname = "Figure01-BaseScatters"
pdf(sprintf("Figures/%s.pdf",fname),width=9,height=6)
par.old <- par(mar=c(4.1,4.1,1.1,1.1),cex.lab=1.3)

# This code provides instructions for printing the figure to PDF and specifies
# its presentation.

# The following chunks graphs the 4 plots of the 90% interior/confidence
# interval of the change in hispanic share of the population v. change in GOP
# share as well as proportional change of hispanic share v. change in GOP share
# over 2000-2016 & 2011-2016 for both measures of hispanic presence.

# interior 90% of data, no log scale
# On d1611.

DT[int.90(d1611_hispanic),.myPlot(x=d1611_hispanic,y=gop_propvote_change,
                                  ylab="Change in GOP share, 2012 to 2016",
                                  xlab="Change in population share Hispanic, 2011 to 2016")]

# On d1600.

DT[int.90(d1600_hispanic),.myPlot(x=d1600_hispanic,y=gop_propvote_change,
                                  ylab="Change in GOP share, 2012 to 2016",
                                  xlab="Change in population share Hispanic, 2000 to 2016")]
# interion 90% of data
# On dprop1611.

DT[int.90(dprop1611_hispanic_notopcode),.myPlot(x=dprop1611_hispanic_notopcode,y=gop_propvote_change,
                                                ylab="Change in GOP share, 2012 to 2016",
                                                xlab="Proportional change in population Hispanic, 2011 to 2016")]
# On dprop1600.

DT[int.90(dprop1600_hispanic_notopcode),.myPlot(x=dprop1600_hispanic_notopcode,y=gop_propvote_change,
                                                ylab="Change in GOP share, 2012 to 2016",
                                                xlab="Proportional change in population Hispanic, 2000 to 2016")]
dev.off()



# Coefplot of effect of changing Hispanic population
# on change in Republican vote share, 2012 to 2016.

# Coefficients from AnalyzePooledPrecintLevelFiles.do

# This code creates table 1 of the paper. It shows change in Republican vote
# share 2012 to 2016 and change in Hispanic population, various time intervals.
# Also from .do file.Robust standard errors are in parentheses. *P < 0.05; **P <
# 0.01. Precinct-level analysis; weighted to number of votes 2012; proportional
# changes top and bottom coded at 1 and −1. Note: Dependent variable is change
# in GOP vote share, 2012 to 2016. Prop., proportion

coefs = fread("Tables/Table01_WeightedFullSample_summaryresultstograph.csv")
.makeCoefVars <- function(coefs,proportional.x10=TRUE) {
  
  # Make variables needed for .coefPlot.
  # Arguments.
  #  coefs -- data.table of coefficients
  #  proportional.x10 -- multiple proportional coefs by 10 for scale
  
  
  # Calculate ends of CIs.
  
  coefs[,lb := m_beta - 1.96*m_se]
  coefs[,ub := m_beta + 1.96*m_se]
  
  
  # Sort on order of coefficients.
 
   setkey(coefs,m_beta)
  
  
  # Drop changes 2000 to 2011.
  
  coefs = coefs[regexpr("2011 - 2000",m_iv) == -1,]
  
  
  # Identify changes 2011 to 2016 vs 2000 to 2016.
  
  coefs[,from.2000 := regexpr("2000",m_iv) != -1]
  
  
  # Identify proportion vs levels.
  
  coefs[,proportional := regexpr("^Prop",m_iv) != -1]
  
  
  # Create pchs - type of statistical analysis - wasn't able to find a
  # definitive definition. Should go back and figure it out with Alice or
  # Preceptor.
  
  pchs = unique(coefs[,c("from.2000","proportional")])
  pchs[,pch := c(12,8,15,19)]
  coefs = merge(coefs,pchs,by=c("from.2000","proportional"))
  
  
  # Create numeric version of m_modeltitle (to use as column name to show the
  # values for each model).
  
  coefs[,m_modeltitle_num := as.numeric(as.factor(m_modeltitle))]
  if (proportional.x10) {
  
      # Multiply proportional coefs by 10.
    
    coefs[proportional==T,m_beta := m_beta*10]
    coefs[proportional==T,m_se := m_se*10]
    coefs[proportional==T,lb := lb*10]
    coefs[proportional==T,ub := ub*10]
  }
  
  # Note whether or not coefs have been multiplied by 10.
  
  coefs[,proportional.x10 := proportional.x10]
  
  # Sort on model order.
  
  setkey(coefs,m_modeltitle_num,proportional,from.2000)
  return(coefs)
}
coefs = .makeCoefVars(coefs)

.coefPlot <- function(coefs,fname=NULL,
                      xlab="Relationship between increasing Hispanic population and GOP vote share") {
  
  # Make a coefficient plot and write out model names.
  # Arguments.
  #  coefs -- data.table of coefficient estimates.
  #  fname -- file name for saving figure and notes text; when NULL, plots to screen
  #  xlab -- xlab for figure
  
  if (!is.null(fname)) { pdf(sprintf("Figures/%s.pdf",fname),width=10,height=6) }
  par.old <- par(mar=c(3.1,3.1,1.1,1.1),cex.lab=1.2)
  coefs[,plot(x=range(c(ub,lb,0.005)),y=c(1,.N),type='n',ann=F,axes=F)]
  grid(lwd=2);axis(1)
  abline(v=0,lty=2,lwd=2,col='gray')
  title(xlab=xlab, ylab="Model version",line=2)
  axis(2,las=2,labels=coefs[,m_modeltitle_num],at=coefs[,seq_len(.N)])
  
# This provide the aesthetics of the statistical coefficients summary table for
# the paper.
  
  # CI.
  
  coefs[,segments(x0=lb,x1=ub,y0=seq_len(.N))]
  
  # Point estimate.
  
  coefs[,points(x=m_beta,y=seq_len(.N),pch=pch,cex=1.5)]
  
  # Legend for point types.
 
   pchs = unique(coefs[,c("from.2000","proportional","proportional.x10","pch")])  
  pchs[,legend := sprintf("%s, %s to 2016",
                          ifelse(proportional,
                              ifelse(proportional.x10,"Proportional change/10","Proportional change"), "Change in levels"),
                          ifelse(from.2000,"2000","2011"))]
  pchs[,legend('topleft',legend=legend,pch=pch,bg='white',pt.cex=1.5)]
  par(par.old)
  if (!is.null(fname)) { dev.off() }
  
  if (!is.null(fname)) { 
    
    # Write out to text a note mapping model code to 
    # model name.
    
    mods = unique(coefs[,c("m_modeltitle_num","m_modeltitle")][order(m_modeltitle_num)])
    mods[,txt := sprintf("(%s) %s",m_modeltitle_num,m_modeltitle)]
    mods[,txt := gsub("Republican","GOP",txt)]
    mods[,txt := gsub("Other Changes","Demographics",txt)]
    
    # Write out note.
    
    write(paste(mods[,txt],collapse="; "),file=sprintf("Figures/%s-Notes.txt",fname))
  }
}

# Make plot.

.coefPlot(coefs,fname="Figure02-CoefficientVariation")


# Variation in magnitude of coefficient relating change in Hispanic population
# to change in Republican vote share by model specification and time interval.
# Note: The figure demonstrates that in no specification or time interval does
# change in Hispanic population benefit Republican presidential vote. Each point
# is the coefficient estimate from that model with lines showing 95% CIs.
# Proportional changes are divided by 10 to scale with changes in levels. Model
# numbers on the y axis correspond to varying model specifications.



# Coefplot of effect of changing Non-citizen Foreign-born population
# on change in Republican vote share, 2012 to 2016.

# Coefficients from AnalyzePooledPrecintLevelFiles.do

coefs = fread("Tables/AppendixTable07_ForeignBorn_summaryresultstograph.csv")
coefs = .makeCoefVars(coefs)

# Make plot.

.coefPlot(coefs,fname="FigureA01-CoefficientVariationNCFB",
          xlab="Relationship between increasing Non-citizen Foreign-born population and GOP vote share")


# This graph is not on my version of the PDF, but it is referenced in the paper
# itself to prove the point that the results are not caused by introduction of
# immigrants into the electorate, but rather a connection between exposure to
# immigrant communities and immigration attitudes.



## DescriptiveStatistics.R -- FILE



# PlotImmigResults.R

# Make descriptive statistics table for Hill Hopkins Huber demographics paper.


rm(list=ls())
if (.Platform$OS == "windows") {
  
  # Set working directory in location of script.
  
  .doit <- function() { 
    
    # only works with R.exe; trap errors if using Rscript.exe
    
    f_f <- lapply(sys.frames(), function(x) x$ofile);
    f_f <- Filter(Negate(is.null),f_f) ; 
    PTH <- dirname(f_f[[length(f_f)]]); 
    setwd(PTH) ; rm(PTH,f_f)
  }
  try(.doit(),silent=T)
}

library(xtable)
library(haven)

# This part begins the second file with additional computer and R setup.


dta <- read_dta("PrecinctData.dta")

colnames(dta) <- gsub("_", ".", colnames(dta))

# The data for precincts studied is loaded (from stata?) and the column names
# are changed for ease of use.


### make table of census descriptive stats ----

cn <- colnames(dta)[grep("l[01][016]", colnames(dta))]

rmat <- matrix(NA, length(cn), 7)
rownames(rmat) <- cn
colnames(rmat) <- c("FL", "GA", "MI", "NV", "OH", "PA", "WA")
for(i in 1:length(cn)) {
  rmat[i, 1] <- mean(dta[dta$st == "FL", cn[i]][[1]], na.rm = T)
  rmat[i, 2] <- mean(dta[dta$st == "GA", cn[i]][[1]], na.rm = T)
  rmat[i, 3] <- mean(dta[dta$st == "MI", cn[i]][[1]], na.rm = T)
  rmat[i, 4] <- mean(dta[dta$st == "NV", cn[i]][[1]], na.rm = T)
  rmat[i, 5] <- mean(dta[dta$st == "OH", cn[i]][[1]], na.rm = T)
  rmat[i, 6] <- mean(dta[dta$st == "PA", cn[i]][[1]], na.rm = T)
  rmat[i, 7] <- mean(dta[dta$st == "WA", cn[i]][[1]], na.rm = T)
}

# This is a loop and it appears to be creating a table of the average key census
# stats per state. I did not find this chart in the published reading, but it
# may be in the appendix, which for some reason was not included in the PDF I
# got from Hollis. I'm a bit unclear on how 'cn' got made and what it represents. 

rownames(rmat) <- c("Has BA or More `16", "Non-white, Non-Hisp. `16", 
                    "Hispanic `11", "Non-Cit. For. Born. `11", 
                    "Pct. Under Poverty Line `11", "Unemployed `11", 
                    "Pct. Empl. in Manufacturing `11", "Avg. Rent (1000s) `11", 
                    "Med. Grs. Rent / Hsh. Inc. `11", "Pct. Homes > $150 `11", 
                    "Pop. Density `11", "Non-Hisp. Black `11", 
                    "Has BA or More `11", "Non-white, Non-Hisp. `11", 
                    "Hispanic `00", "Non-Cit. For. Born `00", 
                    "Pct. Under Poverty Line `00", "Unemployed `00",
                    "Pct. Empl. in Manufacturing `00", "Pop. Density `00", 
                    "Non-Hisp. Black `00", "Has BA or More `00")
rmat <- rmat[c(22, 13, 1, 14, 2, 21, 12, 15, 3, 16, 4, 17, 5, 18, 6, 19, 7, 20, 11, 8, 9, 10),]

# This appears to be renaming rows based on census data imported above.

sink("Tables/DescriptiveStatisticsMeansByState.tex")
print(xtable(rmat))
sink()

sink("Tables/DescriptiveStatisticsMeansByState.txt")
print(round(rmat, 2))
sink()

#  These two small chunks appear to be two distinct formats for printing, but
#  I'm not sure what they result into.