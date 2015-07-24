#' Pathway based Sum of Powered Score tests (SPUpath) and adaptive SPUpath (aSPUpath) test for meta-analyzed data.
#'
#' It gives p-values of the SPUpath tests and aSPUpath test for meta-analyzed data.
#'
#' @param Zs Z-scores for each SNPs. It could be P-values if the Ps option is TRUE. 
#'
#' @param corrSNP Correaltion matirx of SNPs. Estimated from the reference population.
#'
#' @param snp.info SNP information matrix, the 1st column is SNP id, 2nd column is chromosome #, 3rd column indicates SNP location.
#'
#' @param gene.info GENE information matrix, The 1st column is GENE id, 2nd column is chromosome #, 3rd and 4th column indicate start and end positions of the gene.
#'
#' @param pow SNP specific power(gamma values) used in SPUpath test.
#'
#' @param pow2 GENE specific power(gamma values) used in SPUpath test.
#'
#' @param n.perm number of permutations.
#'
#' @param Ps TRUE if input is p-value, FALSE if input is Z-scores. The default is FALSE.
#'
#' @export
#' @return P-values for SPUMpath tests and aSPUMpath test.
#'
#' @author Il-Youp Kwak and Wei Pan
#'
#' @references
#' Wei Pan, Il-Youp Kwak and Peng Wei (2015)
#' A Powerful and Pathway-Based Adaptive Test for Genetic Association With Common or Rare Variants (Submitted)
#'
#' @examples
#' data(kegg9)
#'
#' # p-values of SPUpath and aSPUpath tests.
#' out.a <- aSPUMpath(kegg9$nZ, corrSNP = kegg9$ldmatrix, pow=c(1:8, Inf),
#'                   pow2 = c(1,2,4,8), 
#'                   snp.info=kegg9$snp.info, gene.info = kegg9$gene.info,
#'                   n.perm=10, Ps = TRUE)
#' out.a
#'
#' @seealso \code{\link{simPathAR1Snp}} \code{\link{aSPUpathSingle}} \code{\link{aSPUpath}}

aSPUMpath <- function(Zs, corrSNP, pow=c(1,2,4,8, Inf),
                      pow2 = c(1,2,4,8), 
                      snp.info, gene.info, n.perm=1000,
                      Ps = FALSE) {

    ko <- length(Zs)
    n.gene <- nrow(gene.info)
    GL <- list(0)
    GLch <- NULL
 #   GL.CovSsqrt <- list(0)
    i = 1
    for(g in 1:n.gene) { # g = 1
      snpTF <- ( snp.info[,2] == gene.info[g,2] &
                      gene.info[g,3] <= as.numeric(snp.info[,3]) &
                          gene.info[g,4] >= as.numeric(snp.info[,3]) )

        if( sum(snpTF) != 0){
            GL[[i]] <- which(snpTF)
            GLch <- c(GLch, gene.info[g,2])
            i = i + 1

        }
    }

    chrs <- unique(GLch)
    CH <- list(0)
    CH.CovSsqrt <- list(0)
   for( i in 1:length(chrs) ) { # i = 2
      c = chrs[i]
      CH[[i]] <- unlist(GL[which( GLch == c )])
      Covtemp <- corrSNP[CH[[i]], CH[[i]]]
      eS <- eigen(Covtemp, symmetric = TRUE)
      ev <- eS$values
      k1 <- length(ev)
      CH.CovSsqrt[[i]] <- eS$vectors %*% diag(sqrt(pmax(ev, 0)), k1)
    }

#    for( i in 1:length(chrs) ) { # c = 16
#      c = chrs[i]
#      CH[[c]] <- unlist(GL[which( GLch == c )])
#    }




    Zs = Zs[unlist(GL)]
    nSNPs0=unlist(lapply(GL,length))

    k <- length(Zs)
    if(Ps == TRUE)
        Zs <- qnorm(1 - Zs/2)

    U <- Zs

    nGenes=length(nSNPs0)
    TsUnnorm<-Ts<-StdTs<-rep(0, length(pow)*nGenes)
    for(j in 1:length(pow))
        for(iGene in 1:nGenes){
            if (iGene==1) SNPstart=1 else SNPstart=sum(nSNPs0[1:(iGene-1)])+1
            indx=(SNPstart:(SNPstart+nSNPs0[iGene]-1))
            if (pow[j] < Inf){
                a= (sum(U[indx]^pow[j]))
                TsUnnorm[(j-1)*nGenes+iGene] = a
                Ts[(j-1)*nGenes+iGene] = sign(a)*((abs(a)) ^(1/pow[j]))
                StdTs[(j-1)*nGenes+iGene] = sign(a)*((abs(a)/nSNPs0[iGene]) ^(1/pow[j]))
		# (-1)^(1/3)=NaN!
		#Ts[(j-1)*nGenes+iGene] = (sum(U[indx]^pow[j]))^(1/pow[j])
            }
            else {
                TsUnnorm[(j-1)*nGenes+iGene] = Ts[(j-1)*nGenes+iGene] = StdTs[(j-1)*nGenes+iGene] =max(abs(U[indx]))
            }
        }

    ## Permutations:
    T0sUnnorm=T0s = StdT0s = matrix(0, nrow=n.perm, ncol=length(pow)*nGenes)
    for(b in 1:n.perm){

        U00<-rnorm(ko, 0, 1)
        U0 <- NULL;
        for( ss in 1:length(CH)) { # ss = 21
          U0 <- c(U0, CH.CovSsqrt[[ss]] %*% U00[CH[[ss]]])
        }

        if(Ps == TRUE)
          U0 <- abs(U0)
        ## test stat's:
        for(j in 1:length(pow))
            for(iGene in 1:nGenes){
                if (iGene==1) SNPstart=1 else SNPstart=sum(nSNPs0[1:(iGene-1)])+1
		   indx=(SNPstart:(SNPstart+nSNPs0[iGene]-1))
                if (pow[j] < Inf){
                    a = (sum(U0[indx]^pow[j]))

                    StdT0s[b, (j-1)*nGenes+iGene] = sign(a)*((abs(a)/nSNPs0[iGene]) ^(1/pow[j]))
                }

                else StdT0s[b, (j-1)*nGenes+iGene] = max(abs(U0[indx]))
            }
    }

   #combine gene-level stats to obtain pathway-lelev stats:
    Ts2<-rep(0, length(pow)*length(pow2))
    T0s2<-matrix(0, nrow=n.perm, ncol=length(pow)*length(pow2))
    for(j2 in 1:length(pow2)){
        for(j in 1:length(pow)){
            Ts2[(j2-1)*length(pow) +j] = sum(StdTs[((j-1)*nGenes+1):(j*nGenes)]^pow2[j2])
            for(b in 1:n.perm){
                T0s2[b, (j2-1)*length(pow) +j] = sum(StdT0s[b, ((j-1)*nGenes+1):(j*nGenes)]^pow2[j2])
            }
        }
    }

   # permutation-based p-values:
    pPerm2 = rep(NA, length(pow)*length(pow2));
    pvs = NULL;

    for(j in 1:(length(pow)*length(pow2))) {
        pPerm2[j] = sum( abs(Ts2[j]) < abs(T0s2[,j]))/n.perm
    }
    P0s2 = PermPvs(T0s2)
    minP0s2 = apply(P0s2, 1, min)
    minP2 =  sum( min(pPerm2) > minP0s2 )/n.perm
    minP2s <- rep(NA, length(pow2))
    for(j2 in 1:length(pow2)){
        minP0s2 = apply(P0s2[, ((j2-1)*length(pow)+1):(j2*length(pow))], 1, min)
        minP2s[j2] =  sum( min(pPerm2[((j2-1)*length(pow)+1):(j2*length(pow))]) > minP0s2 )/n.perm
    }
    pvs=c(pPerm2, minP2)

    nmvec <- NULL;
    for(nm in paste("SPUMpath",pow,",", sep=""))
        nmvec <- c(nmvec, paste(nm, pow2, sep="") )

    nmvec <- c(nmvec, "aSPUMpath")
    names(pvs) <- nmvec
    pvs

#    stdPs=c(pPerm2, minP2s, minP2)
}

