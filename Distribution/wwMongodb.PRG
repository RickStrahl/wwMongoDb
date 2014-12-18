DO wwutils
DO wwDotNetBridge
DO wwJsonSerializer

SET PROCEDURE TO wwMongoDb ADDITIVE

*************************************************************
DEFINE CLASS wwMongoDb AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2014
*:Contact: http://www.west-wind.com
*:Created: 12/17/2014
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class wwMongoDb

*:Description:

*:Example:

*:Remarks:
Requires .NET 4.0 installed on the machine

*:SeeAlso:


*:ENDHELP
#ENDIF

oMongo = null
oBridge = null
oSerializer = null
cConnectionString = ""
cLastRequest = ""
cLastResponse = ""

oLastResult = null
cErrorMsg = ""

************************************************************************
*  Init
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init()

this.oBridge = GetwwDotnetBridge("V4")

IF ISNULL(this.oBridge)
   ERROR "Unable to load wwDotnetBridge"
ENDIF   

IF (!this.oBridge.LoadAssembly("Westwind.Data.MongoDb.dll"))
   ERROR "Unable to load Westwind.Data.MongoDb: " + this.oBridge.cErrorMsg
ENDIF

*** Must preload latest NewtonSoft Json assembly
IF (!this.oBridge.LoadAssembly("NewtonSoft.Json.dll"))
   ERROR "Unable to load Westwind.Data.MongoDb: " + this.oBridge.cErrorMsg
ENDIF

   
ENDFUNC
*   Init

************************************************************************
*  Connect
****************************************
***  Function: Connection string to 
***      Pass: Connection String to MongoDb database
***    Assume: mongodb://servername/database
***            mongodb://localhost/foxsample
***    Return: .T. or .F.
************************************************************************
FUNCTION Connect(lcConnectionString)

LOCAL loBridge as wwDotNetBridge
loBridge = this.oBridge

this.cConnectionString = lcConnectionString

LOCAL loMongo as Westwind.Data.MongoDb.MongoDbDataAccess
loMongo = loBridge.CreateInstance("Westwind.Data.MongoDb.MongoDbDataAccess",;
                                  lcConnectionString)

IF ISNULL(loMongo)
   this.SetError(loBridge.cErrorMsg)
   RETURN .F.
ENDIF

THIS.oMongo = loMongo

RETURN .T.
ENDFUNC
*   Connect


************************************************************************
*  Find
****************************************
***  Function: Runs a MongoDb query and returns data as a collection.
***    Assume:
***      Pass: lvQuery - Mongo Query as an object or as a JSON string
***            lnLimit - Limit result size
***            lnSkip  - Items to skip before taking the limit
***    Return: Collection or null
************************************************************************
FUNCTION Find(lvQuery,lcCollection, lnSkip, lnLimit)
LOCAL lcJson

IF VARTYPE(lnLimit) # "N"
   lnLimit = -1
ENDIF
IF VARTYPE(lnSkip) # "N"
   lnSkip = -1
ENDIF      

IF !VARTYPE(lvQuery) = "O"
   lcJson = lvQuery
ELSE
   lcJson = this.Serialize(lvQuery)
   
   *** Translate 3 underlines into $ because $ is illegal Fox prop
   lcJson = STRTRAN(lcJson,["___],["$])   
ENDIF      

this.cLastResponse = ""
this.cLastRequest = lcJson

this.oBridge.cErrorMsg = ""
lcJson = this.oBridge.InvokeMethod(this.oMongo,"FindFromStringJson",lcJson,lcCollection,lnSkip,lnLimit)

IF !VARTYPE(lcJson) = "C" OR !EMPTY(this.oBridge.cErrorMsg)
   ERROR "Query failed: " + this.oBridge.cErrorMsg
ENDIF   

this.cLastResponse = lcJson

loResult = this.Deserialize(lcJson)

RETURN loResult
ENDFUNC
*   Find

************************************************************************
*  FindOne
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FindOne(lvQuery,lcCollection)

IF !VARTYPE(lvQuery) = "O"
   lcJson = lvQuery
ELSE
   lcJson = this.Serialize(lvQuery)

   *** Translate ___ into $ because $ is illegal Fox prop
   lcJson = STRTRAN(lcJson,["___],[$])   
ENDIF      

this.cLastResponse = ""
this.cLastRequest = lcJson

this.oBridge.cErrorMsg = ""
lcJson = this.oBridge.InvokeMethod(this.oMongo,"FindOneFromStringJson",lcJson,lcCollection)

RETURN this.ProcessJsonResult(lcJson)
ENDFUNC
*   FindOne

************************************************************************
*  Load
****************************************
***  Function: Loads an item by ID
***    Assume:
***      Pass: lvId -  string or integer ID 
***    Return: object or null
************************************************************************
FUNCTION Load(lvId, lcCollection)
lcJson = this.oBridge.InvokeMethod(this.oMongo,"LoadJson",lvId,lcCollection)
RETURN this.ProcessJsonResult(lcJson)
ENDFUNC


************************************************************************
*  Save
****************************************
***  Function: Saves an object or json string to the specified 
***            collection.
***    Assume: 
***      Pass: lvEntity -  Object or Json string
***    Return: .T. or .F.
************************************************************************
FUNCTION Save(lvEntity,lcCollection, llIsJson)
LOCAL lcResult, lcType, loSer, lcJson

IF IsNullOrEmpty(lvEntity)
   this.SetError("Can't save null or empty entity")
   RETURN .F.
ENDIF

IF !llIsJson
	lcJson = this.Serialize(lvEntity)
ELSE
    lcJson = lvEntity
ENDIF   

this.oBridge.cErrorMsg = ""
this.oLastResult = null
this.cLastRequest = lcJson 
this.cLastResponse = lcJson

this.oLastResult = this.oBridge.InvokeMethod(this.oMongo,"SaveFromJson",lcJson,"Customers")

IF ISNULL(this.oLastResult)
   this.oLastResult = this.CreateEmptyResult()
   this.oLastResult.Ok = .F.
   this.lLastResult.Message = this.oBridge.cErrorMsg  
   THIS.SetError("Save operation failed: " + this.oBridge.cErrorMsg)
   RETURN .F.
ENDIF   

IF !this.oLastResult.Ok 
   THIS.SetError("Save operation failed: " + this.oLastResult.Message)
   RETURN .F.
ENDIF

RETURN .T.
ENDFUNC
*   Save

************************************************************************
*  Serialize
****************************************
***  Function: Method used to serialize JSON.
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Serialize(lvEntity)

IF ISNULL(this.oSerializer)
	this.oSerializer = CREATEOBJECT("wwJsonSerializer") 
	this.oSerializer.OutputDateType = 1 &&  render ISODATE()
	this.oSerializer.IgnoreDollarVars = .F.
ENDIF   

RETURN this.oSerializer.Serialize(lvEntity)
ENDFUNC
*   Serialize

************************************************************************
*  Deserialize
****************************************
***  Function: Deserializes JSON result
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Deserialize(lcJson)

IF ISNULL(this.oSerializer)
	this.oSerializer = CREATEOBJECT("wwJsonSerializer") 
	this.oSerializer.OutputDateType = 1  &&  render ISODATE()
	this.oSerializer.IgnoreDollarVars = .F.
ENDIF   

RETURN this.oSerializer.DeserializeJson(lcJson)
ENDFUNC
*   Deserialize


************************************************************************
*  GenerateId
****************************************
***  Function: Generates a new BSON ID that uses MongoDb's internal
***            generator. 
***    Assume: Not necessary that you use this ID generator - any string
***            that is unique within your system will work, but this
***            is optimized for MongoDb and it's clustering mechanism
***      Pass: 
***    Return: Id as a string
************************************************************************
FUNCTION GenerateId()
LOCAL lcId

lcId = this.oBridge.InvokeMethod(this.oMongo,"GenerateNewId")
IF (ISNULL(lcId))
   ERROR "Failed to generate new ID: " + this.oBridge.cErrorMsg
ENDIF

RETURN lcID
ENDFUNC
*   GenerateId

************************************************************************
*  GetDate
****************************************
***  Function: Converts a MongoDb returned date object to a Fox
***            date variable
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetDate(loDate)
lnMSecs = loDate.Date
RETURN {^1970/01/01 0:0} - (GetTimeZone() * 60) +  (lnMSecs/1000) 
ENDFUNC
*   GetDate

************************************************************************
*  ProcessJsonResult
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
HIDDEN FUNCTION ProcessJsonResult(lcJson)

IF !EMPTY(this.oBridge.cErrorMsg)
   ERROR "Query failed: " + this.oBridge.cErrorMsg
ENDIF   

this.cLastResponse = lcJson

loResult = this.Deserialize(lcJson)

RETURN loResult
ENDFUNC
*   ProcessJsonResponse

************************************************************************
*  CreateLastResult
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
HIDDEN FUNCTION CreateEmptyLastResult
RETURN this.oSerialize([{ Ok: true, Message: "", Id: "" }])
ENDFUNC
*   CreateLastResult

************************************************************************
*  SetError
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION SetError(lcMessage)

IF IsNullOrEmpty(lcMessage)
   this.cErrorMsg = ""
ELSE
   this.cErrorMsg = lcMessage
ENDIF

ENDFUNC
*   SetError


ENDDEFINE
*EOC wwMongoDb 