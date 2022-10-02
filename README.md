# wwMongoDb

<img src="wwMongoDb.png" align="left" />

#### A small library to access MongoDb from Visual FoxPro

wwMongoDb is a library that allows you to access MongoDb from Visual FoxPro. 
wwMongoDb works using the MongoDb C# driver and provides a simple CRUD and
JSON string based interface that allows FoxPro to interact  with MongoDb 
via JSON commands and FoxPro serialized objects.

Please also check:

* [Change Log](changelog.md)
* [MongoDb Documentation](http://docs.mongodb.org/manual/)
* [C# MongoDb Driver Documentation](http://api.mongodb.org/csharp/current/)


### How it Works
This library works through a number of layers to access MongoDb:

* A FoxPro class that interacts with your code 
* wwDotnetBridge which provides the interface to call .NET code
* A custom Westwind.Data.MongoDb .NET component that marshals commands to the MongoDb driver
* Westwind.Data.MongoDb exposes high level single call operations callable from FoxPro
* Results are captured as JSON data and marshalled back to the FoxPro class
* The FoxPro class turns the results into FoxPro objects to return to your code

### What you need
In order to use and play with this library you will need a number of things:

* A local or remote instance of [MongoDb](http://www.mongodb.org/downloads "MongoDb Downloads") where you have access to create data (install instructions)
* Microsoft [.NET 4.0](http://www.microsoft.com/net/downloads ".NET Download") or later
* [FoxUnit](http://vfpx.codeplex.com/wikipage?title=FoxUnit "FoxUnit Download") (for checking out the samples)
* Recommended: [RoboMongo](http://robomongo.org/ "RoboMongo Download") - A simple IDE for querying and viewing MongoDb data 

In order to use this library you will have a number of dependencies, which you can find in the Dist folder of this project. Essentially you have:

* wwMongoDb.prg - Main class your code interfaces with
* classes Folder - FoxPro support classes
* wconnect.h - required for support classes
* wwDotnetBridge.dll/wwIPstuff.dll - .NET interface libraries
* Newtonsoft.json.dll - JSON library
* bin\Westwind.Data.MongoDb - wwMongoDb interface libary
* bin\MongoDb.Driver\.Bson - MongoDb .NET Driver libary

To use these files copy them into your application's root folder or anywhere where they are
accessible in the FoxPro path. All three folders (root/classes/bin) need to be added to 
the FoxPro path. If you like you can also simply put all files into a single folder.

### Getting Started
To run any code in the installation folder make sure you launch FoxPro in the installation
folder which uses config.fpw to set paths. 

Otherwise set your environment like this:

```
CD <installFolder>\Fox
DO _config
``` 

Make sure that MongoDb is running. The demos assume you're running MongoDb on the local
machine on the default port (27017). If you're running on a different server, or you use 
a different port make sure to adjust the connection string.

To start MongoDb locally, you can use:

```
c:\mongoDb> MongoD 
```

to start the server from the command line or follow the instructions on the MongoDb site
for setting up MongoDb as a service. I like to also add the MongoDb folder to my PATH environment
variable so I can access the server and the shell easily.

Once everything is running you can go to the FoxPro command prompt and do:

```foxpro
DO test
```

which runs a few simple commands to show basic operation. For more detailed examples you
can look at the FoxUnit tests in tests\BasicMongoDbsamples.prg and run those tests in FoxUnit.

### Data Operations with wwMongoDb
Now you're ready to run a few operations.

#### Connecting to MongoDb
```foxpro
*** Load library and dependencies
DO wwMongoDb

*** Create the actual Fox instance
loMongo = CREATEOBJECT("wwMongoDb")

*** Connect to the MongoDb Server and Database
*** if the Db doesn't exist it auto-creates
IF !loMongo.Connect("mongodb://localhost/FoxMongoTest")
   ? "Unable to connect to MongoDb: " + loMongo.cErrorMsg
   RETURN
ENDIF
```
In order to access MongoDb data you need to first create an instance and then connect to a specific server and database.

The connection string supports the following URL Moniker syntax:

	mongodb://username:password@servername:port/database

if no port is specified the default 27017 port is used. Username and password are optional and only required if you set up your database with a logon username and password.

I recommend that you create an instance of the wwMongoDb object once and then store it somewhere persistent in your application: On an application or server object so it can be used without re-creating an instance for each connection. Unlike SQL server, Mongo creates new connections on each request, so there's no 'persistent' connection to the server.

#### Save Data from a Fox Object
*(and create Db/Table if it doesn't exist)*

```foxpro
*** Load library and dependencies
DO wwMongoDb

loMongo = CREATEOBJECT("wwMongoDb")

*** connects to localhost and FoxMongoTest Db
*** if the Db doesn't exist it auto-creates
loMongo.Connect("mongodb://localhost/FoxMongoTest")

*** Create an object to persist
*** Note objects are serialized as lower case
loCustomer = CREATEOBJECT("EMPTY")

*** Recommend you assign your own ids for easier querying
ADDPROPERTY(loCustomer,"_id",loMongo.GenerateId())
ADDPROPERTY(loCustomer,"FirstName","Markus")
ADDPROPERTY(loCustomer,"LastName","Egger")
ADDPROPERTY(loCustomer,"Company","EPS Software")
ADDPROPERTY(loCustomer,"Entered", DATETIME())

loAddress = CREATEOBJECT("EMPTY")
ADDPROPERTY(loAddress,"Street","32 Kaiea")
ADDPROPERTY(loAddress,"City","Paia")
ADDPROPERTY(loCustomer,"Address",loAddress)

*** Create child orders (one to many) 
loOrders = CREATEOBJECT("Collection")
ADDPROPERTY(loCustomer,"Orders",loOrders)

loOrder = CREATEOBJECT("Empty")
ADDPROPERTY(loOrder,"Date",DATETIME())
ADDPROPERTY(loOrder,"OrderId",SUBSTR(SYS(2015),2))
ADDPROPERTY(loOrder,"OrderTotal",120.00)
loOrders.Add(loOrder)

loOrder = CREATEOBJECT("Empty")
ADDPROPERTY(loOrder,"Date",DATETIME())
ADDPROPERTY(loOrder,"OrderId",SUBSTR(SYS(2015),2))
ADDPROPERTY(loOrder,"OrderTotal",120.00)
loOrders.Add(loOrder)


*** NOW SAVE THE OBJECT
this.AssertTrue(loMongo.Save(loCustomer,"Customers"),loMongo.cErrorMsg)


this.AssertTrue(loCustomer._id == loMongo.oLastResult.Id,"Own id shouldn't be updated")

this.MessageOut("ID Generated: " + loMongo.oLastResult.Id)   
```
Note that you can either assign an Id explicitly as I did here (recommended), or you
can let MongoDb auto-create an id. Auto-created Ids are returned on a oLastResult object
as:

```foxpro
lcId = loMongo.oLastResult.Id
```

You can also check for errors on a Save operation:

```foxpro
IF !loMongo.Ok
	? loMongo.oLastResult.Message
    RETURN
ENDIF
```

Note that error messages from Mongo can be sketchy and often don't return any message info.
Your mileage may vary. It's usually best to check the result value for the function and if it's not returning the type you're expecting you have an error to deal with.

#### Save an object using a JSON String
You can also save object using JSON strings, although I'm not sure how useful that is as you essentially have to create the JSON structures to save. Note also that MongoDb uses a special JSON dialect that encodes certain fields like dates in a special way. Regardless it is possible to dynamically create strings and save them using the following code:

```foxpro
loMongo = this.CreateMongo()

*** Note objects are serialized as lower case
loCustomer = CREATEOBJECT("EMPTY")

TEXT TO lcJson TEXTMERGE NOSHOW
{
    _id: "<<loMongo.GenerateId()>>",
    FirstName: "Rick",
    LastName: "Strahl",
    Company: "West Wind",
    Entered: "<<TTOC(DATETIME(),3)>>Z",
    Address: {
        Street: "32 Kaiea",
        City: "Paia"
    },
    Orders: [
        { OrderId: "ar431211", OrderTotal: 125.44, Date: "<<TTOC(DATETIME(),3)>>Z"},
        { OrderId: "fe134341", OrderTotal: 95.12, Date: "<<TTOC(DATETIME(),3)>>Z" }
    ]
}
ENDTEXT

this.AssertTrue(loMongo.Save(lcJson,"Customers",.T.),loMongo.cErrorMsg)

*** Another way to check for errors
this.AssertTrue(loMongo.oLastResult.Ok,loMongo.oLastResult.Message)

lcId = loMongo.oLastResult.Id
this.MessageOut("ID Generated: " + lcId)
```
Note the date encoding - if you use strings you're responsible for providing the proper format  for non string values and escaped strings for string values.

Although the above is possible I highly recommend you send data as objects as the wwMongoDb serialization automatically handles the proper MongoDb compatible JSON encoding for most types.

#### Query: Read a Collection of Items based on a filter
You can query using MongoDb JSON syntax for providing the filter expressions:

```
loMongo = this.CreateMongo()
loCustomers = loMongo.Find('{ firstname: "Rick" }',"Customers")

this.AssertNotNull(loCustomers,"Customers shouldn't be null")

FOR lnX = 1 TO loCustomers.Count
   loCustomer = loCustomers[lnX]

   *** NOTE: MongoDb dates come back as objects so use GetDate()
   this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")
ENDFOR
```
You can use any valid search operations that are part of the MongoDb JSON vocabulary (as shown in
most articles and books).

For example the following find all entries that start with an R using a RegEx expression (which is legal in JSON/JavaScript):

```foxpro
*** Search parameters and skip 30 and limit to 10 items
loCustomers = loMongo.Find('{ firstname: /^R.*/i, entered: { $gt: new Date(2014,12,1) }',;
                           "Customers",30,10)
```

#### Returning a single Entity
```foxpro
loMongo = this.CreateMongo()

loCustomer = loMongo.FindOne('{ firstname: "Rick" }',"Customers")

this.AssertNotNull(loCustomer,"Customers shouldn't be null")

*** NOTE: MongoDb dates come back as objects so use GetDate()
this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")
```

You can also use the Load() method to retrieve a single entity by ID.

#### Returning an Entity by ID

```foxpro
lcID = "SomeIdYouCaptured"

loMongo = this.CreateMongo()

loCustomer = loMongo.Load(lcId,"Customers")

this.AssertNotNull(loCustomer,"Customers shouldn't be null")

*** NOTE: MongoDb dates come back as objects so use GetDate()
this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")
```

#### Accessing Nested Objects and Collections
Because MongoDb stores hierarchical data you can retrieve nested objects that can 
contain child objects or collections. wwMongoDb deserializes those objects and
collections as FoxPro objects and FoxPro collections. The previous two examples
retrieved customer objects - and you can also access the child entities like this:

```foxpro
*** Child Object
IF !ISNULL(loCustomer.Address)
   this.MessageOut( "   " + loCustomer.Address.Street + ", " +;
                    loCustomer.Address.City )
ENDIF

*** Child Collection                
IF !ISNULL(loCustomer.Orders)     
    FOR lnx=1 TO loCustomer.Orders.Count   
		loOrder = loCustomer.Orders[lnX]
	    this.MessageOut( "    " + TRANSFORM(loMongo.GetDate(loOrder.Date))  + "  " + ;
	    				 loOrder.OrderId + " " + TRANSFORM(loOrder.OrderTotal) )
	ENDFOR        
ENDIF                                
```

MongoDb can return nested objects/arrays. Arrays are returned as Collections in FoxPro. 

#### Aggregations
You can also access MongoDb's Aggregation Pipeline. The Aggregation pipeline allows for aggregate queries using grouping and summarizing of data. To use this feature you can use the `Aggregate` method and provide a string that holds an array of the various pipeline commands.

```foxpro
loMongo = this.CreateMongo()

TEXT TO lcJson NOSHOW
[    
       { $project: { Company: "$Company", OrderCount: { $size: "$Orders" }} },
       { $match: {                   
              Company: {$gte: "F" },
              OrderCount: { $gt: 0 }
           }
      },
      { $group: {         
          _id: "$Company", 
          CustomerCount: {$sum: 1 } ,
          OrderCount: {$sum: "$OrderCount" }
        }          
     }
]
ENDTEXT

loResults = loMongo.Aggregate(lcJson,"Customers")
this.AssertNotNull(loResults,loMongo.cErrorMsg)

lnCount = loResults.Count
this.MessageOut(TRANSFORM(lnCount) + " results")
FOR lnX = 1 TO lnCount
   loResult = loResults[lnX]
   this.MessageOut( TRANSFORM(loResult._id) + ;
                    "  Cust Count: " + TRANSFORM(loResult.CustomerCount) + ;
                    "  Order Count: " + TRANSFORM(loResult.OrderCount) )
ENDFOR
```

You provide the aggregation pipeline as an array of documents. The most common ones are $match and $group as well as $project. Note that you can run multiple $match,$project,$group cycles to process results multiple times consequetively.

[http://docs.mongodb.org/manual/reference/operator/aggregation/](http://docs.mongodb.org/manual/reference/operator/aggregation/)

#### Deleting Entities
There are a number of ways to delete entities.

**Delete an individual entity by id:**
```foxpro
loMongo = this.CreateMongo()

*** Retrieve an id
lcId = "someIdFromSomewhere"

IF !loMongo.Delete(lcId,"Customers")
   ?"Customer not deleted: " + loMongo.cErrorMsg)
   RETURN
ENDIF

? "Deleted entities: " + TRANS(loMongo.oLastResult.DocumentsAffected)
```

**Delete multiple entities based on a filter:**
```foxpro
loMongo = this.CreateMongo()

llResult = loMongo.Delete('{ firstname: "Markus" }',"Customers")

IF !llResult
   ? "Delete operation failed: " + loMongo.cErrorMsg
   RETURN
ENDIF

? "Documents deleted: " + TRANSFORM(loMongo.oLastResult.DocumentsAffected)
```

**Delete all entities:**

```foxpro
loMongo = this.CreateMongo()
loCollection = loMongo.GetCollection("Customers")
loMongo.oBridge.InvokeMethod(loCollection,"RemoveAll")
```

**Drop a collection:**
```foxpro
loMongo = this.CreateMongo()
loCollection = loMongo.GetCollection("Customers")
loMongo.oBridge.InvokeMethod(loCollection,"Drop")
```

### Running FoxUnit Tests
The best way to check out examples is to run the FoxUnit tests in the tests\ folder.
The test classes can be easily run from within FoxUnit. To use FoxUnit:

* [Download FoxUnit](http://vfpx.codeplex.com/wikipage?title=FoxUnit)
* Install FoxUnit in a folder of your choice
* Add the FoxUnit to the FoxPro path. Add both the root and \sources
* Run FoxUnit with `DO FoxUnit`
* Use Load Class and find the \tests folder and PRG files
* Run selected or all tests
* Double click to jump to code

### Project Sponsors
The following people/organizations have provided sponsorship to this project by way of direct donations or for paid development as part of a project:

* **Marty Glynn**<br/>
Marty was the original sponsor who requested the basic feature set for accessing
MongoDb.

* **John Harris - Unifier 2 Group**<br/>
John offered early support and feedback for this project and as well as a 
sizable donation for the original development.

* **Dan Martin - WeatherMaker**<br/>
Dan and his company provided several of my billable hours dedicated to this project 
for adding a few small enhancements and bug fixes.

Want to sponsor this project or make a donation? You can contact me directly at rstrahl@west-wind.com or you can also make a donation online via PayPal.

* [Make a donation for wwMongoDb using PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=T377Y7VNFA554)
* [Make a donation for wwMongoDb using our Web Store](http://store.west-wind.com/product/donation)

### License
This library is published under MIT license terms:

Copyright &copy; 2014 Rick Strahl, West Wind Technologies

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
