SET PROCEDURE TO wwRegEx ADDITIVE

#IF .F.
CLEAR
lcText = "Here we go<h3>Header</H3><br>More Text <h2>Header again</H2><br>asasa"
? lcText

loRegEx = CREATEOBJECT("wwRegEx")
loRegEx.IgnoreCase=.T.
? loRegEx.Replace(lcText,[(</h\d><br>)],"STRTRAN(lcMatch,[<br>],[])",.T.)

#ENDIF

RETURN

*************************************************************
DEFINE CLASS wwRegEx AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2007
*:Contact: http://www.west-wind.com
*:Created: 03/04/07
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class wwRegEx

*:Description:
RegEx class based on the VBScript RegEx class. Instance
loads up the VBScript RegEx object and keeps it alive in
this instance.

This class matches the RegEx class signature and then adds
a number of useful high level methods.

*:Example:

*:Remarks:

*:SeeAlso:


*:ENDHELP
#ENDIF

RegEx = null

*** Custom Properties

*** Case Sensitivity
IgnoreCase = .T.

*** Determines if single or multiple matches are found
Global = .T.

*** Multiple line support
MultiLine = .F.

*** Match Collection after call to Match()
Matches = null


FUNCTION IgnoreCase_Assign(value)
this.RegEx.IgnoreCase = value
ENDFUNC

FUNCTION Global_Assign(value)
this.RegEx.Global = value
ENDFUNC

FUNCTION MultiLine_Assign(value)
this.RegEx.MultiLine = value
ENDFUNC

*** Stock Properties

************************************************************************
* wwRegEx ::  Init
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init()

this.RegEx = CREATEOBJECT("VBScript.RegExp")

*** Have to set initial values here
this.RegEx.Global = .T.
this.RegEx.Ignorecase = .T.

ENDFUNC
*  wwRegEx ::  Init

************************************************************************
* wwRegEx ::  Match
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Match(lcSource,lcRegEx)

this.RegEx.Pattern = lcRegEx
this.Matches = this.RegEx.Execute(lcSource)

RETURN THIS.Matches
ENDFUNC
*  wwRegEx ::  Match

************************************************************************
* wwRegEx ::  Test
****************************************
***  Function: Tests a regEx expression.
***    Assume:
***      Pass:
***    Return: .T. if a match is found .F. otherwise
************************************************************************
FUNCTION Test(lcSource,lcRegEx)
this.RegEx.Pattern = lcRegEx
RETURN this.RegEx.Test(lcSource)
ENDFUNC
*  wwRegEx ::  Test

************************************************************************
* wwRegEx ::  Replace
****************************************
***  Function: Replaces the replace string or expression for
***            any RegEx matches found in a source string
***    Assume: NOTE: very different from native REplace method
***      Pass: lcSource
***            lcRegEx
***            lcReplace   -   String or Expression to replace with
***            llIsExpression - if .T. lcReplace is EVAL()'d
***
***            Expression can use a value of lcMatch to get the
***            current matched string value.
***    Return: updated string
************************************************************************
FUNCTION Replace(lcSource,lcRegEx,lcReplace,llIsExpression)
LOCAL loMatches, lnX, loMatch, lcRepl
PRIVATE lcMatch
this.RegEx.Pattern = lcRegEx
loMatches = this.RegEx.Execute(lcSource)

lnCount = loMatches.Count

IF lnCount = 0
   RETURN lcSource
ENDIF

lcRepl = lcReplace

*** Note we have to go last to first to not hose 
*** relative string indexes of the match
FOR lnX = lnCount -1 TO 0 STEP -1
	loMatch = loMatches.Item(lnX)
	lcMatch = loMatch.Value
	IF llIsExpression
		*** Evaluate dynamic expression each time		
		lcRepl = EVAL( lcReplace )
	ENDIF	
	lcSource = STUFF(lcSource,loMatch.FirstIndex+1,loMatch.Length,lcRepl)
ENDFOR

RETURN lcSource
* wwRegEx : Replace

************************************************************************
* wwRegEx ::  StripExpressions
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION aStripExpressions(laMatches,lcText,lcRegEx,lcReplaceWith)
LOCAL lnCount, lnX, loMatches

this.RegEx.Pattern = lcRegEx
loMatches = this.RegEx.Execute(lcText)

lnCount = loMatches.Count

IF lnCount = 0
   RETURN 0
ENDIF

DIMENSION laMatches[lnCount]

FOR lnX = 1 TO lnCount
	loMatch = loMatches.Item(lnX-1)
	lcMatch = loMatch.Value
	
	laMatches[lnX] = lcMatch
	lcText = STRTRAN(lcText,lcMatch,lcReplaceWith)
ENDFOR

RETURN lnCount
ENDFUNC
*  wwRegEx ::  StripExpressions

************************************************************************
* wwRegEx ::  RestoreExpressions
****************************************
***  Function: Strips a set of matched strings from the 
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION aRestoreExpressions(laMatches,lcText,lcReplaceText)
LOCAL lnX

FOR lnX = 1 TO ALEN(laMatches,1)
	lcText = STRTRAN(lcText,lcReplaceText,laMatches[lnX],1,1)
ENDFOR

RETURN lcText
ENDFUNC
*   aRestoreExpressions



ENDDEFINE
*EOC wwRegEx 
