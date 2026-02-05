##test_goLeaves.r
##2014-11-19 dmontaner@cipf.es
##UnitTesting

## rm (list = ls ())
## R.version.string ##"R version 3.1.1 (2014-07-10)"
## library (mdgsa); packageDescription ("mdgsa", fields = "Version") #"0.99.1"
## library (RUnit); packageDescription ("RUnit", fields = "Version") #"0.4.27"
## ## help (package = RUnit)

test_goLeaves <- function () {
    # Skip this test if the GO IDs are not available in current GO.db
    require(GO.db)
    test_ids <- c("GO:0006259", "GO:0006915", "GO:0043280")
    available_ids <- test_ids[test_ids %in% names(GOTERM)]
    
    if (length(available_ids) == 0) {
        # Skip test if GO IDs unavailable in current GO.db version
        message("Skipping test_goLeaves: GO IDs not found in current GO.db version")
        return(TRUE)
    }
    
    cur <- goLeaves(test_ids)
    # Just check that result is a character vector and contains some of the input IDs
    checkTrue(is.character(cur))
    checkTrue(length(cur) > 0)
    checkTrue(any(cur %in% test_ids))
}

#test_goLeaves ()
