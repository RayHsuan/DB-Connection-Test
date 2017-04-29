#---------------get data from MySQL--------------------------------

##Install package for the first time
#install.packages("MySQL")  #install.packages("dbConnect") Not really necessary

library(RMySQL) #can ignore the "required package: DBI" temporary
#library(dbConnect)
drv = dbDriver("MySQL")

#use your owen DB name and password to build DB connection
con = dbConnect(drv,user="root",host="localhost",dbname="testdb", password="0000")
dbSendQuery(con,'SET NAMES utf8 ')
#Show your all of your tables/collections
dbListTables(con)

data(iris)
iris

#write data in DB
dbWriteTable(con, "iris", iris ,row.names=FALSE,append=TRUE)
dbListTables(con)
df = dbGetQuery(con,"select * from iris where species = 'versicolor'")
head(df)

dbRemoveTable(con, "iris")
dbListTables(con)
dbDisconnect(con)

#---------------get data from mongoDB--------------------------------
#Using devtools::install_github can easily install any R package on GitHub:
#  To install devtools make sure you have:
#1.Rtools on Windows
##https://cran.r-project.org/bin/windows/Rtools/
#2.Xcode command line tools for Mac
##https://developer.apple.com/downloads
#3.r-devel or r-base-dev on Linux

##Install these packages for the first time
#install.packages("devtools")
#devtools::install_github("mongosoup/rmongodb")
#https://github.com/dselivanov/rmongodb  == 
#https://github.com/dselivanov/rmongodb/releases


# make sure you open your local mongoDB
#cd C:\Program Files\MongoDB\Server\3.4\bin
#mongod.exe --dbpath C:\mongodb\data

#Examples
#http://www.joyofdata.de/blog/mongodb-state-of-the-r-rmongodb/
#https://gist.github.com/Btibert3/7751989
library(rmongodb)

mongo = mongo.create(host = "localhost")
mongo.is.connected(mongo)

#Show your all of your Database
mongo.get.databases(mongo)

#Easy test here
list <- list(a=2, b=3, c=list(d=4, e=5))
bson <- mongo.bson.from.list(list) # list
mongo.insert(mongo, "Test.t123", bson)
json <- '{"a":1, "b":2, "c": {"d":3, "e":4}}'
bson <- mongo.bson.from.JSON(json) # json
mongo.insert(mongo, "Test.t123", bson)

#data(iris)
#head(iris)
df.iris = mongo.bson.from.df(iris) #dataframe as document
mongo.insert(mongo,"Test.iris",df.iris) 

#Query DB approach 1 
iris.json = mongo.find.one(mongo, ns = "Test.iris")
iris.json
class(iris.json)
names(iris.json)
find_all = mongo.find.all(mongo, ns = "Test.t123")
find_all

#Query DB approach 2 => You need a cursor...
json_qry <- '{ "1.Species": { "$in": [1,2,3]}}'
a <- mongo.find(mongo, "Test.iris", mongo.bson.from.JSON(json_qry))
b <- mongo.find(mongo, "Test.iris", json_qry)
c <- mongo.find(mongo, "Test.iris", '{ "b": 3.0 }')
c

#It's an example of cursor from internet... 
#mongo.disconnect(mongo)
library(plyr)
## create the empty data frame
gameids = data.frame(stringsAsFactors = FALSE)

## create the namespace
DBNS = "Test.t123"

## create the cursor we will iterate over, basically a select * in SQL
cursor = mongo.find(mongo, DBNS)

## create the counter
i = 1

## iterate over the cursor
while (mongo.cursor.next(cursor)) {
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  # From a list to a dataframe
  tmp.df = as.data.frame(t(unlist(tmp)), stringsAsFactors = F)
  # bind to the master dataframe
  gameids = rbind.fill(gameids, tmp.df)
  # to print a message, uncomment the next 2 lines cat('finished game ', i,
  # '\n') i = i +1
}
mongo.disconnect(mongo)
