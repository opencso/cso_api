require(rjstat)
require(dplyr)
require(reshape2)
require(ggplot2)
require(lubridate)
require(JSON)
require(jsonlite)

get.cso.data <- function(dataset = "LRM13"){
    ##dataset <- "LRM13"
    ##dataset <- "B0331"
    ##dataset <- "B0630"
    cso_api_base <- "http://www.cso.ie/StatbankServices/StatbankServices.svc/jsonservice/responseinstance/"
    current_dataset <- paste0(cso_api_base, dataset)
    my <- fromJSONstat(current_dataset)
    ## grab a copy of the json file to pull out metadata
    just_json <- fromJSON(current_dataset)
    ## a list of the headdings in the dataset 
    set_ids <- just_json$dataset$dimension$id
    set_ids <- gsub(" ", ".", set_ids)
                                        # the time column in the set
    time_id <- just_json$dataset$dimension$role$time
    time_id <- gsub(" ", ".", time_id)
    ## the metric id always Statistic
    metric_id <- just_json$dataset$dimension$role$metric
    ## get the index of the time ID
    time_index <- 0
    for(i in 1:length(set_ids)){
        ##cat(set_ids[i], " ", time_id, "\n")
        if(set_ids[i] == time_id){
            time_index <- i
            break
        }
    }
    
    title <- names(my)
    title <- gsub("[^a-z0-9]",".", title,ignore.case=TRUE)
    title <- paste0(title, ".")
    my <- data.frame(my)
    the_names <- names(my)
    ## if the title begains with a number ex 2002.Family.. the R will prepend an X
    ## remove this X if it Exists
    the_names <- gsub("^X", "", the_names)
    for(i in 1:length(the_names)){
        ##cat("title: ", title, paste0("the_names[",i,"]: "), the_names[i], "\n")
        the_names[i] <- gsub(title, "", the_names[i])
    }
    names(my) <- the_names


    ## all data sets contain a Time variable covert it to a Date object
    if(names(my)[time_index] == "Month"){
        my[time_index] <- ymd(paste0(my$Month,"-01"))
        
    } else if(names(my)[time_index] == "Quarter"){

        my$Quarter <- sub("Q1", "0101", my$Quarter)
        my$Quarter <- sub("Q4", "0401", my$Quarter)
        my$Quarter <- sub("Q4", "0701", my$Quarter)
        my$Quarter <- sub("Q4", "1001", my$Quarter)
        my$Quarter <- ymd(my$Quarter) 
        
    } else if(names(my)[time_index] == "Year"){
        my$Year <- ymd(paste(my$Year, "01", "01", sep="-"))

    } else if (names(my)[time_index] == "Census.Year"){
        my$Census.Year <- ymd(paste(my$Census.Year, "01", "01", sep="-"))

    } else {
        cat(names(my)[time_index], " Not correct date\n")
    }

    min_time <- min(my[,time_index], na.rm=TRUE)
    max_time <- max(my[,time_index], na.rm=TRUE)

    ## make all the cols except time and value a factor
    for(i in 1:length(set_ids)){
        if(set_ids[i] != "value"){
            if(set_ids[i] != time_id){
                my[,i] <- as.factor(my[,i])
            }
        }
    }

    my$value <- as.numeric(my$value)
    ## clean up the title
    title <- gsub("..", " ", title)
    title <- gsub(".", " ", title)

    return(my)
}
