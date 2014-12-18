# wwMongoDb

#### A small library to access MongoDb from Visual FoxPro

***Under Construction - prototype stage***


wwMongoDb is a library that allows you to access MongoDb from Visual FoxPro by way of
.NET which acts as small shim. wwMongoDb works using the MongoDb C# driver and providing
a string based interface that allows FoxPro to interact with MongoDb via JSON commands.

### How it Works
This library works through a number of layers to access MongoDb:

* A FoxPro class that interacts with user code 
* The class uses wwDotnetBridge to call into .NET
* The class calls a custom Westwind.Data.MongoDb component
* The component exposes high level single call operations callable from FoxPro
* The component calls into the MongoDb driver to run Mongo Db operations
* Results are captured as JSON data and marshalled back to the FoxPro class
* The FoxPro class turns the results into FoxPro objects to return to user code


### Getting Started
In order to use and play with this library you will need a number of things:

* A local or remote instance of [MongoDb](http://www.mongodb.org/downloads "MongoDb Downloads") where you have access to create data (install instructions)
* Microsoft [.NET 4.0](http://www.microsoft.com/net/downloads ".NET Download") or later
* [FoxUnit](http://vfpx.codeplex.com/wikipage?title=FoxUnit "FoxUnit Download") (for checking out the samples)
* Recommended: [RoboMongo](http://robomongo.org/ "RoboMongo Download") - A simple IDE for querying and viewing MongoDb data 


### Usage
In order to use this library you will have a number of dependencies, which you can find in the Dist folder of this project. Essentially you have:

* wwMongoDb.prg - Main class your code interfaces with
* classes Folder - FoxPro support classes
* wconnect.h - required for support classes
* wwDotnetBridge.dll/wwIPstuff.dll - .NET interface libraries
* Newtonsoft.json.dll - .NET JSON library
* bin\Westwind.Data.MongoDb - MongoDb interface libary
* bin\MongoDb.Driver\.Bson - MongoDb .NET Driver

To use these files copy them into your application's root folder or anywhere where they are
accessible in the FoxPro path. All three folders (root/classes/bin) need to be added to 
the FoxPro path. If you like you can simply put them all into a single folder.

### Getting Started
To run any code in the installation folder make sure you launched FoxPro in installation
folder which uses config.fpw to set paths. 

Otherwise set your environment like this:

```
CD <installFolder>
DO _config
``` 

Make sure that MongoDb is running. The demos assume you're running MongoDb on the local
machine on the default port (27018). If you're running on a different server, or you use 
a different port make sure to adjust the connection string.

To start MongoDb locally, you can use:

```
c:\mongoDb> MongoD 
```

to start the server from the command line or follow the instructions on the MongoDb site
for setting up Mongo as a service. I like to also add the MongoDb folder to my PATH environment
variable so I access the server and the shell easily.

Now you're ready to run a few operations.

#### Save Data (and create Db/Table if it doesn't exist)
```
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

this.AssertTrue(loMongo.Save(loCustomer,"Customers"),loMongo.cErrorMsg)

this.AssertTrue(loCustomer._id == loMongo.oLastResult.Id,"Own id shouldn't be updated")

this.MessageOut("ID Generated: " + loMongo.oLastResult.Id)   
```
Note that you can either assign an Id explicitly as I did here (recommended), or you
can let MongoDb auto-create an id. Auto-created Ids are returned on a oLastResult object
as:

```
lcId = loMongo.oLastResult.Id
```

You can also check for errors on a Save operation:

```
IF !loMongo.Ok
	? loMongo.oLastResult.Message
    RETURN
ENDIF
```

Note that error messages from Mongo can be sketchy and often don't return any message info.
Your mileage may vary. It's usually best to check the result value for the function and if it's not returning the type you're expecting you have an error to deal with.

#### Query: Read a Collection of Items based on a filter
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

```
*** Search parameters and skip 30 and limit to 10 items
loCustomers = loMongo.Find('{ firstname: /^R.*/i, entered: { $gt: new Date(2014,12,1) }',;
                           "Customers",30,10)
```

#### Returning a single Entity
```
loMongo = this.CreateMongo()

loCustomer = loMongo.FindOne('{ firstname: "Rick" }',"Customers")

this.AssertNotNull(loCustomer,"Customers shouldn't be null")

*** NOTE: MongoDb dates come back as objects so use GetDate()
this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")
```

MongoDb can return nested objects/arrays. Arrays are returned as Collections in FoxPro. 

### License
This library is published under MIT license terms:

Copyright &copy; 2014 Rick Strahl, West Wind Technologies

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 