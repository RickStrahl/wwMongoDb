#INCLUDE WCONNECT.H

SET PROCEDURE TO wwCollections ADDITIVE

*************************************************************
DEFINE CLASS wwCollection AS Relation
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/19/2005
*************************************************************

*** Custom Properties

*** Stock Properties
DIMENSION aItems[1] 
Count = 0

************************************************************************
* wwCollection :: Add
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Add(lvValue)

THIS.Count = THIS.Count + 1
DIMENSION THIS.aItems[this.Count]
this.aItems[this.Count] = lvValue

ENDFUNC

************************************************************************
* wwCollection :: InsertAt
****************************************
***  Function: Inserts an item into the array at the specified
***            Position.
***    Assume:
***      Pass: lvValue
***              lvValue to insert
***
***            Position
***              Position to insert it *before*. New item becomes
***              the item at this position. Existing item is shifted down
***    Return: nothing
************************************************************************
FUNCTION InsertAt(Position,lvValue)

DIMENSION this.aItems[this.Count + 1]
IF AINS(this.aItems,Position) = 1 
   this.aItems[Position] = lvValue
   this.Count = this.Count + 1
ENDIF

ENDFUNC
*  wwCollection :: Insert

************************************************************************
* wwCollection :: Item
****************************************
***  Function: Returns an item out of the collection
***    Assume:
***      Pass: lvKey  -  numeric index or Key String value
***    Return: value or .NULL. if not found
************************************************************************
FUNCTION Item(Index)
RETURN this.aItems[Index] 
ENDFUNC

FUNCTION Get(Index)
RETURN THIS.aItems[Index]
ENDFUNC

************************************************************************
* wwCollection ::  GetIndex
****************************************
***  Function: Returns the index of the item
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetIndex(lvValue)
return ASCAN(this.aItems,lvValue,-1,-1,1,1 + 2)
ENDFUNC
*  wwCollection ::  GetIndex

************************************************************************
* wwCollection :: Remove
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Remove(Index)
LOCAL lnRow
THIS.Count = THIS.Count - 1
* this.aItems[Index] = .F.  && Ensure the item is released   no effect
ADEL(this.aItems,Index)
ENDFUNC

************************************************************************
* wwCollection ::  UpdateItem
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateItem(lnIndex,lvValue)
this.aItems[lnIndex] = lvValue
ENDFUNC
*  wwCollection ::  UpdateItem

FUNCTION Dispose
THIS.aItems=null
ENDFUNC

FUNCTION Destroy
THIS.aItems=null
ENDFUNC

************************************************************************
* wwCollection :: Clear
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Clear(llComplete)
LOCAL lnX

IF llComplete
	FOR lnX = 1 TO this.Count
		this.aItems[lnX] = null		
	ENDFOR
ENDIF	

THIS.Count = 0
THIS.aItems = .f.
this.aItems = null

ENDFUNC
*  wwCollection :: Clear

************************************************************************
* wwCollection ::  Sort
****************************************
***  Function: Sorts the list
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Sort()
	ASORT(this.aItems,1,ALEN(this.Items))
ENDFUNC
*  wwCollection ::  Sort

************************************************************************
* wwCollection ::  ToArray
****************************************
***  Function: Returns the Collection as an array.
***    Assume:
***      Pass: @laList  -  An Array Variable
***    Return: nothing (@laList is set)
************************************************************************
FUNCTION ToArray(laList)
ACOPY(this.aItems,laList)
ENDFUNC
*  wwCollection ::  ToArray


ENDDEFINE
*EOC wwCollection 

*************************************************************
DEFINE CLASS wwNameValueCollection AS WWC_WWCOLLECTION
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/18/2005
***************************

DIMENSION aItems[1,2] 
Count = 0

************************************************************************
* wwNameValueCollection :: FastAdd
****************************************
***  Function: FastAdd Adds items without checking for uniqueness first
***    Assume: Considerably faster than regular Add. Use when you know
***            items are added only once.
***      Pass:
***    Return:
************************************************************************
FUNCTION FastAdd(lvKey,lvValue)

THIS.Count = THIS.Count + 1

IF PCOUNT() = 1
   lvValue = lvKey
   lvKey = TRANSFORM(this.Count)
ENDIF
   
DIMENSION THIS.aItems[this.Count,2]
this.aItems[this.Count,1] = lvKey
this.aItems[this.Count,2] = lvValue

ENDFUNC

************************************************************************
* wwNameValueCollection :: Add
****************************************
***  Function: Adds an item to the collection by first checking
***            for existance. If found overwrites existing value
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Add(lvKey,lvValue)
LOCAL lnIndex

lnIndex = THIS.GetIndex(lvKey)
IF lnIndex = 0
   THIS.FastAdd(lvKey,lvValue)
ELSE
   *** Otherwise update exist key
   THIS.aItems[lnIndex,1] = lvKey
   THIS.aItems[lnIndex,2] = lvValue
ENDIF

ENDFUNC
*  wwNameValueCollection :: AddUnique

************************************************************************
* wwNameCollection :: Insert
****************************************
***  Function: Inserts an item into the array at the specified
***            Position.
***    Assume:
***            Position
***              Position to insert it *before*. New item becomes
***              the item at this position. Existing item is shifted down
***            lvKey
***               Key of the value to insert
****           lvValue
***              Value to insert
***
***    Return: nothing
************************************************************************
FUNCTION InsertAt(Position,lvKey,lvValue)

IF PARAMETERS() = 2
   lvValue = lvKey
   lvKey = TRANSFORM(this.Count)
ENDIF

DIMENSION this.aItems[this.Count + 1,2]

IF AINS(this.aItems,Position) = 1 
   this.aItems[Position,1] = lvKey
   this.aItems[Position,2] = lvValue
   this.Count = this.Count + 1
ENDIF

ENDFUNC
*  wwCollection :: Insert

************************************************************************
* wwNameValueCollection :: Item
****************************************
***  Function: Returns an item out of the collection
***    Assume:
***      Pass: lvKey  -  numeric index or Key String value
***    Return: value or .NULL. if not found
************************************************************************
FUNCTION Item(lvKey)
LOCAL lnElement

IF VARTYPE(lvKey) = "N"
   RETURN this.aItems[lvKey,2]
ELSE
   lnElement = ASCAN(this.aItems,lvKey,1,this.Count,1,7) && Case insensitive/exact on
   IF lnElement = 0
      RETURN null
   ENDIF

   RETURN this.aItems[lnElement+1]
ENDIF

ENDFUNC

************************************************************************
* wwNameValueCollection ::  Get
****************************************
***  Function: Returns an object with Key and Value properties
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Get(lvKey)

loRes = CREATEOBJECT("Empty")
ADDPROPERTY(loRes,"Key","")
ADDPROPERTY(loREs,"Value","")

loRes.Key = this.GetKey(lvKey)
loRes.Value = this.Item(lvKey)	

IF ISNULL(loRes.Key)
   RETURN null
ENDIF   

RETURN loRes
ENDFUNC
*  wwNameValueCollection ::  Get
************************************************************************
* wwNameValueCollection ::  GetKey
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetKey(Index)
   RETURN THIS.aItems[Index,1]
ENDFUNC

************************************************************************
* wwNameValueCollection ::  GetIndex
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetIndex(lvKey)
LOCAL lnElement
   lnElement = ASCAN(this.aItems,lvKey,1,this.Count,1,7)  && Case insensitive/exact on
   IF lnElement > 0
      RETURN (lnElement + 1)/2
   ENDIF
   RETURN 0
ENDFUNC

************************************************************************
* wwNameValueCollection :: Remove
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Remove(lvKey)
LOCAL lnRow
   IF VARTYPE(lvKey) = "N"
   	  this.aItems[lvKey,2]= .f. && Clear value
      ADEL(this.aItems,lvKey)
   ELSE
   	  LOCAL lnRow
      lnRow = this.GetIndex(lvKey)
      IF lnRow = 0
         RETURN
      ENDIF
      ADEL(this.aItems,lnRow)
   ENDIF
   THIS.Count = THIS.Count - 1
ENDFUNC

************************************************************************
* wwNameValueCollection ::  UpdateItem
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateItem(lvKey,lvValue)

IF VARTYPE(lvKey) = "N"
  this.aItems[lvKey,2]= lvValue
ELSE
  LOCAL lnRow
  lnRow = this.GetIndex(lvKey)
  IF lnRow = 0
     RETURN .F.
  ENDIF
  this.aItems[lnRow, 2] =  lvValue
ENDIF

ENDFUNC
*  wwNameValueCollection ::  UpdateItem

************************************************************************
* wwNameValueCollection :: Clear
****************************************
***  Function:
***    Assume:
***      Pass: llComplete - forces each item to be nulled explicitly
***    Return:
************************************************************************
FUNCTION Clear(llComplete)
LOCAL lnX

IF llComplete
	FOR lnX = 1 TO this.Count
		this.aItems[lnX,2] = null		
	ENDFOR
ENDIF	

THIS.Count = 0
THIS.aItems = .f.
this.aItems = null

ENDFUNC
*  wwCollection :: Clear


************************************************************************
* wwNameValueCollection :: ToAttributeString
****************************************
***  Function: Loops through name value pairs and creates attribute
***            strings
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToAttributeString(lcSeparator)
LOCAL lnX, lcOutput
lcOutput = ""

IF EMPTY(lcSeparator)
  lcSeparator = " "
ENDIF

FOR lnX = 1 TO THIS.Count
   lcOutput = lcOutput + this.aItems[lnX,1] + [="] + TRANSFORM(this.aItems[lnX,2]) + ["] + lcSeparator
ENDFOR 

RETURN lcOutput
ENDFUNC
*  wwNameValueCollection :: ToAttributeString


FUNCTION Dispose
THIS.aItems=null
ENDFUNC

FUNCTION Destroy
THIS.aItems=null
ENDFUNC

ENDDEFINE

*************************************************************
DEFINE CLASS wwStack AS WWC_WWCOLLECTION
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/20/2005
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class wwStack

*:Description:

*:Example:

*:Remarks:

*:SeeAlso:


*:ENDHELP
#ENDIF

*** Custom Properties
nStackPointer = 0

*** Stock Properties
************************************************************************
* wwStack :: Push
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Push(lvValue)
THIS.Add(lvValue)
ENDFUNC
*  wwStack :: Push

************************************************************************
* wwStack :: Pop
****************************************
***  Function: Pops an item off the stack
***    Assume:
***      Pass:
***    Return: value of the last item on the stack. Null if stack is empty
************************************************************************
FUNCTION Pop()
LOCAL lvValue

IF THIS.Count < 1
   RETURN null
ENDIF

lvValue = THIS.aItems[THIS.Count]
THIS.Remove(THIS.Count)

RETURN lvValue
ENDFUNC
*  wwStack :: Pop

************************************************************************
* wwStack :: Peek
****************************************
***  Function: Returns the last item without popping it off the stack
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Peek()
LOCAL lvValue

IF THIS.Count < 1
   RETURN null
ENDIF

lvValue = THIS.aItems[THIS.Count]

RETURN lvValue
ENDFUNC
*  wwStack :: Peek

*** Hide Other Collection methods
PROTECTED FUNCTION Add(lvValue)
DODEFAULT(lvValue)
ENDFUNC


PROTECTED FUNCTION Remove(lnIndex)
DODEFAULT(lnIndex)
ENDFUNC

ENDDEFINE
*EOC wwStack 



*** wwBusiness Related Collections

*************************************************************
DEFINE CLASS wwValidationError AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 11/16/2005
*************************************************************
*** Custom Properties

*** Stock Properties

*** The Error Message for the validation Error
cMessage  = ""

*** Optional name of the object it applies to
cObjectName = ""

ENDDEFINE

*************************************************************
DEFINE CLASS wwValidationErrors AS wwCollection
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 11/16/2005
*************************************************************

************************************************************************
* wwValidationErrors :: ToString
****************************************
***  Function: Turns the Validation Errors into a string
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToString()
LOCAL lcOutput, lnX

lcOutput = ""
FOR lnX = 1 TO this.Count
   IF lnX < this.Count
      lcOutput = lcOutput + this.aItems[lnX].cMessage + CHR(13) + CHR(10)
   ELSE
      lcOutput = lcOutput + this.aItems[lnX].cMessage 
   ENDIF   
ENDFOR

RETURN lcOutput
ENDFUNC

ENDDEFINE
