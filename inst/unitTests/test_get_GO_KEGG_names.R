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
    ## Robust tests for getKEGGnames: avoid brittle content checks that rely on
    ## external network responses. Validate types, lengths, and NA handling.

    # Basic valid IDs (full path format)
    ids <- c("path:hsa00010", "path:hsa00020")
    cur <- tryCatch(getKEGGnames(ids), error = function(e) stop(e))
    checkTrue(is.character(cur))
    checkTrue(length(cur) == length(ids))

    # Numeric IDs should be accepted and converted
    ids_numeric <- c("00010", "00020")
    cur2 <- tryCatch(getKEGGnames(ids_numeric), error = function(e) stop(e))
    checkTrue(is.character(cur2))
    checkTrue(length(cur2) == length(ids_numeric))

    # Invalid ID should yield NA for that position
    ids_invalid <- c("path:hsa00010", "BAD_KEGG_ID")
    cur3 <- tryCatch(getKEGGnames(ids_invalid), error = function(e) stop(e))
    checkTrue(is.character(cur3))
    checkTrue(length(cur3) == length(ids_invalid))
    checkTrue(any(is.na(cur3)))
}

#test_getGOnames ()
#test_getKEGGnames ()
