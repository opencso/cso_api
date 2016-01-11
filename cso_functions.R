clean.names <- function(my){ 
    ## do some regex messing to shorten the names of the headings
    title <- names(my)
    title <- gsub("[^a-z0-9]",".", title,ignore.case=TRUE)
    title <- paste0(title, ".")
    my <- data.frame(my)
    the_names <- names(my)
    ## if the title begains with a number ex 2002.Family.. the R will prepend an X
    ## remove this X if it Exists

    the_names <- gsub("^X", "", the_names)
    for(i in 1:length(the_names)){
        the_names[i] <- gsub(title, "", the_names[i])
    }

    names(my) <- the_names
    return(my)
}
