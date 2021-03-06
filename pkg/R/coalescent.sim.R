
####################
## coalescent.sim ##
####################

## a function for simulating trees under a fully-linked coalescent model.
## optional simulation of a phenotype and phenotypically-associated SNPs is implemented.
## optional use of a distribution to guide the substitution rate of the non-associated SNPs is implemented.

########################################################################

###################
## DOCUMENTATION ##
###################

#' Simulate a tree, phenotype, and genetic data.
#'
#' This funtion allows the user to simulate a phylogenetic tree, as well as
#' phenotypic and genetic data, including associated and unassociated loci.
#'
#' @param n.ind An integer specifying the number of individual genomes to simulate
#'                (ie. the number of terminal nodes in the tree).
#' @param n.snps An integer specifying the number of genetic loci to simulate.
#' @param n.subs Either an integer or a vector (containing a distribution) that is
#'                used to determine the number of substitutions
#'                to occur on the phylogenetic tree for each genetic locus (see details).
#' @param n.snps.assoc An optional integer specifying the number of genetic loci
#' @param assoc.prob An optional integer (> 0, <= 100) specifying the strength of the
#'                    association between the n.snps.assoc loci and the phenotype (see details).
#' @param n.phen.subs An integer specifying the expected number of phenotypic
#'                      substitutions to occur on the phylogenetic tree (through the same process as
#'                      the n.subs parameter when n.subs is an integer (see details)).
#' @param phen An optional vector containing a phenotype for each of the
#'              n.ind individuals if no phenotypic simulation is desired.
#' @param plot A logical indicating whether to generate a plot of the phylogenetic tree (\code{TRUE}) or not (\code{FALSE}, the default).
#' @param heatmap A logical indicating whether to produce a heatmap of the genetic distance
#'                  between the simulated genomes of the n.ind individuals.
#' @param reconstruct Either a logical indicating whether to attempt to reconstruct
#'                      a phylogenetic tree using the simulated genetic data, or one of c("UPGMA", "nj", "ml")
#'                      to specify that tree reconstruction is desired by one of these three methods
#'                      (Unweighted Pair Group Method with Arithmetic Mean, Neighbour-Joining, Maximum-Likelihood).
#' @param dist.dna.model A character string specifying the type of model to use in reconstructing the phylogenetic tree for
#'                          calculating the genetic distance between individual genomes, only used if \code{tree} is a character string (see ?dist.dna).
#' @param grp.min An optional number between 0.1 and 0.9 to control the proportional size of the smaller phenotypic group.
#' @param seed An optional integer controlling the pseudo-random process of simulation; else \code{NULL}.
#'                Two instances of coalescent.sim with the same seed and arguments will produce identical output.
#' @param row.names An optional vector containing row names for the individuals to be simulated.
#' @param set An integer (1, 2, or 3) required to select the method of generating associated loci if \code{n.snps.assoc} is not zero.
#' @param coaltree A logical indicating whether to generate a coalescent tree (\code{TRUE}, the default), or an rtree-type tree (\code{FALSE}, see ?rtree).
#' @param s If \code{set} is 3, the \code{s} parameter controls a baseline number of substiutions to be experienced by the phenotype and associated loci: by default, 20.
#' @param af If \code{set} is 3, the \code{af} parameter provides an association factor,
#'              controlling the preference for association over non-association at associated loci:  by default, 10 (for a 10x preference).
#' @param filename.plot An optional character string denoting the file location for saving any plots produced; else \code{NULL}.
#' @param seed An optional integer to control the pseudo-randomisation process and allow for identical repeat runs of the function; else \code{NULL}.
#'
#' @details
#' \strong{Homoplasy Distribution}
#'
#' The homoplasy distribution contains the number of substitutions per site.
#'
#' If the value of the \code{n.subs} parameter is set to an integer, this integer is
#' used as the parameter of a Poisson distribution from which the number of substitutions to
#' occur on the phylogenetic tree is drawn for each of the \code{n.snps} simulated genetic loci.
#'
#' The \code{n.subs} argument can also be used to provide a distribution
#' to define the number of substitutions per site.
#'
#' It must be in the form of a \emph{named} vector (or table), or a vector in which the \emph{i}'th element
#' contains the number of \emph{loci} that have been estimated to undergo \emph{i} substitutions on the tree.
#' The vector must be of length \emph{max n.subs}, and "empty" indices must contain zeros.
#' For example: the vector \code{n.subs = c(1833, 642, 17, 6, 1, 0, 0, 1)}, could be used to define the homoplasy distribution for a dataset with 2500 loci,
#' where the maximum number of substitutions to be undergone on the tree by any locus is 8, and no loci undergo either 6 or 7 substitutions.
#'
#'
#' \strong{Association Probability}
#'
#' The \code{assoc.prob} parameter is only functional when \code{set} is set to 1.
#' If so, \code{assoc.prob} controls the strength of association through a process analagous to dilution.
#' All \code{n.snps.assoc} loci are initially simulated to undergo a substitution
#' every time the phenotype undergoes a substitution (ie. perfect association).
#' The assoc.prob parameter then acts like a dilution factor, removing \code{(100 - assoc.prob)\%}
#' of the substitutions that occurred during simulation under perfect association.
#'
#' @author Caitlin Collins \email{caitiecollins@@gmail.com}
#'
#' @examples
#' \dontrun{
#' ## load example homoplasy distribution
#' data(dist_0)
#' str(dist_0)
#'
#' ## simulate a matrix with 10 associated loci:
#' dat <- coalescent.sim(n.ind = 100,
#'                         n.snps = 1000,
#'                         n.subs = dist_0,
#'                         n.snps.assoc = 10,
#'                         assoc.prob = 90,
#'                         n.phen.subs = 15,
#'                         phen = NULL,
#'                         plot = TRUE,
#'                         heatmap = FALSE,
#'                         reconstruct = FALSE,
#'                         dist.dna.model = "JC69",
#'                         grp.min = 0.25,
#'                         row.names = NULL,
#'                         coaltree = TRUE,
#'                         s = NULL,
#'                         af = NULL,
#'                         filename = NULL,
#'                         set = 1,
#'                         seed = 1)
#'
#' ## examine output:
#' str(dat)
#'
#' ## isolate elements of output:
#' snps <- dat$snps
#' phen <- dat$phen
#' snps.assoc <- dat$snps.assoc
#' tree <- dat$tree
#' }
#' @import adegenet ape
#' @importFrom phangorn midpoint
#'
#' @export

########################################################################
#  @useDynLib phangorn, .registration = TRUE

############
## NOTES: ##
############
## theta_p changed to n.phen.subs (and just n.subs in phen.sim.R)


## OLD ARGS: ##
# (n.ind=100, gen.size=10000, sim.by="locus",
#  theta=1*2, dist=NULL,
#  n.phen.subs=15, phen=NULL,
#  n.snps.assoc=5, assoc.option="all", assoc.prob=90,
#  haploid=TRUE, biallelic=TRUE, seed=NULL,
#  plot=TRUE, heatmap=FALSE, plot2="UPGMA")

## NEW ARGS: ##
# n.ind <- 100
# n.snps <- 10000
# n.subs <- dist_0.1
# n.snps.assoc <- 10
# assoc.prob <- 100
# n.phen.subs <- 15
# phen <- NULL
# plot <- TRUE
# heatmap <- FALSE
# reconstruct <- FALSE
# dist.dna.model <- "JC69"
# grp.min <- 0.25
# row.names <- NULL
# coaltree <- FALSE
# s <- 20
# af <- 10
# set <- 3 # NULL #
# filename <- NULL
# seed <- 77


## TOY EG for PRESENTATION:
# c.sim <- coalescent.sim(n.ind=15,
#                         n.snps=1000,
#                         n.subs=dist_0,
#                         n.snps.assoc=10,
#                         assoc.prob=90,
#                         n.phen.subs=5,
#                         phen=NULL,
#                         plot=TRUE,
#                         heatmap=FALSE,
#                         reconstruct=FALSE,
#                         dist.dna.model="JC69",
#                         grp.min = 0.25,
#                         row.names=NULL,
#                         coaltree = TRUE,
#                         s = 10,
#                         af = 5,
#                         filename = NULL,
#                         set=1,
#                         seed=5)

## EG:
# c.sim <- coalescent.sim(n.ind=100,
#                         n.snps=10000,
#                         n.subs=dist_0,
#                         n.snps.assoc=10,
#                         assoc.prob=100,
#                         n.phen.subs=15,
#                         phen=NULL,
#                         plot=TRUE,
#                         heatmap=FALSE,
#                         reconstruct=FALSE,
#                         dist.dna.model="JC69",
#                         grp.min = 0.25,
#                         row.names=NULL,
#                         coaltree = TRUE,
#                         s = 10,
#                         af = 5,
#                         filename = NULL,
#                         set=1,
#                         seed=78)


coalescent.sim <- function(n.ind = 100,
                           n.snps = 10000,
                           n.subs = 1,
                           n.snps.assoc = 0,
                           assoc.prob = 100,
                           n.phen.subs = 15,
                           phen = NULL,
                           plot = TRUE,
                           heatmap = FALSE,
                           reconstruct = FALSE,
                           dist.dna.model = "JC69",
                           grp.min = 0.25,
                           row.names = TRUE,
                           set = 1,
                           coaltree = TRUE,
                           s = 20,
                           af = 10,
                           filename.plot = NULL,
                           seed = NULL){
  ## load packages:
  # require(adegenet)
  # require(ape)

  filename <- filename.plot

  if(is.null(set)){
    set <- 1
    # warning("set cannot be NULL. Setting set to 1.")
  }
  sets <- NULL

  if(length(which(c(plot, heatmap, reconstruct)==TRUE))==1){
    par(ask=FALSE)
  }else{
    par(ask=TRUE)
  }

  ################################
  ## Simulate Phylogenetic Tree ##
  ################################
  if(coaltree == TRUE){
    if(!is.null(seed)) set.seed(seed)
    tree <- coalescent.tree.sim(n.ind = n.ind, seed = seed)
  }else{
    if(!is.null(seed)) set.seed(seed)
    tree <- rtree(n = n.ind)
  }
  ## Always work with tree in pruningwise order:
  tree <- reorder.phylo(tree, order="pruningwise")
  ## Trees must be rooted:
  if(!is.rooted(tree)) tree <- midpoint(tree)

  ########################
  ## Simulate Phenotype ##
  ########################
  if(set == 3){

    ############
    ## NEW Q: ##
    ############
    ## if Q contains RATES --> P contains probs
    ## QUESTION -- HOW TO INTERPRET/PREDICT THE RELATIVE EFFECTS OF ASSOC.FACTOR AND N.SUBS (+ BRANCH LENGTH) ON ASSOC STRENGTH, N.SUBS PER TREE ?

    if(is.null(s)) s <- 20 # n.subs
    if(is.null(af)) af <- 10 # association factor
    ## Modify s to account for sum(tree$edge.length):
    ## --> ~ s/10 (= 2) for coaltree
    ## OR --> ~ s/100 (= 0.2) for rtree
    s <- s/sum(tree$edge.length)


    Q.mat <- matrix(c(NA, 1*s, 1*s, 0,
                      1*af*s, NA, 0, 1*af*s,
                      1*af*s, 0, NA, 1*af*s,
                      0, 1*s, 1*s, NA),
                    nrow=4, byrow=T, dimnames=rep(list(c("0|0", "0|1", "1|0", "1|1")), 2))

    diag(Q.mat) <- sapply(c(1:nrow(Q.mat)), function(e) -sum(Q.mat[e, c(1:ncol(Q.mat))[-e]]))
    # Q <- Q.mat

    ## SAVE PANEL PLOT:
    if(!is.null(filename)){
      pdf(file=filename[[2]], width=7, height=11)
      # dev.copy(pdf, file=filename[[2]], width=7, height=11)
    }

    ## RUN SNP.SIM.Q: ##
    if(!is.null(seed)) set.seed(seed)
    system.time(
    snps.list <- snp.sim.Q(n.snps = n.snps,
                           n.subs = n.subs,
                           snp.root = NULL,
                           n.snps.assoc = n.snps.assoc,
                           assoc.prob = assoc.prob,
                           ## dependent/corr' transition rate/prob mat:
                           Q = Q.mat,
                           tree = tree,
                           n.phen.subs = n.phen.subs,
                           phen.loci = NULL,
                           heatmap = FALSE,
                           reconstruct = FALSE,
                           dist.dna.model = "JC69",
                           grp.min = grp.min,
                           row.names = NULL,
                           set=set,
                           seed=seed)
    )
    snps <- snps.list$snps
    snps.assoc <- snps.list$snps.assoc
    sets <- NULL
    phen <- snps.list$phen
    phen.nodes <- snps.list$phen.nodes

    if(!is.null(filename)){
      ## end saving panel plot:
      dev.off()
    }

  }else{


    ##################
    ## SETS 1 and 2 ##
    ##################

  if(is.null(phen)){
    if(!is.null(seed)) set.seed(seed)
    ## get list of phenotype simulation output
    phen.list <- phen.sim(tree, n.subs = n.phen.subs, grp.min = grp.min, seed = seed)

    ## get phenotype for terminal nodes only
    phen <- phen.list$phen

    ## get phenotype for all nodes,
    ## terminal and internal
    phen.nodes <- phen.list$phen.nodes

    ## get the indices of phen.subs (ie. branches)
    phen.loci <- phen.list$phen.loci
  }else{
    #############################
    ## User-provided Phenotype ##
    #############################
    phen.nodes <- phen
    phen.loci <- NULL
  }


  ###################
  ## Simulate SNPs ##
  ###################

  ## TO DO: #######################################
  ## CHECK SNP SIMULATION FOR COMPUTATIONAL SPEED! #########################################################################################
  #################################################
  ## 10 --> 53 --> 12.5
  ## Are the remaining extra 2.5 seconds still just a result of the while loop??
  ## Or have I slowed anything down in the post-processing steps as well??????????????????

  #   n.snps <- 10000 # 13.3
  #   n.snps <- 100000 # 153.8
  #   n.snps <- 1000000 # >> 1941.7 (stopped trying..)
  #

  if(!is.null(seed)) set.seed(seed)
  # system.time(
  snps.list <- snp.sim(n.snps=n.snps,
                       n.subs=n.subs,
                       n.snps.assoc=n.snps.assoc,
                       assoc.prob=assoc.prob,
                       tree=tree,
                       phen.loci=phen.loci,
                       heatmap=heatmap,
                       reconstruct=reconstruct,
                       dist.dna.model=dist.dna.model,
                       row.names = NULL,
                       set=set,
                       seed=seed)
  # )

  snps <- snps.list$snps
  snps.assoc <- snps.list$snps.assoc
  sets <- snps.list$sets

  }

  #################################
  ## Plot Tree showing Phenotype ##
  #################################

  ## SAVE TREE PLOT:
  if(!is.null(filename)){
    pdf(file=filename[[1]], width=7, height=11)
    # dev.copy(pdf, file=filename[[1]], width=7, height=11)
  }

  if(plot==TRUE){
    if(class(try(plot.phen(tree = tree,
                           phen.nodes = phen.nodes,
                           plot = plot))) =="try-error"){
      plot(tree)
      warning("Oops-- something went wrong when trying to plot
              phenotypic changes on tree.")
    }else{
      phen.plot.col <- plot.phen(tree = tree,
                                 phen.nodes = phen.nodes,
                                 plot = plot, main.title=FALSE)
    }

    ##################
    ## SET 2 CLADES ##
    ##################
    ## plot set2 clade sets along tips:
    if(!is.null(sets)){
      ## Get CLADES:
      set1 <- names(sets)[which(sets == 1)]
      set2 <- names(sets)[which(sets == 2)]

      tip.labs <- tree$tip.label
      if(coaltree == FALSE) tip.labs <- removeFirstN(tip.labs, 1) ## assuming tip.labs are prefaced w/ "t" for all rtrees...
      cladeCol <- rep(NA, length(tip.labs))
      cladeCol <- replace(cladeCol, which(tip.labs %in% set1), "black")
      cladeCol <- replace(cladeCol, which(tip.labs %in% set2), "grey")
      ## PLOT CLADES along tips:
      ## coaltree:
      if(coaltree == TRUE){
        tiplabels(text=NULL, cex=0.6, adj=c(0.65, 0.5), col=cladeCol, pch=15) # adj=c(0.65, 0.75) ## NOT SURE WHY/WHEN ADJ WORKS/w WHAT VALUES?????
      }else{
        ## rtree:
        tiplabels(text=NULL, cex=0.75, adj=c(0.65, 0.75), col=cladeCol, pch=15) # adj=c(0.65, 0.75) ## NOT SURE WHY/WHEN ADJ WORKS/w WHAT VALUES?????
      }
    }

    if(!is.null(filename)){
      ## end saving tree plot:
      dev.off()
    }

  }

  ################
  ## Get Output ##
  ################
  out <- list(snps, snps.assoc, phen, phen.plot.col, tree, sets)
  names(out) <- c("snps", "snps.assoc", "phen", "phen.plot.col", "tree", "sets")
  return(out)

} # end coalescent.sim
