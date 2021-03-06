% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GatesSimes.R
\name{GatesSimes}
\alias{GatesSimes}
\title{GATES-Simes test for single trait - pathway association.}
\usage{
GatesSimes(pvec, ldmatrix, snp.info, gene.info)
}
\arguments{
\item{pvec}{p-values for each SNP.}

\item{ldmatrix}{numeric. A correlation matrix of SNPs with dimensions matching the length of pvec (the number of SNPs).}

\item{snp.info}{SNP information matrix, the 1st column is SNP id, 2nd column is chromosome #, 3rd column indicates SNP location.}

\item{gene.info}{GENE information matrix, The 1st column is GENE id, 2nd column is chromosome #, 3rd and 4th column indicate start and end positions of the gene.}
}
\value{
A p-value.
}
\description{
Get the p-value of GATES-Simes. It uses an extended Simes procedure to combine GATES p-values across multiple genes in a pathway.
}
\examples{

simula <- simPathAR1Snp(nGenes=20, nGenes1=1, nSNPlim=c(1, 20), nSNP0=1:3,
                           LOR=.2, rholim=c(0,0),
                           n=100, MAFlim=c(0.05, 0.4), p0=0.05)
logitp <- getlogitp(simula$Y, simula$X)

## get correlation of SNPs using controls
ldmat <- cor(simula$X[ simula$Y == 0, ])
out <- GatesSimes(pvec = logitp, ldmatrix = ldmat, snp.info = simula$snp.info,
                  gene.info = simula$gene.info)
out


}
\author{
Il-Youp Kwak and Wei Pan
}
\references{
Hongsheng Gui, Miaoxin Li, Pak C Sham and Stacey S Cherny (2011)
Comparisons of seven algorithms for pathway analysis using the WTCCC Crohn's Disease
BMC Research Notes, 4:386
}
\seealso{
\code{\link{Hyst}}  \code{\link{GATES2}}
}

