
################################################################################
###           MOTUS PROJECT - EXTRACTING AND SUMMARISING CTT DATA            ###
################################################################################

## This script is adapted from an online tutorial for extracting data from CTT, accessed from:
## https://cellular-tracking-technologies.github.io/

# Clean the environment before beginning:
rm(list = ls())

## HOW TO USE THIS SCRIPT: ##

# For the first time ever opening this, and wanting to extract data from CTT, run sections
# 1 - 6: These will install the packages, set up a database to store the data, prepare for the 
# CTT download, and pull out ALL historic data from the CTT database.

# Once you have built that directory of historic detection data in the appropriate place (see
# commentaries below), then section 7 can be used to update the database as and when and
# pull out key data summaries (e.g. recent detections), as well as some more advanced queries.

# Sections 8 and 9 are for additional queries and plotting, this is more of a playground section, 
# and can be used alongside the documentation of the CTT and duckdb packages to query/ plot different
# aspects of the data. 

# NOTE: Currently this script only downloads and deals with the BluTag receiver data. But other data types could
# easily be extracted (see section 5 and documentation).

### RUNNING THE SCRIPT FOR THE FIRST TIME: ######
### 1 - Installing packages and setting up a directory: ######

## Required packages:

# There are several packages needed for this script to run, if you encounter any additional 
# dependencies then install them as needed:

install.packages("DBI"); install.packages("duckdb"); install.packages("stringr"); 
install.packages("R.utils"); install.packages("duckplyr"); install.packages("dplyr")

# The CTT specific package is a package available on github, so we first need to install a package that will 
# read in from github, then get the 'celltracktech' package:

install.packages("devtools")
# 'devtools' has lots of dependencies packages, so this might take a minute.

# Now install the 'celltracktech' package from github using 'devtools':
devtools::install_github("cellular-tracking-technologies/celltracktech")

# You might be prompted to approve additional dependency packages depending on what you already have installed,
# type 'Yes' (or 1) into the console to continue with the download.

# Now load all these packages in:
require(DBI); require(duckdb); require(stringr); require(R.utils); require(duckplyr);
require(dplyr); require(celltracktech)

## File directory:

# This script is going to make a few files external to R, so set up a directory where you want
# to keep them.

# Then call it below, and assign it to an object for later use (If you press CTRL + SHIFT + H it opens the 
# directory tool):

setwd("insert directory here")
dir <- "insert directory here"

### 2 - Assigning the API key: ######

# An API key is essentially an access code to use some external software (or Application Programming
# Interface - API). This gives you access to this software when calling upon it from R, and since
# CTT is an external service, we need one now.

# An API key is a protected, user- or project-specific code, and so should not be sheared externally. 
# plug in your own API key below to continue using the script:

# Assign the API key to the environment as follows:
my_token <- "insert API key here"

### 3 - Creating a relational database to handle big datasets: ######

# CTT downloads hourly datasets from our multiple base stations that have been established for at
# times entire field seasons. These hourly datasets contain tag detections which ping at 10 second 
# intervals. All this to say... that's a lot of data. 

# Trying to download and integrate all that data into a single database will cause memory issues in
# R, so instead we'll use an SQL relational database. Rather than integrating all data into a single 
# file, these databases draw data together from common columns or variables, such as tag number / station ID etc.

# We are now going to use the directory we made earlier, called 'dir'.

# Here we a re buidling a database called 'CTTquery' in the directory you marked at the top 
# of this script.

CTTdatabase <- DBI::dbConnect(duckdb::duckdb(), 
                              dbdir = paste0(dir, "/", "CTTquery.duckdb"),
                              read_only = FALSE)

# The object that has now been created is not the database itself, it the connector we use to 
# query the file that has been created in the directory.

### 4 - Setting up the CTT extraction function: ######

# So now we have all the packages installed, the API key to access CTT, and a database prepared
# to handle the masses of data incoming. So now it's time to get that data:

# First, we need to assign a few key terms for the data function:

# 1. The name of the project we are accessing:

# IMPORTANT! - You will notice below there is a space after 'Scotland'. This is how the project
# is named on the CTT database so we have to copy it.
myproject <- "RSPB Scotland "

# 2. The base station(s) to access:

# I'm pulling these directly from CTT, they are the base station ID's.
# Central <- "V3023D3653A8", South <- "V3023D3656DE", Coquet <- "V3023D363B93"
# These will be more useful later when filtering the database so I have actually hashed them out,
# good to keep here for reference, and are used properly in section 7.

# 3. The search dates:

# We could go about this in a number of ways, and so these can be changed accordingly.

# Since this is the first time running the script, we want to extract all the data from CTT. 
# Let's do this by setting the date to the first point of tag deployment in 2025 (on-bird), which
# was 07/06/2025:
startdate <- as.Date("2025-06-07")
# We can make this end date today's date, since we want all the data that's currently in the CTT system.
enddate <- as.Date(Sys.Date())

# 4. The export directory:

# We want to make an export folder within our internal R directory for the function to store things
# to. This needs to be the same name as our project, so I am calling the 'myproject' object:
temp <- "./data/"
celltracktech::create_outpath(paste0(temp, "/", myproject))
rm(temp)

# 5. The export folder:

# Make a folder in the project directory that the data will export to. This is different to the
# above internal direccory, this is an actual folder that data could be put in to.
outpath <- dir
dir.create(file.path(outpath, myproject), recursive = TRUE, showWarnings = FALSE)

### 5 - Running the CTT download function on all historic data! ######

# Now to run the code! This is going to make a lot of console scroll and download a lot of files,
# the laptop will prepare for take off! Set aside some time to leave this running, over a lunch break or even over
# night. It won't always take this long, once this historical back log is downloaded the iterative database 
# update (sections below) only takes a few minutes.

# NOTE: You will probably get a 'gateway error' message pop up on the first time you run this (in any R session).
# Just ignore it and run the code again. That is the actual advice from the CTT people...

celltracktech::get_my_data(
  my_token = my_token,                    # API key to access CTT
  outpath = outpath,                      # Where the files are downloaded
  db_name = CTTdatabase,                  # The SQL relational database
  myproject = myproject,                  # The name of the project on the CTT account
  begin = startdate,                      # Start date of the CTT query
  end = enddate,                          # End date of the CTT query
  filetypes = c("blu"))                   # What files we want from CTT, here 2.4GHz

# The other options for file types are listed here in case, and are detailed in the tutorial
# linked at the top of this script:
# filetypes = c("raw", "blu", "gps", "node_health", "sensorgnome", "telemetry", 'log'))

## ONCE COMPLETE:

# This function has downloaded all the data files from CTT for all the base stations linked to our account.

### 6 - Moving the bulk downloaded data back into R: ######

# The above function downloaded all the CTT files into the directory you established, but they are not yet 
# present in R in any capacity. As mentioned, we don't want to load them all into R itself, this will make our
# laptops suffer dearly. Instead we want to use that relational database we set up...

# Upload the compressed data (the ‘.csv.gz’ files you just downloaded) into your 
# relational database:

CTTdatabase <- DBI::dbConnect(duckdb::duckdb(), 
                              dbdir = paste0(dir, "/", "CTTquery.duckdb"),
                              read_only = FALSE)

celltracktech::create_database(my_token = my_token,
                               outpath = outpath,
                               myproject = myproject,
                               db_name = CTTdatabase)

# The crucial thing here - you do not load this duckdb database into R, you query it. So it exists
# as a file in your directory, and you use functions within R to investigate the data it contains.
# This stops R becoming overloaded with data.

dbListTables(CTTdatabase)
# So we can see this lists all the databases that were exported from CTT.

###

# So that's it for the historic download, woo! The next sections detail how to update this database with new data.

### UPDATING THE EXISTING CTT DATABASE: ######
### 7 - Updating the CTT database and summarising recent detections: ######

# Read in the packages needed:

require(DBI); require(duckdb); require(stringr); require(R.utils); require(duckplyr);
require(dplyr); require(celltracktech); require(ggplot2)

# First, let's reconnect to this database, and see where we last downloaded to:

# Re-assign your directory, this will be the one you used before:
dir <- "C:/Users/LewisLancaster/OneDrive - THE ROYAL SOCIETY FOR THE PROTECTION OF BIRDS/Lewis' Files/MOTUS CTT Data"

CTTdatabase <- DBI::dbConnect(duckdb::duckdb(), 
                              dbdir = paste0(dir, "/", "CTTquery.duckdb"),
                              read_only = FALSE)

# The below loop is going to run everything needed to update the database and pull out summary
# statistics in a single run function. The codes inside the loop are still annotated though so you
# can follow along.

# NOTE:
# If you get the bad gateway error message as before, just ignore and re-run the loop
# (this isn't me making lazy code, this is the official CTT package advice...)

# NOTE FOR THIS DATABASE UPDATE RUN:
# You may get an error stating that a file already exists in the database, and this has caused the loop to crash.
# Easy fix though! Just re-run the 'lastiteration' command and get a new start date, this will be up to where the
# dupe error occurred. Then re-run the function and it will carry on. This can be done also by just rerunning the loop,
# (and is much easier this way rather than running specific lines) but wanted to give full troubleshoot details. 

for(i in 1){
  
  ### Updating the CTT database with new detection data:
  
  # Ensure the directoty is present:
  dir <- "insert file directory here"
  
  # Let's pull out the most recent detection date in the database, that will tell us when to run
  # this update from:
  lastiteration <- as.Date(dbGetQuery(CTTdatabase, "SELECT MAX(time) AS latest_detection FROM blu")[1,1])
  
  # Now we can set a start date for two days prior to the date of last download, just to give a buffer:
  startdate <- lastiteration
  rm(lastiteration)
  
  # For the end date, set this to tomorrow. This is because the function cuts the download off at midnight of
  # the end date. So if we put today it will cut off from last night, by setting to tomorrow this gives us all the
  # current CTT data:
  enddate <- as.Date(Sys.Date()) + 1
  
  # Before we re-run the CTT download, we can fact check this database update by pulling out the
  # number of detections before adding in the new files:
  priorcount <- as.numeric(dbGetQuery(CTTdatabase, "SELECT COUNT(*) FROM blu"))
  
  # Write in the CTT specific objects we need (all axplained in sections 1-6):
  my_token <- "insert API key here"
  myproject <- "RSPB Scotland "
  outpath <- dir
  
  print(ls())
  
  # Now re-run with the updated date window:
  celltracktech::get_my_data(
    my_token = my_token,                    
    outpath = outpath,                      
    db_name = CTTdatabase,                  
    myproject = myproject,                  
    begin = startdate,                      
    end = enddate,                          
    filetypes = c("blu"))
  
  # Now update the relational database with the new data:
  celltracktech::update_db(CTTdatabase, outpath, myproject)
  
  # Clean up a little and remove those function objects:
  rm(dir, enddate, my_token, myproject, outpath, startdate)
  
  # The console the function talks to you as it is working. One of things it says is 
  # 'getting station file list' followed by 'got the file list; comparing against the files'
  # and finally 'comparison complete... about to get XXX files' 
  
  # So it 'appears' to compare what it is going to download against what we already have, but 
  # this isn't fool proof.
  
  # Before we continue, the 'duckdb' package does not guarantee that these processes will not create
  # dupe rows, particularly since we are enforcing an overlap between past iterations and the current
  # one. So let's quickly check for and clear duplicates:
  
  # If this isn't the first time running this command, then the duplicate tables will already exist
  # in the relational database. So we need to delete them if they exist, then reinstate them:
  
  # Remove old temp tables if they exist
  DBI::dbExecute(CTTdatabase, "DROP TABLE IF EXISTS blu_backup")
  DBI::dbExecute(CTTdatabase, "DROP TABLE IF EXISTS blu_dedup")
  
  # Optional backup first:
  DBI::dbExecute(CTTdatabase, "CREATE TABLE blu_backup AS SELECT * FROM blu")
  # Create a deduplicated copy:
  DBI::dbExecute(CTTdatabase, "CREATE TABLE blu_dedup AS SELECT DISTINCT * FROM blu")
  # Swap it in for the raw downloaded copy:
  DBI::dbExecute(CTTdatabase, "DROP TABLE blu")
  DBI::dbExecute(CTTdatabase, "ALTER TABLE blu_dedup RENAME TO blu")
  
  # It may well be that there are no duplicated rows (as was the case when setting this up), but this
  # is a sensible check to make:
  
  # Check that this has added new data to the CTT database:
  newcount <- as.numeric(dbGetQuery(CTTdatabase, "SELECT COUNT(*) FROM blu"))
  
  if(newcount > priorcount){
    print(paste("Directory update successful:", (newcount-priorcount), "new detections downloaded"), sep = " ")
  } else{
    print("No new detections downloaded")
  }
  
  # Clean up a little bit now that we have ran the duplication check:
  rm(newcount, priorcount)
  
}

rm(i)

### 8 - Pulling out some summary tables from the new (and historic) CTT detection data: ######

# First things first, let's see the most recent detection from each base station, and see how many
# tags have been detected in the last 7 and 30 days:

recentsumary <- data.frame(matrix(nrow = 4, ncol = 5)); colnames(recentsumary) <- c("Station", "StationID", "LastDetection", "PastMonthTagCount", "PastWeekTagCount")
recentsumary$Station <- c("Central", "South", "Coquet/North", "Mobile")
recentsumary$StationID <- c("V3023D3653A8", "V3023D3656DE", "V3023D363B93", "V3023D36E994")

# Get the most recent detection timestamp for each base station. It does this by subsetting for
# each station ID and then finding the highest (most recent) timestamp linked to a detection:

foo <- dbGetQuery(CTTdatabase, "
  SELECT
    station_id,
    MAX(time) AS last_detection
  FROM blu
  GROUP BY station_id
  ORDER BY last_detection DESC
  ")

# Now map that into the summary table:
recentsumary$LastDetection <- as.POSIXct(NA)
for(j in 1:4){
  recentsumary$LastDetection[j] <- as.POSIXct(foo$last_detection[which(foo$station_id == recentsumary$StationID[j])], format = "%Y-%m-%d %H:%M:%S")
}
rm(foo, j)

# Now extract the number of tags detected by base stations in the last 30 days. We do this by 
# converting the time within the 'blu' files to timestamps, and setting a threshold of the current
# timestamp minus 30 days. It then filters this subset of data for unique tag ID's and splits
# that by station ID:

foo <- dbGetQuery(CTTdatabase, "
  SELECT
    station_id,
    COUNT(DISTINCT tag_id) AS unique_tags
  FROM (
    SELECT
      station_id,
      tag_id,
      CAST(time AS TIMESTAMP) AS detection_time
    FROM blu
  )
  WHERE detection_time >= CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - INTERVAL 30 DAY
  GROUP BY station_id
  ORDER BY unique_tags DESC
  ")

if(nrow(foo) > 0){
  
  # Now we can map that into the summary table:
  for(j in 1:nrow(recentsumary)){
    
    # Not all stations will have detected a tag in the past week, so this filters for that:
    if(recentsumary$StationID[j] %in% foo$station_id){
      recentsumary$PastMonthTagCount[j] <- foo$unique_tags[which(foo$station_id == recentsumary$StationID[j])]
    } else{
      recentsumary$PastMonthTagCount[j] <- 0
    }
  }
  
}

rm(foo, j)

# If no tags have been detected in a month, then set those values to zero:
recentsumary$PastMonthTagCount[which(is.na(recentsumary$PastMonthTagCount))] <- 0

# Now, repeat that above query but for the past week rather than past month:
foo <- dbGetQuery(CTTdatabase, "
  SELECT
    station_id,
    COUNT(DISTINCT tag_id) AS unique_tags
  FROM (
    SELECT
      station_id,
      tag_id,
      CAST(time AS TIMESTAMP) AS detection_time
    FROM blu
  )
  WHERE detection_time >= CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - INTERVAL 7 DAY
  GROUP BY station_id
  ORDER BY unique_tags DESC
  ")

if(nrow(foo) > 0){
  
  # Now we can map that into the summary table:
  for(j in 1:nrow(recentsumary)){
    
    # Not all stations will have detected a tag in the past week, so this filters for that:
    if(recentsumary$StationID[j] %in% foo$station_id){
      recentsumary$PastWeekTagCount[j] <- foo$unique_tags[which(foo$station_id == recentsumary$StationID[j])]
    } else{
      recentsumary$PastWeekTagCount[j] <- 0
    }
  }
  
}


# If no tags have been detected in a week, then set those values to zero:
recentsumary$PastWeekTagCount[which(is.na(recentsumary$PastWeekTagCount))] <- 0

rm(foo, j)

###

# The last query database we want to make is a summary of all tags, when they were last
# detected, where, and what the tag is:

# This will give us the last detection of each tag, and when and where it was:
lastseen <- dbGetQuery(CTTdatabase, "
  SELECT tag_id, station_id, time
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (
             PARTITION BY tag_id
             ORDER BY time DESC
           ) AS rn
    FROM blu
  )
  WHERE rn = 1
  ")

# Lets put this in descending time for ease:
lastseen <- lastseen %>% arrange(desc(time))

# Clean up the naming:
colnames(lastseen) <- c("TagID", "StationID", "LastDetection")

# Add an identifier to the database to tell us whether the tag is a test or on-bird tag:
lastseen$TagType <- "NA"
lastseen$TagType[which(lastseen$TagID %in% c("5EAD9E2E", "06B8E5AE"))] <- "AT_STATION"
lastseen$TagType[which(lastseen$TagID %in% c("06FE06EF"))] <- "COQUET_STATION"
lastseen$TagType[which(lastseen$TagID %in% c("5DBCD9E0"))] <- "TEST?"
lastseen$TagType[which(lastseen$TagID %in% c("E0A0211A",
                                             "01AEB356",
                                             "8A88B621",
                                             "34414CC1",
                                             "5232A472",
                                             "6B3199C4",
                                             "2C3AD442",
                                             "89E2FB9F",
                                             "9EB1F6D1",
                                             "0B7059E9",
                                             "EACEA00E",
                                             "2D02AF20",
                                             "4ACB61C2",
                                             "A2C40F82",
                                             "B324E1C2",
                                             "78728BEC",
                                             "D2CAFBFA",
                                             "B348C3E0",
                                             "2207E427",
                                             "BC8027D7"))] <- "ON_BIRD"

# Again for ease let's also name the station:
lastseen$Station <- NA

for(j in 1:nrow(lastseen)){
  lastseen$Station[j] <- recentsumary$Station[which(recentsumary$StationID == lastseen$StationID[j])]
}
rm(j)

# Just reordering the columns for ease of interpretting:
lastseen <- lastseen[, c(1, 4, 3, 5, 2)]

# We can chop off 2025 data here if we want:
lastseen2026 <- lastseen[which(lastseen$LastDetection > as.POSIXct("2026-01-01 00:00:00")), ]

### 9 - Additional queries and filters the CTT tag database (playground): ######

# This query returns a list of all tags detected across all the stations, and lists the number
# of detections per station:

tagcounts <- dbGetQuery(CTTdatabase, "
  SELECT tag_id, station_id, COUNT(*) AS n
  FROM blu
  GROUP BY tag_id, station_id
  ORDER BY tag_id, station_id
")

tagcounts$Station <- NA
for(i in 1:nrow(tagcounts)){
  tagcounts$Station[i] <- recentsumary$Station[which(recentsumary$StationID == tagcounts$station_id[i])]
}
rm(i)
tagcounts <- tagcounts[, c(1,4,3)]; colnames(tagcounts) <- c("TagID", "Station", "DetectionCount")
View(tagcounts)

# This function can be used to query a specific tag, and tell us where and when it was detected:

get_tag_detections <- function(CTTdatabase, tag_id) {
  query <- DBI::sqlInterpolate(
    CTTdatabase,
    "
    SELECT
      tag_id,
      station_id,
      time
    FROM blu
    WHERE tag_id = ?tag_id
    ORDER BY time
    ",
    tag_id = tag_id
  )
  
  DBI::dbGetQuery(CTTdatabase, query)
}

# Change the tag ID here to match the one that you want (a list of them can be seen from the 
# other output files such as 'lastseen')

TagQuery <- "58548BFA"
TagQuery <- get_tag_detections(CTTdatabase, TagQuery)

TagQuery <- TagQuery %>%
  left_join(
    recentsumary %>% select(StationID, Station),
    by = c("station_id" = "StationID")
  ) 

TagQuery <- TagQuery[, c(1,4,3)]; colnames(TagQuery) <- c("TagID", "Station", "DetectionTime")

# Plot the detections of this specific tag (in this case Billy):
ggplot(TagQuery, aes(x = DetectionTime)) +
  geom_linerange(aes(ymin = 0, ymax = 1)) +
  scale_y_continuous(breaks = c(0, 1)) +
  labs(title = "Billy's Coquet Visits")



last_detections <- dbGetQuery(
  con,
  "
  SELECT
      tag_id,
      MAX(timestamp) AS last_detection,
      arg_max(base_station, timestamp) AS last_base_station
  FROM detections
  GROUP BY tag_id
  "
)


### 10 - Plotting the historical tag detections: ######

# This plot will give us a timeline of all tags (which can be filtered for meaningful tags)
# detections through any given time period.

# Lets isolate the tags that are either on birds or at base stations: 
Wanted <- lastseen$TagID[which(lastseen$TagType %in% c("AT_STATION", "ON_BIRD"))]

temp <- list()

for(i in 1:length(Wanted)){
  
  foo <- get_tag_detections(CTTdatabase, Wanted[i])
  temp[[i]] <- foo
  
}
rm(foo, i, Wanted)

Detections <- bind_rows(temp)
rm(temp)

Detections$tag_id <- as.factor(Detections$tag_id)

# create detection summary data frame and sort it based on last detection date
Detections <- Detections[order(Detections$time, decreasing = TRUE), ]

# create a heat-bin plot, with the bins reperesenting time periods, and the color representing the number of detections
ggplot(data = Detections, aes(x = time, y = tag_id)) +
  geom_bin2d(binwidth = c(3600, 1)) + # Hour time bins
  scale_fill_continuous(type = "viridis") +
  labs(x = "Timestamp", 
       y = "Tag ID") +
  theme_minimal()

# This is great, but with the context lets cut it to the summer of 2025:
Detections2025 <- Detections[which(Detections$time < "2026-01-01 00:00:00"), ]

ggplot(data = Detections2025, aes(x = time, y = tag_id)) +
  geom_bin2d(binwidth = c(3600, 1)) + # Hour time bins
  scale_fill_continuous(type = "viridis") +
  scale_x_datetime(limits = c(min(Detections2025$time) - 3600*24, "2025-09-01 00:00:00"),
                   date_breaks = "7 days", date_labels = "%d %b") +
  labs(x = "Timestamp", 
       y = "Tag ID",
       fill = "Detections") +
  theme_minimal()

############




