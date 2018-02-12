### This file contains your main code.
### Feel free to rename it, or split it into several files.
###
### Your final product should contain the code along the following lines:

##    ---------- Google Civic Platform ----------
## 1. create the google civic platform request and httr::GET() the result
##    you need to include your api key in the request.  See the documentation
##    https://developers.google.com/civic-information/
##    in particular the reference section.
##
##    Note: you can submit the requests through your browser.  If unsure, or if
##    httr::GET gives you an error, you may always put the address in your browser's
##    address bar.  If correct, it will display the corresponding JSON data.  If
##    incorrect, you get an error message.
library("httr")
library("jsonlite")
library(dplyr)
library(tidyr)

base <- "https://www.googleapis.com/civicinfo/v2"
endpoint <- "/representatives"
uri <-paste0(base, endpoint)
source("keys.R")
query.params <- list(address="Seattle", includeOffices = TRUE, key = google.key)
civic_response <- httr::GET(uri, query = query.params)

## 2. extract the elected officials' data from the result
##    The data contains many relevant variables, including normalized address,
##    'offices' and 'officials'.  In order to attach the officials (people)
##    with offices (jobs), I recommend to use dplyr joins (what would be the key?)
##    More about joins in
##    https://info201.github.io/dplyr.html#joins
##    http://r4ds.had.co.nz/relational-data.html

body <- content(civic_response,"text")
representatives <- fromJSON(body)
officials <- as.data.frame(representatives$officials)
offices <- as.data.frame(representatives$offices)
offices <- unnest(offices, officialIndices)
officials$officialIndices = seq.int(nrow(officials)) - 1

data <- left_join(officials, offices, by = "officialIndices")

## 3. transform the data into a well formatted table
##    I recommend you transform the data into markdown strings.  For instance,
##    to display a html link as a link in the markdown file, you may want to
##    embed it between "[](" and ")".
##    
##    You may want to consider improved table printing, look for details at the rmarkdown
##    page at
##    http://rmarkdown.rstudio.com/index.html

data$name.x <- ifelse(data$urls != "NA", paste0("[", data$name.x, "](", data$urls, ")"), data$name.x)
repTable <- data %>% select(Name = name.x, Position = name.y, Party = party, Email = emails, Phone = phones, Photo = photoUrl)
is.na(repTable) <- repTable == "NULL"
repTable$Photo <- ifelse(repTable$Photo != "NA", paste0("![Image](", repTable$Photo, ")"))


## -------------------- propublica --------------------
## 4. Get state representatives from propublica congress API
##    you need the respective API key.
##
##    Note1: the api key must be sent as 'X-API-Key'.  No other name, such as 'api-key'
##    will work.
##
##    Note2: Propublica API has several endpoints.  The relevant one here is 'members'.
##    It which allows you to get lists of members, lists of members by state,
##    specific member by id, voting data, and more.
##    
##    Read the documentation:
##    https://projects.propublica.org/api-docs/congress-api/members/

base2 <- "https://api.propublica.org"
endpoint2 <- "/congress/v1/members/house/WA/current.json"
uri2 <-paste0(base2, endpoint2)
propublica_response <- httr::GET(uri2, add_headers("X-API-Key" = propublica.key))
body2 <- content(propublica_response,"text")
house <- fromJSON(body2)
house <- as.data.frame(house$results)

## 5. transform it in a form you can use for visualizations.
## 
##    For the first visualization you have to extract the party affiliation of all the members
##    and make a histogram of that data.

party <- table(house$party)
gender <- table(house$gender)

## 6. pick a representative.
##
##    Note: this representative must correspond to the state the address points to.  Different
##    states have different number of representatives, I recommend to pick one of these at random. 
## 7. get this representative's info
##
##    Consult the 'members' endpoint and the examples related to information about a particular member.
uri2 <- house$api_uri[1]
propublica_response <- httr::GET(uri2, add_headers("X-API-Key" = propublica.key))
body2 <- content(propublica_response,"text")
person_data <- fromJSON(body2)
person_full <- as.data.frame(person_data$results)
person_more <- as.data.frame(person_data$results$roles[[1]])

## 8. get her recent votes.
##
##    In order to get the percentage of votes with majority, you have:
##    a) get the member's voting data (see the same API documentation)
##    b) pick the most recent votes (the data includes vote date)
##    c) find her position (Yes/No)
##    d) find the total votes (yes/no)
##    Consult the example in the API documentation that includes the relevant JSON result.

uri2 <- paste0(substring(uri2, 0, 54), "/votes.json")
propublica_response <- httr::GET(uri2, add_headers("X-API-Key" = propublica.key))
body2 <- content(propublica_response,"text")
votes_data <- fromJSON(body2)
votes <- as.data.frame(votes_data$results$votes[[1]]$total)
votes$position <- votes_data$results$votes[[1]]$position
