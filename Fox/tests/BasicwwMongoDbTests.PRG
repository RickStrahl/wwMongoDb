
DEFINE CLASS BasicwwMongoDbTests as FxuTestCase OF FxuTestCase.prg


*** SETUP AND CONFIGURATION *** 

************************************************************************
*  Setup
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Setup()

	*** Make sure libraries are loaded
	DO wwMongoDb

ENDFUNC
*   Setup

************************************************************************
*  TearDown
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION TearDown()

ENDFUNC
*   TearDown

************************************************************************
*  CreateMongo
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CreateMongo()

loMongo = CREATEOBJECT("wwMongoDb")
loMongo.Connect("mongodb://localhost/FoxMongoTest")

RETURN loMongo
ENDFUNC
*   CreateMongo

*** END SETUP AND CONFIGURATION ***



*** TESTS ***


************************************************************************
*   ConnectionTest
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ConnectionTest()

*** Explicitly create an instance and connect
loMongo = CREATEOBJECT("wwMongoDb")
this.AssertTrue(loMongo.Connect("mongodb://localhost/FoxMongoTest"),loMongo.cErrorMsg)

ENDFUNC
*  ConnectionTest

************************************************************************
*  BasicSaveEntityTest
****************************************
FUNCTION BasicSaveEntityTest()

*** Create instance (reused in all tests)
loMongo = this.CreateMongo()

*** Note objects are serialized as lower case
loCustomer = CREATEOBJECT("EMPTY")

*** Highly recommend you create your own ids - so that they 
*** are stored as strings or numbers rather than object IDs
ADDPROPERTY(loCustomer,"_id",loMongo.GenerateId())
ADDPROPERTY(loCustomer,"FirstName","Rick")
ADDPROPERTY(loCustomer,"LastName","Strahl")
ADDPROPERTY(loCustomer,"Company","West Wind Technologies")
ADDPROPERTY(loCustomer,"Entered",DATETIME())

loAddress = CREATEOBJECT("EMPTY")
ADDPROPERTY(loAddress,"Street","32 Kaiea")
ADDPROPERTY(loAddress,"City","Paia")

ADDPROPERTY(loCustomer,"Address",loAddress)

this.AssertTrue(loMongo.Save(loCustomer,"Customers"),loMongo.cErrorMsg)

this.MessageOut("ID Generated: " + loMongo.oLastResult.Id)

ENDFUNC
*  BasicSaveEntityTest


************************************************************************
*  BasicSaveEntityWithOwnIdTest
****************************************
FUNCTION BasicSaveEntityWithOwnIdTest()

loMongo = this.CreateMongo()

*** Note objects are serialized as lower case
loCustomer = CREATEOBJECT("EMPTY")

*** Recommend you assign your own ids for easier querying
ADDPROPERTY(loCustomer,"_id",SYS(2015))
ADDPROPERTY(loCustomer,"FirstName","Markus")
ADDPROPERTY(loCustomer,"LastName","Egger")
ADDPROPERTY(loCustomer,"Company","EPS Software")
ADDPROPERTY(loCustomer,"Entered", DATETIME())

loAddress = CREATEOBJECT("EMPTY")
ADDPROPERTY(loAddress,"Street","32 Kaiea")
ADDPROPERTY(loAddress,"City","Paia")

ADDPROPERTY(loCustomer,"Address",loAddress)

this.AssertTrue(loMongo.Save(loCustomer,"Customers"),loMongo.cErrorMsg)

this.AssertTrue(loCustomer._id == loMongo.oLastResult.Id,"Own id shouldn't be updated")

this.MessageOut("ID Generated: " + loMongo.oLastResult.Id)

ENDFUNC
*   BasicSaveEntityWithOwnIdTest

************************************************************************
*  FindTest
****************************************
***  Function: Finds a list of records that match the search
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FindTest()
LOCAL loMongo

loMongo = this.CreateMongo()
loCustomers = loMongo.Find('{ firstname: "Rick" }',"Customers")

this.AssertNotNull(loCustomers,"Customers shouldnt be null")



FOR lnX = 1 TO loCustomers.Count
   loCustomer = loCustomers[lnX]
   *** NOTE: MongoDb dates come back as objects so use GetDate()
   this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")
ENDFOR

ENDFUNC
*   FindTest

************************************************************************
*  Find2Test
****************************************
***  Function: Finds a list of records that match the search
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FindMoreComplexTest()
LOCAL loMongo

loMongo = this.CreateMongo()
*firstname: /^R.*/i,
loCustomers = loMongo.Find('{ firstname: /^R.*/i,  entered: { "$gte": new Date(2011,11,1) } }',"Customers")

this.AssertNotNull(loCustomers,"Customers shouldnt be null")

this.MessageOut("Count: " + TRANSFORM(loCustomers.Count))

FOR lnX = 1 TO loCustomers.Count
   loCustomer = loCustomers[lnX]
   *** NOTE: MongoDb dates come back as objects so use GetDate()
   this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")

ENDFOR

ENDFUNC
*   FindTest

*!*	************************************************************************
*!*	*  FindTest
*!*	****************************************
*!*	***  Function: Finds a list of records that match the search
*!*	***    Assume:
*!*	***      Pass:
*!*	***    Return:
*!*	************************************************************************
*!*	FUNCTION FindWithObjectTest()

*!*	loMongo = this.CreateMongo()


*!*	loQuery = CREATEOBJECT("EMPTY")
*!*	ADDPROPERTY(loQuery,"firstname","Rick (Fox)")

*!*	loDate= CREATEOBJECT("EMPTY")
*!*	ADDPROPERTY(loDate,"___gte",{1-1-2014})
*!*	ADDPROPERTY(loQuery,"entered",loDate)

*!*	loCustomers = loMongo.Find(loDate,"Customers")

*!*	this.AssertNotNull(loCustomers,"Customers shouldnt be null")

*!*	FOR lnX = 1 TO loCustomers.Count
*!*	   loCustomer = loCustomers[lnX]
*!*	   this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + " (" + TRANSFORM(loCustomer.Entered) + ")" + " (" + TRANSFORM(loCustomer._id) + ")" )
*!*	ENDFOR

*!*	ENDFUNC
*!*	*   FindTest

************************************************************************
*  FindOneTest
****************************************
***  Function: Finds the first record that matches the search
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FindOneTest()

loMongo = this.CreateMongo()

loCustomer = loMongo.FindOne('{ firstname: "Rick" }',"Customers")

this.AssertNotNull(loCustomer,"Customers shouldnt be null")

*** NOTE: MongoDb dates come back as objects so use GetDate()
this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")

ENDFUNC
*   FindOneTest

************************************************************************
*  FindOneTest
****************************************
***  Function: Finds the first record that matches the search
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadTest()

loMongo = this.CreateMongo()

*** Retrieve an id
loCustomer = loMongo.FindOne('{ firstname: "Rick" }',"Customers")
this.AssertNotNull(loCustomer,"Before id retrieval failed")
lcId = loCustomer._id
this.MessageOut("ID to search for: " + lcId)

loCustomer = loMongo.Load(lcId,"Customers")

this.AssertNotNull(loCustomer,"Customers shouldnt be null")

this.MessageOut( loCustomer.FirstName + " " + loCustomer.LastName + ;
                " (" + TRANSFORM(loMongo.GetDate(loCustomer.entered)) + ")" + ;
                " (ID: " + TRANSFORM(loCustomer._id) + ")")

ENDFUNC
*   FindTest


ENDDEFINE

