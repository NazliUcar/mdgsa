##get_GO_KEGG_names.r
##2013-04-03 dmontaner@cipf.es
##2013-09-26 dmontaner@cipf.es


##' @name getGOnames
## @docType 
##' @author David Montaner \email{dmontaner@@cipf.es}
##' 
## @aliases 
##' 
##' @keywords GO ontology names
##' @seealso \code{\link{propagateGO}}, \code{\link{goLeaves}},
##' \code{\link{splitOntologies}}, \code{\link{getKEGGnames}},
##' \code{\link{getOntology}}
##' 
##' @title Get Gene Ontology names
##'
##' @description
##' Finds the GO name form GO id.
##' 
##' @details
##' Uses the library GO.db.
##'
##' \code{x} may be a \code{data.frame}.
##' In such case, GO ids are expected in its row names.
##' 
##' @param x a character vector of GO ids.
##' @param verbose verbose.
##'
##' @return A character vector with the corresponding GO names.
##'
##' @examples
##' getGOnames (c("GO:0000018", "GO:0000038", "BAD_GO"))
##' 
##' @import DBI
##' @import GO.db
##'
##' @export

getGOnames <- function (x, verbose = TRUE) {
    
    if (is.data.frame (x) | is.matrix (x)) {
        if (verbose) message ("Using row names of the input matrix.")
        x <- rownames (x)
    }
    
    if (verbose) {
        message ("Using GO.db version: ",
                 packageDescription ("GO.db", fields = "Version"))
    }
    
    ##go id to ontology
    micon <- GO_dbconn ()
    tabla <- dbReadTable (micon, "go_term")
    tabla <- tabla[,c("go_id", "term")]
    ##tabla <- tabla[tabla$go_id != "all",]
    
    id2name <- tabla[,"term"]
    names (id2name) <- tabla[,"go_id"]
    
    ##my go ids
    res <- id2name[x]
    
    if (any (is.na (res))) {
        warning (sum (is.na (res)),
                 " GOids where not found; missing names generated.")
    }

    ## OUTPUT
    res
}


################################################################################
################################################################################


##' @name getKEGGnames
## @docType 
##' @author David Montaner \email{dmontaner@@cipf.es}
##' 
## @aliases 
##' 
##' @keywords KEGG names
##' @seealso \code{\link{getGOnames}}
##' 
##' @title Get KEGG  names
##' 
##' @description
##' Finds the KEGG name form KEGG id.
##' 
##' @details
##' Uses the library KEGG.db.
##'
##' \code{x} may be a \code{data.frame}.
##' In such case, GO ids are expected in its row names.
##' 
##' @param x a character vector of KEGG ids.
##' @param verbose verbose.
##'
##' @return A character vector with the corresponding KEGG names.
##'
##' @examples
##' getKEGGnames (c("00010", "00020", "BAD_KEGG"))
##' 
##' @import DBI
##' @import KEGGREST
##'
##' @export

getKEGGnames <- function(x, verbose = TRUE) {
    
    if (is.data.frame(x) | is.matrix(x)) {
        if (verbose) message("Using row names of the input matrix.")
        x <- rownames(x)
    }
    
    if (verbose) {
        message("Fetching KEGG data online using KEGGREST")
    }

    # Ensure IDs are properly formatted (KEGGREST requires full IDs)
    # Using 'hsa' for Human; tappAS will appreciate the clarity
    x <- ifelse(!grepl("^path:", x), paste0("path:hsa", x), x) 
    
    # Fetch pathway names from KEGG
    id2name <- sapply(x, function(id) {
        tryCatch({
            keggGet(id)[[1]]$NAME
        }, error = function(e) NA) 
    })
    
    # Warn if any IDs were not found
    if (any(is.na(id2name))) {
        warning(sum(is.na(id2name)), " KEGG ids were not found; missing names generated.")
    }

    return(id2name)
}