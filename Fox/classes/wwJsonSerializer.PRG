#INCLUDE wconnect.h

SET PROCEDURE TO wwUtils Additive
SET PROCEDURE TO wwAPI Additive
SET PROCEDURE TO wwRegEx ADDITIVE
SET PROCEDURE TO wwCollections ADDITIVE

*** If you use DeserializeJson you'll also need this in your code
SET PROCEDURE TO wwDotnetBridge ADDITIVE

SET PROCEDURE TO wwJsonSerializer Additive

*** NOTE: wwIPStuff.dll dependency for JSON encoding
*** For JsonEncode() API function to encode strings efficiently
*** since VFP's char by char parsing is too slow

*************************************************************
DEFINE CLASS wwJsonSerializer AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2006
*:Contact: http://www.west-wind.com
*:Created: 09/19/2006
*************************************************************

PROTECTED cOutput
cOutput = ""

TrimStringValues = .T.

*** Exclude Custom Property Exclusions
PropertyExclusionList = ;
 ",activecontrol,classlibrary,baseclass,comment,docked,dockposition,controls,objects,controlcount,"+;
 "class,parent,parentalias,parentclass,helpcontextid,whatsthishelpid," +;
 "width,height,top,left,tag,picture,onetomany,childalias,childorder,relationalexpr,timestamp_column," 

*** Overrides property naming by using the
*** names specified here with proper case 
*** instead of the properties 
PropertyNameOverrides = ""

*** If .t. doesn't convert dates to UTC first
*** Assumes that any date is already UTC formatted
AssumeUtcDates = .F.

*** 0 - ISO Date String, 1 - new Date('ISO') 2 - ISODate('ISO')
OutputDateType = 0

*** Ignore variables that start with $
IgnoreDollarVars = .T.

*** wwDotnetBridge Instance
oBridge = null

PROTECTED oPropertyNames
oPropertyNames = null

FUNCTION Init
DECLARE INTEGER JsonEncodeString IN wwipstuff.dll string  json,string@  output
ENDFUNC

************************************************************************
* wwJSONSerializer ::  Serialize
****************************************
***  Function: Serializes a VFP value, object or array/collection to
***            a JSON string.
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Serialize(lvValue)
LOCAL lcOldPoint, lcJson

lcOldPoint = SET("POINT")
SET POINT TO "."

this.cOutput = ""
this.WriteValue(@lvValue)

SET POINT TO lcOldPoint

RETURN THIS.cOutput
ENDFUNC
*  wwJSONSerializer ::  Serialize

************************************************************************
* wwJSONSerializer ::  WriteValue
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteValue(lvValue)
LOCAL lcType, lnX
LOCAL ARRAY la_array[1]
LOCAL ARRAY lvValArray[1]

lcType = TYPE([lvValue])
		
DO CASE
	CASE TYPE([ALEN(lvValue)]) = "N"
		this.WriteArray(@lvValue)		
	CASE ISNULL(lvValue)		
		this.cOutput = this.cOutput + "null"
	CASE INLIST(lcType,"C","M","V")
		DO CASE
		 CASE lvValue = "cursor:" OR lvValue ="cursor_rawarray:"
			this.WriteCursor(@lvValue)
		OTHERWISE
			this.WriteString(@lvValue)
		ENDCASE
	CASE lcType == "Y"
		this.cOutput = this.cOutput + ALLTRIM(TRANSFORM(lvValue,"@N"))
	CASE INLIST(lcType,"I","N","F")
		this.cOutput = this.cOutput + TRANSFORM(lvValue)
	CASE lcType = "L"
		IF lvValue 
			this.cOutput = this.cOutput + "true"
		ELSE
			this.cOutput = this.cOutput + "false"
		ENDIF
	CASE INLIST(lcType,"D","T")
		this.WriteDate(@lvValue)
	*** Base 64 encode binary values
	CASE lcType = "W" OR lcType = "Q"
		this.cOutput = this.cOutput + STRCONV(lvValue,13)
	CASE lcType = "O"
		LOCAL lcValueType
		lcValueType = TYPE("lvValue.Class")
		
		*** Special Object - wwCollection: Serialize as array
		DO CASE
		CASE lcValueType = "C" AND LOWER(lvValue.Class)= "collection"
		    IF lvValue.Count = 0
		        this.cOutput = this.cOutput + "[]"
			ELSE
				llHasKeys = !EMPTY(EVALUATE("lvValue.GetKey(1)"))
				IF llHasKeys
					THIS.WriteKeyCollection(@lvValue)
				ELSE			
					*** Turn collection into Array and parse as Array
					this.WriteCollection(@lvValue)
				ENDIF
			ENDIF
		CASE lcValueType = "C" AND LOWER(lvValue.Class)= "wwcollection"
			DIMENSION la_array[1]
			ACOPY(lvValue.aItems,la_array)
			this.WriteArray(@la_array)
		OTHERWISE
			this.WriteObject(@lvValue)
		ENDCASE
	OTHERWISE 
	    this.cOutput = this.cOutput + "null"
ENDCASE
ENDFUNC
*  wwJSONSerializer ::  WriteValue


************************************************************************
* wwJSONSerializer ::  WriteString
****************************************
***  Function: serializes string
***    Assume: Thanks to Lauren Clarke for his help in 
***            optimization.
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteString(lcValue)
LOCAL lnK, lcResult, lcValue,lcOutput

IF THIS.TrimStringValues
   lcValue = TRIM(m.lcValue)
ENDIF

IF EMPTY(lcValue)
	this.cOutput = this.cOutput + [""]
	RETURN 
ENDIF	

*** Optimized for perf with C code in wwIPStuff.dll
*** JsonEncodeString
LOCAL lcOutput 
lcOutput = REPLICATE(CHR(0),LEN(lcValue) * 6 + 3)
lnPointer = JsonEncodeString(lcValue,@lcOutput)
this.cOutput = this.cOutput +  WinApi_NullString(@lcOutput)

ENDFUNC
* WriteString

************************************************************************
* wwJsonSerializer ::  WriteDate
****************************************
***  Function: Turns a date into an ISO formatted date value string
***    Assume: Input dates are assumed to be local dates
***            If you have UTC dates to start you'll need to convert
***            them to local dates first
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteDate(lvValue)
LOCAL lcDate

IF VARTYPE(lvValue) = "D"
	lvValue = DTOT(lvValue)
ENDIF	

*** turn into UTC date
IF !THIS.AssumeUtcDates
	lvValue = lvValue + (GetTimeZone() * 60)
ENDIF

IF EMPTY(lvValue)
	lvValue = {^1970-1-1 :}
ENDIF

#IF wwVFPVersion > 8
	lcDate = '"' + TTOC(lvValue,3) + 'Z"'
#ELSE
	lcDate = '"' + TRANSFORM(YEAR(ldDateVal)) + "-" + ;
	       PADL(TRANSFORM(MONTH(ldDateVal)),2,"0") + "-" +;
	       PADL(TRANSFORM(Day(ldDateVal)),2,"0") + "T" +;
	       PADL(TRANSFORM(Hour(ldDateVal)),2,"0") + ":" +;
	       PADL(TRANSFORM(Minute(ldDateVal)),2,"0") + ":" +;
	       PADL(TRANSFORM(Sec(ldDateVal)),2,"0") + 'Z"'
#ENDIF

IF THIS.OutputDateType = 1
   lcDate = 'new Date(' + lcDate + ')'
ENDIF
IF this.OutputDateType = 2
   lcDate = 'ISODate(' + lcDate + ')'
ENDIF
   
*** ISO Format
this.cOutput = this.cOutput +  " " + lcDate

ENDFUNC
*  wwJsonSerializer ::  WriteDate


************************************************************************
* wwJsonSerializer ::  SerializeArray
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteArray(laItems)
LOCAL lnRows, lnX, lvItem
EXTERNAL ARRAY laItems

lnRows = ALEN(laItems,1)
this.cOutput = this.cOutput + "["

FOR lnX = 1 TO lnRows
	lvItem = laItems[lnX]
		
	this.WriteValue( @lvItem ) 
	
	this.cOutput = this.cOutput + ","	
ENDFOR

this.cOutput = TrimWhiteSpace(this.cOutput,",")

this.cOutput = this.cOutput + "]"
ENDFUNC
*  wwJsonSerializer ::  SerializeArray

************************************************************************
* wwJsonSerializer ::  WriteCollection
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteCollection(loCol)
LOCAL lnRows, lnX, lvItem

lnRows = loCol.Count
this.cOutput = this.cOutput + "["

FOR lnX = 1 TO lnRows
	lvItem = loCol.Item(lnx)
	this.WriteValue( @lvItem ) 	
	this.cOutput = this.cOutput + ","	
ENDFOR

this.cOutput = TrimWhiteSpace(this.cOutput,",")

this.cOutput = this.cOutput + "]"
ENDFUNC
*  wwJsonSerializer ::  SerializeArray



************************************************************************
*  WriteKeyCollection
****************************************
***  Function: Writes a key/value collection as a JSON object
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteKeyCollection(loCollection)
LOCAL loResult, lnRows
lnRows = loCollection.Count

THIS.cOutput = THIS.cOutput +  "{"
FOR lnX = 1 TO lnRows 
	this.cOutput = this.cOutput + ["] + loCollection.GetKey(lnX) + [":]
	this.WriteValue(loCollection.Item[lnx])
	IF lnX < loCollection.Count
		this.cOutput = this.cOutput + ","
	ENDIF
ENDFOR

this.cOutput = this.cOutput + "}"
ENDFUNC
*   WriteKeyCollection

************************************************************************
* wwJSONSerializer ::  WriteObject
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteObject()
LPARAMETERS loObject
LOCAL lnX, lnProperties, lcFieldName, lcFieldType, lvValue, llExclusions
LOCAL ARRAY laMembers[1], la_array[1]

lnProperties = AMEMBERS(laMembers,loObject)

this.cOutput = this.cOutput + [{]

IF !EMPTY(this.PropertyNameOverrides) AND ISNULL(this.oPropertyNames)
   this.oPropertyNames = CREATEOBJECT("wwCollection")
   this.oPropertyNames.Count = ALINES(this.oPropertyNames.aItems,this.PropertyNameOverrides,1 + 4,",")
ENDIF

llPropNames = !ISNULL(this.oPropertyNames)

FOR lnX = 1 TO lnProperties
	  lcFieldName=LOWER(laMembers[lnX])
      
	   *** Handle property exclusions
	   IF AT("," + lcFieldName + ",","," + THIS.PropertyExclusionList + ",")>0
	      LOOP
	   ENDIF
      
	  IF llPropNames
	  	 lnIndex = this.oPropertyNames.GetIndex(lcFieldName)
	  	 IF lnIndex > 0
	  	    lcFieldName = this.oPropertyNames.aItems[lnIndex]
	  	 ENDIF
	  ENDIF	  
 
      this.cOutput = this.cOutput + ["] + lcFieldName + [":]
      
	  IF TYPE([ALEN(loObject.] + lcFieldName + [)]) = "N"
	     *** Special Array handling - have to copy it to var first so we can pass by ref
         DIMENSION la_array[1]
         ACOPY(loObject.&lcFieldName,la_array)
	  	this.WriteArray( @la_Array )
	  ELSE  
	    this.WriteValue( EVAL("loObject."+lcFieldName) )
	  ENDIF
	  
	  this.cOutput = this.cOutput + ","
ENDFOR

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",")
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",")
#ENDIF

this.cOutput = this.cOutput + [}]
ENDFUNC
*  wwJSONSerializer ::  WriteObject

************************************************************************
* wwJSONSerializer ::  WriteCursor
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteCursor(lcCursor)
LOCAL lnFieldCount, lnX, lcOldCursor, lcField, llNoRows, llExclusions,lnCount

llNoRows = .F.
IF AT("cursor_rawarray:",lcCursor) > 0
   llNoRows = .T.
   lcCursor = STRTRAN(lcCursor,"cursor_rawarray:","")
ELSE
   lcCursor = STRTRAN(lcCursor,"cursor:","")
ENDIF

lcOldCursor = ALIAS()

IF EMPTY(lcCursor)
	lcCursor = ALIAS()
ENDIF
IF EMPTY(lcCursor)
   this.cOutput = this.cOutput + "null"	
   RETURN
ENDIF

IF USED(lcCursor)
   SELECT (lcCursor)
ELSE
   RETURN   
ENDIF   

lnFieldCount = AFIELDS(laFields,lcCursor)


IF !EMPTY(this.PropertyNameOverrides) AND ISNULL(this.oPropertyNames)
   this.oPropertyNames = CREATEOBJECT("wwCollection")
   this.oPropertyNames.Count = ALINES(this.oPropertyNames.aItems,this.PropertyNameOverrides,1 + 4,",")
ENDIF

llExclusions = !ISNULL(this.oPropertyNames)


*** Note: Inconsistency Exception here - 
***       use upper case so it works with the script library
***       for automatic databinding.
IF !llNoRows
	this.cOutput = this.cOutput +  '{"Rows":'
ENDIF

this.cOutput = this.cOutput + "["

lnCount = 0
SCAN
	this.cOutput = this.cOutput + [{]	
	
	FOR lnX = 1 TO lnFieldCount
		lcField = LOWER(laFields[lnX,1])
		
		  IF llExclusions
		  	 lnIndex = this.oPropertyNames.GetIndex(lcField)
		  	 IF lnIndex > 0
		  	    lcField = this.oPropertyNames.aItems[lnIndex]
		  	 ENDIF
		  ENDIF	  		
		
		this.cOutput = this.cOutput + ["] +  lcField+ [":]
		this.WriteValue( EVALUATE( lcField ) )
		
		IF lnX < lnFieldCount
			this.cOutput = this.cOutput + ","
		ENDIF
	ENDFOR

	this.cOutput = this.cOutput + [},]
	lnCount = lnCount + 1 
ENDSCAN

IF USED(lcOldCursor)
	SELECT (lcOldCursor)
ENDIF	

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",") +  "]"
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",") +  "]"
#ENDIF

IF !llNoRows
  this.cOutput = this.cOutput + ',"Count": '  +  TRANSFORM(lnCount) + "}"
ENDIF

ENDFUNC
*  wwJSONSerializer ::  WriteCursor

************************************************************************
* wwJSONSerializer ::  WriteRow
****************************************
***  Function:
***    Assume: Record is loaded and ready to go
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteRow(lvValue)
LOCAL lnFieldCount, lnX, lcOldCursor, lcField

lcCursor = STRTRAN(lcCursor,"cursorrow:","")

lcOldCursor = ALIAS()

IF EMPTY(lcCursor)
	lcCursor = ALIAS()
ENDIF
IF EMPTY(lcCursor)
   this.cOutput = this.cOutput + "null"	
   RETURN
ENDIF

IF USED(lcCursor)
   SELECT (lcCursor)
ELSE
   RETURN   
ENDIF   

lnFieldCount = AFIELDS(laFields,lcCursor)
this.cOutput = this.cOutput +  '{'

FOR lnX = 1 TO lnFieldCount
	lcField = laFields[lnX,1]	
	this.cOutput = this.cOutput + ["] +  lcField+ [":]
	this.WriteValue( EVALUATE( lcField ) )
	this.cOutput = this.cOutput + ","
ENDFOR

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",") +  "}"
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",") +  "}"
#ENDIF

IF USED(lcOldCursor)
	SELECT (lcOldCursor)
ENDIF	

ENDFUNC
*  wwJSONSerializer ::  WriteRow

************************************************************************
* wwJsonSerializer ::  Deserialize
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Deserialize(lcValue)

*** ISO, or MS AJAX dates, \/Date(9999999)\/ or new Date(9999999)
IF (LEN(lcValue) = 22 AND RIGHT(lcValue,2) = 'Z"' AND SUBSTR(lcValue,6,1)="-") OR ;
   lcValue = ["\/Date] OR lcValue = ["\\/Date] OR lcValue = "new Date("
   RETURN this.ParseDate(lcValue)
ENDIF   

lcValue = ALLTRIM(lcValue)

*** Check for string values
IF lcValue = ["]
   RETURN this.ParseString(lcValue)
ENDIF

*** Check for objects - note only limited support
IF lcValue = [{]
   RETURN this.ParseObject(lcValue)
ENDIF

*** Check for Arrays - not supported at this time: returns null
IF lcValue = "["
  RETURN this.ParseArray(lcValue)
ENDIF     

*** Check for boolean values
IF INLIST(lcValue,"true","false")
  RETURN this.ParseLogical(lcValue)
ENDIF

IF lcValue = "null"
   RETURN null
ENDIF   

*** Anything else is a literal numeric
RETURN VAL(lcValue)
ENDFUNC
*  wwJsonSerializer ::  ParseValue

************************************************************************
* wwJsonSerializer ::  ParseString
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseString(lcJsonString)

IF VARTYPE(poJScript) # "O"
	PUBLIC poJScript
	loJScript = CREATEOBJECT("ScriptControl")
	loJScript.Language = "JavaScript"
ENDIF

lcValue = ""
TRY
	lcValue=loJScript.Eval(lcJsonString)
CATCH	
ENDTRY

RETURN lcValue
* wwJsonSerializer :: ParseString

************************************************************************
* wwJsonSerializer ::  ParseNumber
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseNumber(lcNumber)
RETURN VAL(lcNumber)
ENDFUNC
*  wwJsonSerializer ::  ParseNumber

************************************************************************
* wwJsonSerializer ::  ParseLogical
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseLogical(lcLogical)
IF (lcLogical = "true")
	RETURN .t.
ENDIF
RETURN .F.
ENDFUNC
*  wwJsonSerializer ::  ParseLogical

************************************************************************
* wwJsonSerializer ::  ParseDate
****************************************
***  Function: Converts a JSON Date String to a VFP Time Value
***    Assume: 
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseDate(lcDate, llReturnUtcTime)
LOCAL lnCount, lcDate, ldDate
LOCAL ARRAY laNums[1]

IF EMPTY(lcDate)
   RETURN  {/ /  : }
ENDIF

IF LEN(lcDate) != 22
   RETURN {/ / : }
ENDIF   

*** ISO format: 2009-01-03T18:10:00Z
IF RIGHT(lcDate,2) = 'Z"' AND SUBSTR(lcDate,6,1) = "-"
	lcDate = STRTRAN(lcDate,'"',"")
	lcDate = STRTRAN(lcDate,"T"," ")
	lcDate = SUBSTR(lcDate,1,LEN(lcDate)-1)
	lcDate = "{^" + lcDate + "}"
	ldDate = EVALUATE(lcDate)
	
	IF llReturnUtcTime
	   RETURN ldDate
	ENDIF   	
	
	*** Subtract TimeZone Offset in Minutes
	ldDate = ldDate - (GetTimeZone() * 60)	
	RETURN ldDate
ENDIF

*** MS AJAX Date Format: "\/Date(1012341)\/"
IF lcDate = ["\/] OR lcDate = ["\\/]
   lnMSecs = VAL(STREXTRACT(lcDate,"Date(",")"))
   RETURN {^1970/01/01 0:0} - (GetTimeZone() * 60) +  (lnMSecs/1000) 
ENDIF

** Input: new Date(2007,0,2,9,58,17,254)
lcDateNums = STREXTRACT(lcDate,"new Date(",")")

lnCount = ALINES(laNums,lcDateNums,1,",")

** String Output:  "{^2007-01-01 22:15:10}"
lcDate = "{^" + laNums[1] + "-" + TRANSFORM(VAL(laNums[2]) + 1) + "-" + laNums[3] +;
		 " " + laNums[4] + ":" + laNums[5] + ":" + laNums[6] + "}"

ldDate = EVALUATE(lcDate)

IF llReturnUtcTime
   RETURN ldDate
ENDIF   

*** Subtract TimeZone Offset in Minutes
ldDate = ldDate - (GetTimeZone() * 60)

RETURN ldDate
ENDFUNC
*  wwJsonSerializer ::  ParseDate

************************************************************************
* wwJsonSerializer ::  ParseObject
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseObject(lcObjectString,loObject)
LOCAL lnCurPos,llDone,lnAt,lnAt2, lcProperty, lcObject, lcValue

IF LEN(lcObjectString) < 3
	RETURN null
ENDIF
	
lcObject = SUBSTR(lcObjectString,3,LEN(lcObjectString)-3)

IF VARTYPE(loObject) # "O"
	loObject = CREATEOBJECT("EMPTY")
ENDIF	

lnCurPos = 0
llDone = .f.
DO WHILE .T.
	IF StartsWith(lcObject,",")
	   lcObject = ALLTRIM(SUBSTR(lcObject,2)) && Skip over comma
   	   lcObject = ALLTRIM(SUBSTR(lcObject,2)) && leading "
	ENDIF
	
	lnAt = AT([":],lcObject)
	IF lnAt = 0
		EXIT
	ENDIF

	lcProperty = SUBSTR(lcObject,1,lnAt-1)
	lcObject = ALLTRIM(SUBSTR(lcObject,lnAT+2))
	
	DO CASE 
		CASE lcObject = "{"
			*** NESTED OBJECT				
			lcValue = this.FindMatchingBrace(lcObject,"{","}")
			IF EMPTY(lcObject)
				lcValue = null
			ENDIF
		CASE lcObject = "["
			*** Nested Array			
			lcValue = this.FindMatchingBrace(lcObject,"[","]")
			IF EMPTY(lcObject)
			    lcValue = null
			ENDIF
		CASE lcObject = ["]
			*** String
			LOCAL loRegEx,loMatches
			loRegEx = GetwwRegExObject()
			loMatches = loRegEx.Match(lcObject,'".*?((^")|[^\\]")')
			IF !ISNULL(loMatches) AND loMatches.Count > 0
			   lcValue = loMatches.Item(0).Value
			ENDIF
			
		    *lvValue = this.ParseString(lcValue)	
		OTHERWISE
		    lnAt2 = AT([,"],lcObject)
			IF lnAt2 = 0
			   lcValue = lcObject
			ELSE
			   lcValue = SUBSTR(lcObject,1,lnAt2-1)
			ENDIF
	ENDCASE
	
	lcObject = ALLTRIM(STRTRAN(lcObject,lcValue,"",1,1))
		
	ADDPROPERTY(loObject,lcProperty, this.Deserialize(lcValue) )

	IF EMPTY(lcObject)
	   EXIT
	ENDIF
*!*		IF lnAt2 = 0
*!*			EXIT
*!*		ENDIF
	
	*lcObject = SUBSTR(lcObject,lnAt2+2)
ENDDO

RETURN loObject
ENDFUNC
*  wwJsonSerializer ::  ParseObject

************************************************************************
* wwJsonSerializer ::  ParseArray
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseArray(lcObjectString)
LOCAL lcData, lcFirst, lcValue, loCol, lnAt

lcData = ALLTRIM(lcObjectString)

IF lcObjectString == "null"
  RETURN null
ENDIF
  
IF LEN(lcData) < 3
   *** Empty array
   RETURN CREATEOBJECT("Collection")
ENDIF   

*** Strip off []
lcData = ALLTRIM(SUBSTR(lcData,2,LEN(lcObjectString)-2))

loCol = CREATEOBJECT("Collection")

DO WHILE .T.
	IF LEN(lcData) = 0
	   EXIT
	ENDIF
	
	*** Strip off leading ,
	IF SUBSTR(lcData,1,1) = ","
	   lcData = ALLTRIM(SUBSTR(lcData,2))
	ENDIF	

	lcFirst = SUBSTR(lcData,1,1)
	lvValue = null

	DO CASE
		*** Object
		CASE lcFirst = "{"
		   lcValue = this.FindMatchingBrace(lcData,"{","}")		   
		   lvValue = this.ParseObject(lcValue)
		CASE lcFirst = "["
		   lcValue = this.FindMatchingBrace(lcData,"[","]")
		   lvValue = this.ParseArray(lcValue)
		*** String
		CASE lcFirst = ["]
			LOCAL loRegEx,loMatches
			loRegEx = GetwwRegExObject()
			loMatches = loRegEx.Match(lcData,'".*?((^")|[^\\]")')
			IF !ISNULL(loMatches) AND loMatches.Count > 0
			   lcValue = loMatches.Item(0).Value
			ENDIF
			
		   lvValue = this.ParseString(lcValue)		   
		*** Literal
		OTHERWISE
		   lnAt = AT(",",lcData)
		   IF lnAt = 0
			  lnAt = AT("]",lcData)
		   ENDIF
		   IF lnAt = 0
		      EXIT
		   ENDIF
		      
		   lcValue = SUBSTR(lcData,1,lnAt-1)
		   lvValue = this.Deserialize(lcValue)		
	ENDCASE
	
	*** Trim out the parsed value
	lcData = ALLTRIM(STRTRAN(lcData,lcValue,"",1,1))
	
	loCol.Add(lvValue)
ENDDO

RETURN loCol
ENDFUNC
*  wwJsonSerializer ::  ParseArray


************************************************************************
* wwJsonSerializer ::  FindMatchingBrace
****************************************
***  Function: returns a matching brace for a string
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION FindMatchingBrace(lcCode,lcOpenBrace,lcCloseBrace,lcFollows)
LOCAL lnAt, lcSubCode

lnAT = AT(lcCloseBrace,lcCode)
IF lnAt = 0
	RETURN ""
ENDIF	
lcSubCode = SUBSTR(lcCode,1,lnAt)

lnOccurs = OCCURS(lcOpenBrace,lcSubCode)
IF lnOccurs = 0
	RETURN ""
ENDIF
IF lnOccurs = 1
	RETURN SUBSTR(lcCode,1,lnAT) 
ENDIF

lnAt = AT(lcCloseBrace,lcCode,lnOccurs)
IF lnAT = 0
	RETURN ""
ENDIF	

RETURN SUBSTR(lcCode,1,lnAT) 

************************************************************************
*  DeserializeJson
****************************************
***  Function: Deserializes a JSON object, value or array into a Fox object
***    Assume: Requires wwDotnetBridge 
***      Pass:
***    Return:
************************************************************************
FUNCTION DeserializeJson(lcJson)
LOCAL loSer, loRes

IF (VARTYPE(lcJson) != "C")
   RETURN NULL
ENDIF   

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")
loRes = loSer.DeserializeJsonNet(lcJson)

IF ISNULL(loRes)
   RETURN null
ENDIF   

DO CASE
   CASE loRes.Type = "O"
	   RETURN THIS.ParseObjectJson(loRes)
   CASE loRes.Type = "A"
       RETURN THIS.ParseArrayJson(loRes)
   OTHERWISE
       RETURN this.ParseValueJson(loRes)
ENDCASE          

ENDFUNC
*   DeserializeJson


************************************************************************
*  DeserializeXml
****************************************
***  Function: Deserializes an XML object, value or array into a Fox object
***    Assume: Requires wwDotnetBridge 
***      Pass:
***    Return:
************************************************************************
FUNCTION DeserializeXml(lcXml)
LOCAL loSer, loRes

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")

loRes = loSer.DeserializeXml(lcXml)

IF ISNULL(loRes)
   RETURN null
ENDIF   

DO CASE
   CASE loRes.Type = "O"
	   RETURN THIS.ParseObjectJson(loRes)
   CASE loRes.Type = "A"
       RETURN THIS.ParseArrayJson(loRes)
   OTHERWISE
       RETURN this.ParseValueJson(loRes)
ENDCASE          

ENDFUNC
*   DeserializeXml

************************************************************************
*  ParseValue
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION ParseValueJson(loRes)
RETURN this.oBridge.GetProperty(loRes,"Value")
ENDFUNC
*   ParseValueJson


************************************************************************
*  ParseObject
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION ParseObjectJson(loObject)
LOCAL loResult, loMembers, loMember, lnCount, lnX, lvValue, lcName

loResult = CREATEOBJECT("EMPTY")

loMembers = this.oBridge.InvokeMethod(loObject,"GetMembers")
lnCount =loMembers.Count

FOR lnX = 0 TO lnCount-1
   loMember = loMembers.Item(lnX)
   lvValue = null
   
   DO CASE 
	CASE loMember.Type = "O"
   	  lvValue = THIS.ParseObjectJson(loMember)
	CASE loMember.Type = "A"
	  lvValue = THIS.ParseArrayJson(loMember)
	OTHERWISE
	  lvValue = this.ParseValueJson(loMember)
   ENDCASE
   
   lcName = loMember.Name
   lcName_First = LEFT(lcName,1)
   IF ISDIGIT(lcName_First)
      lcName = "_" + lcName
   ENDIF
   
   *** Ignore 'temporay names'
   IF THIS.IgnoreDollarVars AND lcName = "$"
     LOOP
   ENDIF
  
   *** Normalize Property Name
   lcName = CHRTRAN(lcName," `~!@#$%^&*()-+={}[]\|/?.,<>:;'" + ["],"")
   
   ADDPROPERTY(loResult,lcName,lvValue)
ENDFOR   

RETURN loResult
ENDFUNC

************************************************************************
*  ParseArrayJson
****************************************
***  Function:
***    Assume:
***      Pass: 
***    Return: Returns array as a wwCollection object
************************************************************************
PROTECTED FUNCTION ParseArrayJson(loObject)
LOCAL loCollection, loValue, loValues, lvValue, lnCount, lnX

loCollection = CREATEOBJECT("Collection")

loValues = this.oBridge.InvokeMethod(loObject,"GetValues")
lnCount = loValues.Count

FOR lnX = 0 TO lnCount-1
   loValue = loValues.Item(lnX)
   lvValue = null
   
   DO CASE 
	CASE loValue.Type = "O"
   	  lvValue = THIS.ParseObjectJson(loValue)
	CASE loValue.Type = "A"
	  lvValue = THIS.ParseArrayJson(loValue)
	OTHERWISE
	  lvValue = this.ParseValueJson(loValue)
   ENDCASE
   
   loCollection.Add(lvValue)
ENDFOR   

RETURN loCollection
ENDFUNC
*   ParseArray

************************************************************************
* wwJsonSerializer ::  Property
****************************************
***  Function: Custom version of FoxPro's AddProperty that
***            automatically adds the property's name to the
***            PropertyOverrides list
***    Assume:
***      Pass: loObject
***            lcProperty
***            lvValue
***    Return: nothing
************************************************************************
FUNCTION Property(loObject, lcProperty, lvValue)
ADDPROPERTY(loObject,lcProperty, lvValue)
THIS.PropertyNameOverrides = THIS.PropertyNameOverrides + ","  +lcProperty
ENDFUNC
*  wwJsonSerializer ::  AddProperty

************************************************************************
*  FormatJson
****************************************
***  Function: Takes a raw JSON string and turns it into indented
***            JSON fit for easier display.
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FormatJson(lcJson)

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")

RETURN loSer.FormatJson(lcJson)
ENDFUNC
*   FormatJson

ENDDEFINE