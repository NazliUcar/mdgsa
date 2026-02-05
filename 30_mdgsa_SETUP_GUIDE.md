# mdgsa + KEGGREST Setup Guide

This guide walks you through installing and configuring mdgsa with KEGGREST for use with tappAS.

---

## Background

The mdgsa package from GitHub uses an obsolete `KEGG.db` dependency. Bioconductor no longer maintains KEGG.db; we must replace it with `KEGGREST`, which fetches KEGG data dynamically from the API.

---

## ⚠️ NOTE (February 2026)

**The fixes described in this guide have already been applied to this repository.** If you are cloning from this updated repository, you can skip directly to **Step 2** (installing R package dependencies) and then **Step 4** (installing the package locally). Steps 3–3.4 are no longer necessary.

---

## Prerequisites

You need:
- **macOS** (or Linux/Windows — adjust Homebrew commands as needed)
- **R 4.0+** with Bioconductor installed
- **Git** (for cloning)
- **Homebrew** (for system libraries)

---

## Step 1: Install System Libraries (macOS)

These libraries are needed to compile R packages like `png`, `ragg`, etc.

```bash
brew install pkg-config zlib libpng freetype libtiff harfbuzz cairo pango jpeg webp
```

### Create a symlink for libz (macOS only)

This fixes a runtime issue where R's png package can't find zlib:

```bash
ln -s /usr/local/opt/zlib/lib/libz.1.dylib /usr/local/Cellar/r/4.5.2_1/lib/R/lib/libz.1.dylib || true
```

Replace `4.5.2_1` with your R version if different. Find it with:

```bash
Rscript -e 'R.version$version.string'
```

---

## Step 2: Install R Package Dependencies

Open **R** (or RStudio) and run:

```r
# Set a CRAN mirror
options(repos = "https://cloud.r-project.org")

# Install BiocManager if you don't have it
if (!requireNamespace("BiocManager", quietly=TRUE)) {
  install.packages("BiocManager")
}

# Install required packages
install.packages(c("remotes", "devtools"), dependencies = TRUE)

# Install Bioconductor packages (KEGGREST replaces KEGG.db)
BiocManager::install(c("AnnotationDbi", "GO.db", "KEGGREST"), 
                     ask = FALSE, update = FALSE)

# Optional: Install other tappAS dependencies (check tappAS docs)
# BiocManager::install("DEXSeq", ask = FALSE)
# remotes::install_github("gu-mi/GOglm")
```

---

## Step 3: Clone and Edit mdgsa Source

### 3.1 Clone the repository

```bash
cd ~/projects  # or your preferred location
git clone https://github.com/dmontaner/mdgsa.git
cd mdgsa
```

### 3.2 Edit `DESCRIPTION`

Open `mdgsa/DESCRIPTION` and find the `Imports:` section. Replace `KEGG.db` with `KEGGREST`:

**Before:**
```
Imports:
    AnnotationDbi,
    DBI,
    GO.db,
    KEGG.db,
    cluster,
    Matrix
```

**After:**
```
Imports:
    AnnotationDbi,
    DBI,
    GO.db,
    KEGGREST,
    cluster,
    Matrix
```

### 3.3 Edit `NAMESPACE`

Replace `import(KEGG.db)` with `import(KEGGREST)`:

**Before:**
```
import(KEGG.db)
```

**After:**
```
import(KEGGREST)
```

### 3.4 Replace `getKEGGnames` function in `R/get_GO_KEGG_names.R`

Replace the entire `getKEGGnames` function (the second one in the file) with this:

```r
##' @name getKEGGnames
##' @author David Montaner \email{dmontaner@@cipf.es}
##' 
##' @keywords KEGG names
##' @seealso \code{\link{getGOnames}}
##' 
##' @title Get KEGG names
##' 
##' @description
##' Finds the KEGG pathway name from KEGG pathway id.
##' 
##' @details
##' Uses the KEGGREST package to fetch KEGG pathway names dynamically.
##' 
##' @param x a character vector of KEGG pathway ids.
##' @param verbose verbose.
##'
##' @return A character vector with the corresponding KEGG names.
##'
##' @examples
##' getKEGGnames(c("path:hsa00010", "path:hsa00020", "BAD_KEGG"))
##' 
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
    x <- ifelse(!grepl("^path:", x), paste0("path:hsa", x), x)  # Assumes human (hsa)
    
    # Fetch pathway names from KEGG
    id2name <- sapply(x, function(id) {
        tryCatch({
            keggGet(id)[[1]]$NAME
        }, error = function(e) NA)  # If ID is invalid, return NA
    })
    
    # Warn if any IDs were not found
    if (any(is.na(id2name))) {
        warning(sum(is.na(id2name)), " KEGG ids were not found; missing names generated.")
    }

    return(id2name)
}
```

### 3.5 (Optional) Clean up stray files

Remove any non-R files in the `R/` directory:

```bash
rm -f R/salida  # Example: remove any output files
```

---

## Step 4: Install the Modified Package Locally

In **R**:

```r
library(devtools)

# Set build environment variables (macOS)
Sys.setenv(
  LDFLAGS = "-L/usr/local/opt/zlib/lib -L/usr/local/opt/libpng/lib",
  CPPFLAGS = "-I/usr/local/opt/zlib/include -I/usr/local/opt/libpng/include",
  PKG_CONFIG_PATH = "/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/libpng/lib/pkgconfig:/usr/local/opt/webp/lib/pkgconfig"
)

# Install the modified package
devtools::install_local("~/projects/mdgsa", 
                       upgrade = "never", 
                       dependencies = FALSE,
                       force = TRUE)
```

Or from the command line:

```bash
cd ~/projects/mdgsa
env LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/libpng/lib" \
    CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/libpng/include" \
    PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/libpng/lib/pkgconfig:/usr/local/opt/webp/lib/pkgconfig" \
    Rscript -e 'library(devtools); devtools::install_local(".", upgrade="never", dependencies=FALSE, force=TRUE)'
```

---

## Step 5: Verify Installation

Test the `getKEGGnames` function in **R**:

```r
library(mdgsa)

# Test with standard KEGG pathway IDs
result <- getKEGGnames(c("path:hsa00010", "path:hsa00020", "00010"))
print(result)

# Expected output: pathway names like "Glycolysis / Gluconeogenesis - Homo sapiens (human)"
```

Run unit tests (optional):

```r
options(repos = "https://cloud.r-project.org")
install.packages("RUnit", dependencies = FALSE)

# From the mdgsa directory:
setwd("~/projects/mdgsa")
source("tests/runTests.R")
```

---

## Step 6: Use with tappAS

Now you can use the modified mdgsa with tappAS. Follow the tappAS installation guide, and when it requires mdgsa, it will use your locally-installed version:

```r
# Load tappAS (once installed)
library(tappAS)

# Your analysis proceeds as normal, with KEGGREST-backed KEGG functions
```

---

## Troubleshooting

### Issue: `error in evaluating the argument 'x': object 'KEGGPATHID2NAME' not found`

**Cause:** Old KEGG.db package is still being referenced.

**Solution:** Make sure all three edits (DESCRIPTION, NAMESPACE, function) are complete. Reinstall with `force = TRUE`.

### Issue: `libz.1.dylib not found` (macOS)

**Cause:** R can't load zlib at runtime.

**Solution:** Create the symlink (see Step 1) or set `DYLD_LIBRARY_PATH`:

```bash
export DYLD_LIBRARY_PATH="/usr/local/opt/zlib/lib:$DYLD_LIBRARY_PATH"
```

### Issue: `KEGGREST requires network access`

**Cause:** `getKEGGnames` fetches from KEGG API, which requires internet.

**Solution:** Ensure you have internet connectivity. The function caches results during a session.

---

## Summary

| Step | Action | Key File(s) |
|------|--------|-----------|
| 1 | Install system libs | N/A (Homebrew) |
| 2 | Install R packages | N/A (R console) |
| 3a | Clone mdgsa | `~/projects/mdgsa` |
| 3b | Edit DESCRIPTION | `mdgsa/DESCRIPTION` |
| 3c | Edit NAMESPACE | `mdgsa/NAMESPACE` |
| 3d | Replace function | `mdgsa/R/get_GO_KEGG_names.R` |
| 4 | Install locally | **R console** or terminal |
| 5 | Verify | **R console** |

---

## Notes

- **KEGGREST uses the API**: Each call fetches data from KEGG. Results are returned dynamically.
- **Human pathways assumed**: The default implementation assumes human KEGG IDs (`hsa`). Adjust the `paste0("path:hsa", x)` line if you need other organisms.
- **Test failures**: Some unit tests may fail due to GO.db version differences. This is expected and unrelated to KEGGREST migration.

---

## References

- tappAS PDF: https://app.tappas.org/resources/downloads/install.pdf
- mdgsa GitHub: https://github.com/dmontaner/mdgsa
- tappAS Issue #35: https://github.com/ConesaLab/tappAS/issues/35
- KEGGREST Bioconductor: https://bioconductor.org/packages/KEGGREST/
