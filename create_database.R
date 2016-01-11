## create database.R
## read a json-stat file from cso.ie and save a csv with the data
## a .sql file with a create table command with the field names 
## and the types the types of the fields
## these will all be varchar(x) except for Month/Year etc and value which will be Data and real
## and the the data

## these files can then be used to 

require(rjstat)
require(dplyr)
require(reshape2)
require(ggplot2)
require(lubridate)
require(JSON)
require(jsonlite)

source("cso_functions.R")

all_sql <- ""
table_list <- read.csv("table_names.csv")
for(k in 1:nrow(table_list)){
    file_path <- "/home/dave/cso/api/files/"
    current_filename <-"CDD19"## table_list[k,]
    current_dataset <- paste0(file_path, current_filename)
    tryCatch(my <- fromJSONstat(current_dataset),warning=function(){ next},error=function(){ next})
    cat(current_filename, "\n")
    my_codes <-fromJSONstat(current_dataset, naming="id")
    
    ## grab a copy of the json file to pull out metadata
    just_json <- fromJSON(current_dataset)
    
    ## a list of the headdings in the dataset 
    set_ids <- just_json$dataset$dimension$id
    set_ids <- gsub(" ", ".", set_ids)
    
    ## the time column in the set
    time_id <- just_json$dataset$dimension$role$time
    time_id <- gsub(" ", ".", time_id)
    
    ## the metric id always Statistic
    metric_id <- just_json$dataset$dimension$role$metric

    ##join the labels and the ids into one data.frame
    my <- clean.names(my)
    value_index <- ncol(my)
    my_codes <- clean.names(my_codes)
    my_codes <- my_codes[-c(time_index, ncol(my_codes))]
    names(my_codes) <- paste0(names(my_codes), "_code")
    my <- cbind(my_codes, my)
    new_set_ids <- names(my)
    ## get the index of the time ID
    time_index <- 0
    for(i in 1:length(new_set_ids)){
        ##cat(set_ids[i], " ", time_id, "\n")
        if(new_set_ids[i] == time_id){
            time_index <- i
            break
        }
    }

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

    ## make all the cols except time and value a factor
    for(i in 1:length(new_set_ids)){
        if(new_set_ids[i] != "value"){
            if(new_set_ids[i] != time_id){
                my[,i] <- as.factor(my[,i])
            }
        }
    }

    my$value <- as.numeric(my$value)
    
    write.table(my, file=paste0("/home/dave/cso/api/output/",current_filename, ".csv"), col.names=FALSE, sep=",")
    ## create
    
    sql_string <-  paste0("create table ", current_filename, "( index int,\n")
    

    for(i in 1:length(new_set_ids)) {
        names(my)[i] <- gsub("\\.", "_", names(my)[i])
        ##cat(i, " ",names(my)[i], "\n")
        if(is.factor(my[,i])) {

            names(my)[i]
            my_levels <- levels(my[,i])
            max_length <- 0
            
            for(j in 1:length(my_levels)){
                if(nchar(as.character(my_levels[j])) > max_length){
                    max_length <- nchar(as.character(my_levels[j]))
                }                
            }
            sql_string <- paste0(sql_string, names(my)[i], " varchar(", max_length, "),\n")
        } else if(i == time_index) {
            sql_string <- paste0(sql_string, names(my)[i], " date,\n")
        } else if(names(my)[i] == "value") {
            sql_string <- paste0(sql_string,current_filename, "_value real\n);\n")
            
        }

    }
    sql_string <- paste0(sql_string, "\\copy ", current_filename, " FROM '/home/dave/cso/api/output/", current_filename,".csv' DELIMITER ',' CSV NULL 'NA' ;\n\n")
    all_sql <- paste0(all_sql, sql_string)
    
    
##}

cat(all_sql, file="all_sql.sql")    
