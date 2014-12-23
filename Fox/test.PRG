CLEAR

*** Load library and dependencies
DO wwMongoDb

loMongo = CREATEOBJECT("wwMongoDb")


*** connects to localhost and FoxMongoTest Db
*** if the Db doesn't exist it auto-creates
loMongo.Connect("mongodb://localhost/FoxMongoTest")


*** Add an Entity to the database

loCollection = loMongo.GetCollection("Customers")
? loCollection
? loMongo.oBridge.InvokeMethod(loCollection,"Count")

RETURN



*** Create an object to persist
*** Note objects are serialized as lower case
loCustomer = CREATEOBJECT("EMPTY")

*** Recommend you assign your own ids for easier querying
ADDPROPERTY(loCustomer,"_id",loMongo.GenerateId())
ADDPROPERTY(loCustomer,"FirstName","Rick")
ADDPROPERTY(loCustomer,"LastName","Strahl")
ADDPROPERTY(loCustomer,"Company","West Wind")
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
ADDPROPERTY(loOrder,"OrderTotal",12.56)
loOrders.Add(loOrder)

loOrder = CREATEOBJECT("Empty")
ADDPROPERTY(loOrder,"Date",DATETIME())
ADDPROPERTY(loOrder,"OrderId",SUBSTR(SYS(2015),2))
ADDPROPERTY(loOrder,"OrderTotal",120.99)
loOrders.Add(loOrder)

IF !loMongo.Save(loCustomer,"Customers")
   ? loMongo.cErrorMsg
   RETURN
ENDIF

*** Capture and display the Id of the added record
*** (if you don't create your own ID, Mongo creates one
***  and this will give you the generated ID after an insert)
lcId = loMongo.oLastResult.Id
?"Customer added. ID Generated: " + loMongo.oLastResult.Id


*** List Customers that match a filter ***

*** Filter using MongoDb JSON filter expressions
?
? "List Customers that start with 'Rick'"
? "-----------------"

loCustomers = loMongo.Find('{ firstname: "Rick" }',"Customers")

FOR lnX = 1 TO loCustomers.Count
   loCustomer = loCustomers[lnX]
   *** NOTE: MongoDb dates come back as objects so use GetDate()
   ? loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")"
ENDFOR


*** Find a single customer using MongoDb JSON filter expressions
?
? "Find first Customer that starts with 'Rick'"
? "-----------------"

loCustomer = loMongo.FindOne('{ firstname: "Rick" }',"Customers")

*** NOTE: MongoDb dates come back as objects so use GetDate()
? loCustomer.FirstName + " " + loCustomer.LastName + ;
        " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
        " (ID: " + TRANSFORM(loCustomer._id) + ")"


*** Find a single customer using MongoDb JSON filter expressions
?
? "Find Customer by ID"
? "-----------------"

*** Load a single record by ID from Customers collection
loCustomer = loMongo.Load(lcId,"Customers")

*** NOTE: MongoDb dates come back as objects so use GetDate()
? loCustomer.FirstName + " " + loCustomer.LastName + ;
        " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
        " (ID: " + TRANSFORM(loCustomer._id) + ")"
        
IF !ISNULL(loCustomer.Orders)        
    FOR lnx=1 TO loCustomer.Orders.Count   
		loOrder = loCustomer.Orders[lnX]
	    ? "    " + TRANSFORM(loMongo.GetDate(loOrder.Date))  + "  " + loOrder.OrderId + " " + TRANSFORM(loOrder.OrderTotal)

	ENDFOR        
ENDIF
