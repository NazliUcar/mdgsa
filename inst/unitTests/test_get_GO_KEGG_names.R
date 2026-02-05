##test_get_GO_KEGG_names.r
##2014-11-19 dmontaner@cipf.es
##UnitTesting

## rm (list = ls ())
## R.version.string ##"R version 3.1.1 (2014-07-10)"
## library (mdgsa); packageDescription ("mdgsa", fields = "Version") #"0.99.1"
## library (RUnit); packageDescription ("RUnit", fields = "Version") #"0.4.27"
## ## help (package = RUnit)

test_getGOnames <- function () {
    require (GO.db)
    system.time (tgt <- Term (GOTERM))
    ids <- names (tgt)
    system.time (cur <- getGOnames (ids))
    checkIdentical (tgt, cur)
}

test_getKEGGnames <- function () {
    ## Test with KEGGREST-based implementation
    ## Verify that getKEGGnames returns non-empty results for valid KEGG pathway IDs
    ids <- c("path:hsa00010", "path:hsa00020")
    system.time (cur <- getKEGGnames (ids))
    
    ## Check that result is a character vector with names
    checkTrue(is.character(cur))
    checkTrue(length(cur) > 0)
    checkTrue(all(nchar(cur) > 0))
    
    ## Test with numeric IDs (should be converted to path:hsa format)
    ids_numeric <- c("00010", "00020")
    system.time (cur2 <- getKEGGnames (ids_numeric))
    checkTrue(is.character(cur2))
    checkTrue(length(cur2) > 0)
    
    ## Test with invalid ID (should return NA with warning)
    ids_invalid <- c("path:hsa00010", "BAD_KEGG_ID")
    cur3 <- getKEGGnames (ids_invalid)
    checkTrue(any(is.na(cur3)))
}

#test_getGOnames ()
#test_getKEGGnames ()
