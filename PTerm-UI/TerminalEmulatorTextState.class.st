Class {
	#name : #TerminalEmulatorTextState,
	#superclass : #Object,
	#instVars : [
		'string',
		'stringSize',
		'fgRuns',
		'bgRuns',
		'emRuns',
		'cursorCol',
		'changed',
		'selection',
		'lastCol'
	],
	#category : #'PTerm-UI'
}

{ #category : #'instance creation' }
TerminalEmulatorTextState class >> new [

	^super new initialize
]

{ #category : #'instance creation' }
TerminalEmulatorTextState class >> new: size [

	^self string: (String new: size withAll: $ )
]

{ #category : #'instance creation' }
TerminalEmulatorTextState class >> string: aString [

	^super new initialize: aString
]

{ #category : #selection }
TerminalEmulatorTextState >> appendSelectionTo: aStream [

	selection isNil ifTrue: [^self].	"no selection"
	selection first > lastCol ifTrue: [^aStream cr].	"only the end of line is selected"
	selection first to: (selection last min: lastCol) do: [:i | aStream nextPut: (string at: i)].	"line contents are selected"
	selection last > lastCol ifTrue: [aStream cr].	"end of line is included in selection"
]

{ #category : #accessing }
TerminalEmulatorTextState >> at: index insert: char fg: fg bg: bg em: em [

	stringSize - 1 to: index by: -1 do: [:i |
		string at: i + 1 put: (string at: i).
		fgRuns at: i + 1 put: (fgRuns at: i).
		bgRuns at: i + 1 put: (bgRuns at: i).
		emRuns at: i + 1 put: (emRuns at: i)].
	string at: index put: char.
	self foregroundAt: index put: fg.
	self backgroundAt: index put: bg.
	lastCol := lastCol + 1 min: stringSize max: index.
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> at: index put: char fg: fg bg: bg em: em [

	((string at: index) ~~ char
			or: [(fgRuns at: index) ~~ fg
			or: [(bgRuns at: index) ~~ bg
			or: [(emRuns at: index) ~~em]]])
		ifTrue:
			[string at: index put: char.
			 self foregroundAt: index put: fg.
			 self backgroundAt: index put: bg.
			 emRuns at: index put: em.
			 lastCol := lastCol max: index.
			 changed := true]
]

{ #category : #accessing }
TerminalEmulatorTextState >> atAllPut: char fg: fg bg: bg em: em [
	"Update the receiver's string, colour and emphasis."

	string from: 1 to: stringSize put: char.
	fgRuns from: 1 to: stringSize put: fg.
	bgRuns from: 1 to: stringSize put: bg.
	emRuns from: 1 to: stringSize put: em.
	lastCol := char == $  ifTrue: [1] ifFalse: [stringSize].
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> background: bgIndex [

	1 to: stringSize do: [:i | self backgroundAt: i put: bgIndex]
]

{ #category : #accessing }
TerminalEmulatorTextState >> backgroundAt: index put: c [

	(bgRuns at: index) ~~ c
		ifTrue:
			[bgRuns at: index put: c.
			 changed := true]
]

{ #category : #accessing }
TerminalEmulatorTextState >> basicAt: index put: char fg: fg bg: bg em: em [

	string at: index put: char.
	self foregroundAt: index put: fg.
	self backgroundAt: index put: bg.
	emRuns at: index put: em.
	lastCol := lastCol max: index.
]

{ #category : #accessing }
TerminalEmulatorTextState >> bgRuns [

	^bgRuns
]

{ #category : #accessing }
TerminalEmulatorTextState >> changed [

	^changed
]

{ #category : #accessing }
TerminalEmulatorTextState >> changed: aBoolean [

	changed := aBoolean
]

{ #category : #selection }
TerminalEmulatorTextState >> clearSelection [
	selection isNil ifTrue: [^self].
	selection last > emRuns size ifTrue:[^self].
	selection first to: selection last do: [:i | emRuns at: i put: ((emRuns at: i) bitXor: 64)].
	selection := nil.
	changed := true
]

{ #category : #copying }
TerminalEmulatorTextState >> copy [

	^self deepCopy
]

{ #category : #accessing }
TerminalEmulatorTextState >> cursorCol: x [

	cursorCol := x.
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> cursorColumn [

	^cursorCol
]

{ #category : #accessing }
TerminalEmulatorTextState >> deleteCharAt: index [
	"Delete the character at index, moving anything to the right of it left one column."

	index to: stringSize - 1 do: [:i |
		string at: i put: (string at: i + 1).
		fgRuns at: i put: (fgRuns at: i + 1).
		bgRuns at: i put: (bgRuns at: i + 1).
		emRuns at: i put: (emRuns at: i + 1)].
	string at: stringSize put: $ .
	lastCol := lastCol - 1 max: 0.
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> emRuns [

	^emRuns
]

{ #category : #accessing }
TerminalEmulatorTextState >> fgRuns [

	^fgRuns
]

{ #category : #selection }
TerminalEmulatorTextState >> findFirstInClass: charClasses from: start [
	"Find the index of the leftmost character in the sequence of characters beginning at start that all belong to the same class in charClasses."

	| charClass |
	charClass := charClasses at: (string at: start) asciiValue + 1.
	start - 1 to: 1 by: -1 do: [ :i | (charClasses at: (string at: i) asciiValue + 1) == charClass ifFalse: [^i + 1]].
	^1.
]

{ #category : #private }
TerminalEmulatorTextState >> findLastColumn [

	stringSize to: 1 by: -1 do: [ :i | (string at: i) == $  ifFalse: [^lastCol := i]].
	^lastCol := 0.
]

{ #category : #selection }
TerminalEmulatorTextState >> findLastInClass: charClasses from: start [
	"Find the index of the rightmost character in the sequence of characters beginning at start that all belong to the same class in charClasses."

	| charClass |
	charClass := charClasses at: (string at: start) asciiValue + 1.
	start + 1 to: lastCol do: [ :i | (charClasses at: (string at: i) asciiValue + 1) == charClass ifFalse: [^i - 1]].
	^lastCol.
]

{ #category : #accessing }
TerminalEmulatorTextState >> foreground: fbIndex [

	1 to: stringSize do: [:i | self foregroundAt: i put: fbIndex]
]

{ #category : #accessing }
TerminalEmulatorTextState >> foregroundAt: index put: c [

	(fgRuns at: index) ~~ c
		ifTrue:
			[fgRuns at: index put: c.
			 changed := true]
]

{ #category : #accessing }
TerminalEmulatorTextState >> from: start to: stop put: char fg: fg bg: bg em: em [

	string from: start to: stop put: char.
	fgRuns from: start to: stop put: fg.
	bgRuns from: start to: stop put: bg.
	emRuns from: start to: stop put: em.
	changed := true
]

{ #category : #'initialize-release' }
TerminalEmulatorTextState >> initialize [
	"Initialize the receiver with empty contents."

	self initialize: (String new: 0)
]

{ #category : #'initialize-release' }
TerminalEmulatorTextState >> initialize: aString [
	"Initialize the receiver with the given contents."

	string := aString.
	stringSize := string size.
	fgRuns := Array new: stringSize withAll: 0.
	bgRuns := Array new: stringSize withAll: 7.
	emRuns := Array new: stringSize withAll: 0.
	cursorCol := 0.
	changed := true.	"want initial display"
	selection := nil.
	lastCol := 0.
]

{ #category : #accessing }
TerminalEmulatorTextState >> insertAt: index [

	stringSize - 1 to: index by: -1 do: [:i |
		string at: i + 1 put: (string at: i).
		fgRuns at: i + 1 put: (fgRuns at: i).
		bgRuns at: i + 1 put: (bgRuns at: i).
		emRuns at: i + 1 put: (emRuns at: i)].
	lastCol := lastCol + 1 min: stringSize max: index.
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> lastColumn [
	"Answer the rightmost column into which a character has been explicitly written."

	^lastCol
]

{ #category : #accessing }
TerminalEmulatorTextState >> lastColumn: col [
	"Somebody has deleted everythig from col onwards."

	lastCol := col
]

{ #category : #selection }
TerminalEmulatorTextState >> selectFrom: left to: right [
	right > emRuns size ifTrue:[^self]. 
	selection isNil ifFalse: [self clearSelection].
	selection := Array with: left with: right.
	left to: right do: [:i | emRuns at: i put: ((emRuns at: i) bitXor: 64)].
	changed := true
]

{ #category : #accessing }
TerminalEmulatorTextState >> selection [
	"Answer the selection range for this line."

	^selection
]

{ #category : #selection }
TerminalEmulatorTextState >> selectionSpansColumn: index [
	"Answer whether index is inside the current selection range."

	^selection notNil and: [index >= selection first and: [index <= selection last]]
]

{ #category : #accessing }
TerminalEmulatorTextState >> setWidth: width [

	string size < width
		ifTrue: [self string: (string forceTo: width paddingWith: $ )]
		ifFalse: [string size > width
			ifTrue: [self from: width + 1 to: string size  put: $  fg: 0 bg: 7 em: 0]].
	stringSize := width.
	self findLastColumn.
]

{ #category : #accessing }
TerminalEmulatorTextState >> string [
	"check doble world here to return a correct string
	|off tr|
	off := (string select: [:c| c isFullWidth]) size.
	off = 0 ifTrue:[^string].
	tr := string truncateTo: string size - off.
	^tr"
	^string
]

{ #category : #accessing }
TerminalEmulatorTextState >> string: aString [
	"Replace the receiver's string with aString.  If the receiver changes width then also modify the colours and emphasis retaining the overlapping portions and extending with default colours and emphasis, and then update the geometry.  Reset lastCol to be the index of the last non-whitespace in aString."

	| oldSize newSize |
	oldSize := string size.
	newSize := aString size.
	string := aString.
	oldSize < newSize
		ifTrue:
			[fgRuns := fgRuns forceTo: newSize paddingWith: 0.
			 bgRuns := bgRuns forceTo: newSize paddingWith: 7.
			 emRuns := emRuns forceTo: newSize paddingWith: 0]
		ifFalse:
			[fgRuns from: newSize + 1 to: oldSize put: 0.
			 bgRuns from: newSize + 1 to: oldSize put: 7.
			 emRuns from: newSize + 1 to: oldSize put: 0].
	cursorCol := cursorCol min: newSize.
	stringSize := newSize.
	self findLastColumn.
	selection := nil
]

{ #category : #accessing }
TerminalEmulatorTextState >> stringSize [

	^stringSize
]
