"
I am a glass teletype.  I accept raw input from some source (which I display without interpretation) and generate raw characters for some sink.

I implement sufficient cursor addressing and character attributes to provide terminal emulators with the necessary support to implement ANSI (ISO 6429) colours and emphasis (with the exception of blinking) and the full range of VT220-style cursor-based screen editing.  However, I make no attempt to interpret ASCII control characters nor ANSI, DEC (or any other) escape sequences.  This, like all other `cooked' interpratation of special characters, is left entirely to my source and sink (which will normally be the same instance of some terminal emulator, immediately below me in a protocol stack).

I am designed to be the head of a protocol stack.  For this reason I expect my source to send me #upcall: aCharacter (I am the high protocol for some emulator) and I pass keyboard events down to my sink by sending it #downcall: aCharacter (the sink is my low protocol).  Anybody can send me #delete which I will propagate to all members of my protocol stack as a #windowClosed note.  (This will normally cause any connected endpoints at the tail end of the stack to be disconnected and destroyed.)

	TerminalEmulatorMorph new openInWorld

"
Class {
	#name : #TerminalEmulatorMorph,
	#superclass : #Morph,
	#instVars : [
		'inset',
		'font',
		'pitch',
		'skip',
		'rows',
		'cols',
		'lines',
		'savedLines',
		'savedLineLimit',
		'displayStart',
		'topLine',
		'bottomLine',
		'down',
		'x',
		'y',
		'fg',
		'bg',
		'em',
		'rv',
		'ec',
		'tabs',
		'scroll',
		'scrollOn',
		'autoWrap',
		'reverseWrap',
		'autoLinefeed',
		'autoCR',
		'relativeOrigin',
		'insertMode',
		'showCursor',
		'session',
		'systemWindow',
		'running',
		'autoFlush',
		'smoothScroll',
		'steps',
		'metaSendsEscape',
		'deleteIsDel',
		'altScreenSwitch',
		'altScreenActive',
		'altScreenColours',
		'reverseVideo',
		'hasFocus',
		'mousePosition',
		'selectionStart',
		'selectionEnd',
		'selectionActive',
		'selection',
		'trackingSelection',
		'mouseControlsSelection',
		'keyboardControlsSelection',
		'scrollOnInput',
		'scrollOnOutput',
		'allow132',
		'characterClasses',
		'cursorColour'
	],
	#classVars : [
		'CharClass',
		'KeyboardControlsSelection',
		'MouseControlsSelection',
		'SaveTerminalSize',
		'SavedLineLimit',
		'TextCursor'
	],
	#category : #'PTerm-UI'
}

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> example [
	"TerminalEmulatorMorph example"

	| echo tty |
	"Pushing tty onto localEcho will convert ASCII control chars into tty cursor commands."
	(echo := ProtocolAdaptor new) localEcho asProtocolStack push: (tty := self new openInHand); install; run.
	echo downcallAll: TerminalEmulatorMorph organization classComment string asByteArray.
	tty activePosition: 1@24; flush.
	^tty
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> example2 [
	"TerminalEmulatorMorph example2"

	| top tty |
	top := ScrollPane new scroller: (tty := TerminalEmulatorMorph new).
	ProtocolAdaptor new localEcho asProtocolStack push: tty; install; run.
	top openInHand
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> initialize [
	"TerminalEmulatorMorph initialize"

	self initializeCursor.
	self initializeCharacterClasses.
	SavedLineLimit := 64.
	"Set the default selection handling behaviour."
	MouseControlsSelection := true.
	KeyboardControlsSelection := false.
	"Notes:
	If MouseControlsSelection then selected text is copied to the clipboard when selection tracking finishes and the yellow button pastes from the clipboard into the terminal window.  Note that this moves the VT Options menu off the yellowButton and onto control-yellowButton (which is usually bound to the morph menu by things beyond our control; i.e., the VT menu becomes unavailable from within the TtyMorph itself.).
	If KeyboardControlsSelection then cmd-c copies the last mouse selection to the clipboard and cmd-v pastes the clipboard text into the terminal.  Note that this means M-C and M-V will no longer be available to programs such as Emacs.
	Note also that these can be in effect simultaneously to have both mouse and keyboard control of the selection.
	By default we turn mouse selection on and keyboard selection off.  This way the TtyMorph responds to the mouse like a real xterm and the M-C and M-V keys are passed unhindered to Emacs."
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> initializeCharacterClasses [
	"TerminalEmulatorMorph initializeCharacterClasses asByteArray inspect"
	"Clicking the red button twice in rapid succession will cause all adjacent characters of the same class (e.g., letters, white space, punctuation) under the pointer to be selected.  Since different people have different preferences for what should be selected (for example, whether filenames should be selected as a whole or as individual path components) the default mapping can be overridden through the use of the CharClass variable.  The default collects whitespace, alphanumeric and special graphics characters into three classes.  Each punctuation character is in a class of its own.
	NOTE: in order to see the contents of some of the strings in this method you might have to select their contents and then use the window menu to change their font to Fixed."

	"Start with each character in its own class."
	CharClass := (0 to: 255) asByteArray asString.
	"Put the ASCII whitespace characters (nul tab space) into the same class as space."
	#(0 9 32)
		do: [:c | CharClass at: 1 + c put: $ ].
	"Put the ASCII alphanumeric characters into the same class as `0'."
	'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ:=abcdefghijklmnopqrstuvwxyz'
		do: [:c | CharClass at: 1 + c asciiValue put: $0].
	"Put the ISO 8859 Latin-1 accented characters into the same class as `0'."
	'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ'
		do: [:c | CharClass at: 1 + c asciiValue put: $0].
	"Put the ANSI special graphics characters into the same class as SOH (char 1)."
	'

'
		do: [:c | CharClass at: 1 + c asciiValue put: (Character value: 1)].
	"All other characters are punctuation and remain singletons."
	^CharClass


	"The table below is pulled directly out of xterm.  Evaluate the following to yield an Array whose first element is the complete set of xterm char classes and whose second element contains just the three non-singleton classes:
	| s |
	s := IdentityDictionary new.
	#(32 1 1 1 1 1 1 1 1 32 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 32
	   33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 48 48 48 48 48 48 48
	   48 48 58 59 60 61 62 63 64 48 48 48 48 48 48 48 48 48 48 48 48 48 48
	   48 48 48 48 48 48 48 48 48 48 48 48 91 92 93 94 48 96 48 48 48 48 48
	   48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 123 124
	   125 126 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
	   1 1 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175
	   176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 48 48
	   48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 215 48
	   48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48 48
	   48 48 48 48 48 48 48 247 48 48 48 48 48 48 48 48)
		withIndexDo: [:e :i | (s at: e ifAbsent: [s at: e put: IdentitySet new]) add: i - 1].
	s := s associationsDo: [:a | a value: a value asSortedCollection asByteArray].
	^Array with: s with: (s select: [:v | v size > 1])
	"
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> initializeCursor [
	"TerminalEmulatorMorph initializeCursor"
	"TextCursor showWhile: [Sensor waitButton]"

	TextCursor :=   CursorWithMask derivedFrom:
		(Cursor
			extent: 16@16
			fromArray: #(
		2r0000000000000000
		2r0000111011100000
		2r0000001110000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000000100000000
		2r0000001110000000
		2r0000111011100000
		2r0000000000000000
		2r0)
			offset: -7 @ -7).
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> new [

	| tty |
	tty := super new initialize: 80@24.
	^tty
]

{ #category : #'as yet unclassified' }
TerminalEmulatorMorph class >> showCharacterClasses [
	"TerminalEmulatorMorph showCharacterClasses"

	| s range start stop |
	s := IdentityDictionary new.
	CharClass asByteArray withIndexDo: [:e :i | (s at: e ifAbsent: [s at: e put: IdentitySet new]) add: i - 1].
	s := (s associationsDo: [ :a | a value: a value asSortedCollection asByteArray]) select: [:v | v size > 1].
	s := String streamContents: [ :str |
		s keys asSortedCollection do: [ :key |
			range := ReadStream on: (s at: key).
			[range atEnd] whileFalse:
				[str nextPut: $,.start := range next.
				 stop := start.
				 [range atEnd not and: [stop + 1 == range peek]] whileTrue: [stop := range next].
				 str nextPutAll: start printString.
				 start == stop ifFalse: [str nextPut: $-; nextPutAll: stop printString].
				 str nextPut: $:; nextPutAll: key printString]]].
	s := s copyFrom: 2 to: s size.
	UIManager default
		request: 'Character classes'
		initialAnswer: s
]

{ #category : #accessing }
TerminalEmulatorMorph >> activeColumn [

	^x
]

{ #category : #accessing }
TerminalEmulatorMorph >> activeColumn: c [

	x := c min: cols.
	self showCursor.
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> activePosition [

	^x@y
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> activePosition: aPoint [

	self hideCursor.
	x := aPoint x min: cols max: 1.
	y := aPoint y min: rows max: 1.
	relativeOrigin ifTrue: [y := y + topLine - 1 min: bottomLine max: topLine].
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> autoFlush [

	(autoFlush := autoFlush - 1) < 1
		ifTrue:
			[self updateScrollbar; changed.
			 autoFlush := self autoFlushCount.
			 Processor yield.]
]

{ #category : #private }
TerminalEmulatorMorph >> autoFlushCount [

	^smoothScroll ifTrue: [2] ifFalse: [rows]
]

{ #category : #private }
TerminalEmulatorMorph >> banner [

	^''
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> bs [

	self cursorLeft: 1 wrapping: false
]

{ #category : #accessing }
TerminalEmulatorMorph >> bufferState [
	"Answer an opaque representation of the current state of the buffer contents."

	| theLines state |
	self clearSelection.
	theLines := OrderedCollection new.
	self linesDo: [:line | theLines addLast: line copy].
	state := Array with: theLines asArray with: rv with: altScreenActive with: x with: y with: cursorColour.
	altScreenActive := true.
	^state
]

{ #category : #accessing }
TerminalEmulatorMorph >> bufferState: state [
	"Restore the buffer contents to a previously saved state."

	| theLines nRows |
	altScreenSwitch ifFalse: [^self].
	self clearSelection; clearCursor.
	theLines := state at: 1.
	rv := state at: 2.
	altScreenActive := state at: 3.
	"Ensure we have sufficient lines in the display."
	[lines size < theLines size]
		whileTrue:
			[lines addLast: (TerminalEmulatorTextState new: cols).
			 self addMorphBack: (TerminalEmulatorLineMorph contents: lines last)].
	nRows := rows min: theLines size.
	1 to: nRows do: [ :i |
		(submorphs at: i)
			lineState:
			(self displayLineAt: i put:
				((theLines at: i) setWidth: cols))].
	nRows + 1 to: rows do: [:i | self clearLine: i from: 1 to: cols].
	submorphs from: 1 to: rows do: [ :m | m rv: (rv xor: reverseVideo)].
	x := (state at: 4) min: cols max: 1.
	y := (state at: 5) min: rows max: 1.
	cursorColour := state at: 6.
	self showCursor; linesChanged; changed
]

{ #category : #accessing }
TerminalEmulatorMorph >> characterClass [

	^CharClass
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> clearCursor [

	lines do: [ :line | line cursorCol: 0]
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearLine [

	self
		hideCursor;
		clearLine: y from: 1 to: cols;
		showCursor
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearLine: n from: l to: r [

	(self lineAt: n)
		from: l to: r put: $  fg: fg bg: bg em: 0;
		lastColumn: l - 1.
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearLineLeft [

	self
		clearSelection;
		hideCursor;
		clearLine: y from: 1 to: x;
		showCursor
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearLineRight [

	self
		clearSelection;
		hideCursor;
		clearLine: y from: x to: cols;
		showCursor
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearScreen [

	self hideCursor.
	1 to: rows do: [:i | self clearLine: i from: 1 to: cols].
	self showCursor.
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearScreenLeft [

	self
		clearSelection;
		hideCursor;
		clearLine: y from: 1 to: x.
	1 to: y - 1 do: [:i | self clearLine: i from: 1 to: cols].
	self showCursor.
	self flush
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> clearScreenRight [

	self
		clearSelection;
		hideCursor;
		clearLine: y from: x to: cols.
	y + 1 to: rows do: [:i | self clearLine: i from: 1 to: cols].
	self showCursor.
	self flush
]

{ #category : #selection }
TerminalEmulatorMorph >> clearSelection [
	"Remove the visual representation of the selection region.  Saved selection text is unaffacted."

	selectionActive ifFalse: [^self].
	lines do: [:line | line clearSelection].
	selectionActive := false.
	"self changed"
]

{ #category : #tabs }
TerminalEmulatorMorph >> clearTab [

	x <= cols ifTrue: [tabs at: x put: false].
"
	Transcript
		nextPutAll: 'tab CLR ', x printString; tab;
		nextPutAll: (String withAll: (tabs collect: [:t | t ifTrue: [$!] ifFalse: [$.]]));
		cr; endEntry
"
]

{ #category : #tabs }
TerminalEmulatorMorph >> clearTabs [

	tabs atAllPut: false.
]

{ #category : #accessing }
TerminalEmulatorMorph >> columns [

	^cols
]

{ #category : #selection }
TerminalEmulatorMorph >> copySelection [
	"Copy the currently selected text to the clipboard."

	Clipboard clipboardText: selection
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> cr [

	self hideCursor.
	x := 1.
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> currentLine [

	^lines at: lines size - rows + y
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> cursorDown: n scrolling: scrollFlag [
	self hideCursor.
	n timesRepeat: [self cursorDownScrolling: scrollFlag].
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> cursorDownScrolling: scrollFlag [

	(y >= bottomLine and: [scrollFlag]) ifTrue: [self scrollForward].
	y := y + 1 min: bottomLine
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> cursorLeft: n wrapping: wrapFlag [
	self hideCursor.
	n timesRepeat: [self cursorLeftWrapping: wrapFlag].
	self showCursor.
	"dont know why but need to signal changed here"
]

{ #category : #private }
TerminalEmulatorMorph >> cursorLeftWrapping: wrapFlag [

	x > 1 ifTrue: [^x := x - 1].
	(y > 1 and: [wrapFlag and: [reverseWrap]]) ifTrue: [x := cols.  y := y - 1]
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> cursorRight: n wrapping: wrapFlag [

	self hideCursor.
	n timesRepeat: [self cursorRightWrapping: wrapFlag].
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> cursorRightWrapping: wrapFlag [

	((x := x + 1) > cols and: [wrapFlag not]) ifTrue: [x := cols].
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> cursorUp: n scrolling: scrollFlag [

	self hideCursor.
	n timesRepeat: [self cursorUpScrolling: scrollFlag].
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> cursorUpScrolling: scrollFlag [

	(y <= topLine and: [scrollFlag]) ifTrue: [self scrollBackward].
	y := y - 1 max: topLine
]

{ #category : #private }
TerminalEmulatorMorph >> debug: message [

	Transcript nextPutAll: message; cr; endEntry
]

{ #category : #private }
TerminalEmulatorMorph >> debug: message with: arg [

	Transcript nextPutAll: message; space; print: arg; cr; endEntry
]

{ #category : #private }
TerminalEmulatorMorph >> deleteForward [

	(self protectSelection; currentLine) deleteCharAt: x
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> deleteForward: n [

	self hideCursor.
	n timesRepeat: [self deleteForward].
	self showCursor
]

{ #category : #accessing }
TerminalEmulatorMorph >> deleteIsDel [

	^deleteIsDel
]

{ #category : #accessing }
TerminalEmulatorMorph >> deleteIsDel: aBoolean [

	deleteIsDel := aBoolean
]

{ #category : #private }
TerminalEmulatorMorph >> deleteLine [

	^self scrollForwardFrom: y to: bottomLine
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> deleteLines: n [

	self hideCursor.
	n timesRepeat: [self deleteLine].
	self showCursor.
	self autoFlush
]

{ #category : #private }
TerminalEmulatorMorph >> displayLineAt: index [
	"Answer the displayed (visible) line at index."

	^lines at: displayStart + index
]

{ #category : #private }
TerminalEmulatorMorph >> displayLineAt: index put: anObject [
	"Change the displayed (visible) line at index."

	^lines at: displayStart + index put: anObject
]

{ #category : #private }
TerminalEmulatorMorph >> displayLinesDo: aBlock [

	lines from: displayStart + 1 to: displayStart + rows do: aBlock
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> doFullReset [
	"Clear the screen, reset tabs to every eight columns, and reset the terminal modes (such as wrap and smooth scroll) to their initial states just after terminal initialisation."

	self
		doSoftReset;
		clearSelection;
		clearScreen;
		activePosition: 1@1;
		initializeTabs;
		initializeTerminalModes;
		changed
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> doResetAndClear [
	"Reset the terminal to a sane state and clear the saved lines."

	self doFullReset.
	displayStart := 0.
	savedLines := 0.
	lines := lines copyFrom: lines size - rows + 1 to: lines size.
	self linesChanged; changed
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> doSoftReset [
	"Reset scroll regions.  This can be convenient when some program has left the scroll regions set incorrectly (often a problem when using VMS or TOPS-20)."

	topLine := 1.
	bottomLine := rows.
]

{ #category : #protocol }
TerminalEmulatorMorph >> down: protoLo [

	down := protoLo
]

{ #category : #private }
TerminalEmulatorMorph >> drawOn: aCanvas [

	super drawOn: aCanvas.
	self updateScrollbar.
]

{ #category : #selection }
TerminalEmulatorMorph >> endSelection: screenPosition [
	"Mouse selection has just finished.  Stop tracking and, iff the mouse moved since selection start, compute and remember the new selection text."

	self stopSteppingSelector: #trackSelection.
	self showCursor; changed.
	selectionEnd isNil ifTrue: [^nil].
	self saveSelection.
	screenPosition = mousePosition ifFalse: [selectionEnd := nil]
]

{ #category : #selection }
TerminalEmulatorMorph >> extendSelection: screenPosition [
	"Extend the current selection through screenPosition."

	selectionStart isNil ifFalse: [self trackSelection: screenPosition]
]

{ #category : #geometry }
TerminalEmulatorMorph >> extent: newExtent [
	"We're being allocated real estate from above (initial placement or manual resize).  Adjust the screen size accordingly."

	| layoutBounds textBounds nCols nRows org ext lineSkip |
	super extent: newExtent.
	layoutBounds := self layoutBounds.
	textBounds := self textBounds: layoutBounds.
	nCols := textBounds width // pitch.
	nRows := textBounds height // skip.
	self hideScrollbar; initTextBounds: textBounds width: nCols height: nRows.
	org := textBounds topLeft.
	ext := (cols * pitch) @ skip.
	lineSkip := 0 @ skip.
	submorphs doWithIndex: [:m :i |
		m bounds: (org extent: ext).
		org := org translateBy: lineSkip].
	self showScrollbar.
	self note: #resizeWindow with: nRows @ nCols
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> fillScreen: char [

	self
		clearSelection;
		linesDo: [:line | line atAllPut: char fg: fg bg: bg em: em]
]

{ #category : #protocol }
TerminalEmulatorMorph >> flush [

	submorphs from: 1 to: rows do: [ :m | m flush].
	autoFlush := self autoFlushCount.
	self updateScrollbar.
]

{ #category : #selection }
TerminalEmulatorMorph >> getSelectionRegion [
	"Answer a Rectangle representing the current selection area in character coordinates.  Note that the origin may be to the right of the corner."

	| start end tmp |
	(start := selectionStart) y > (end := selectionEnd) y ifTrue: [start := selectionEnd.  end := selectionStart].
	(start y == end y and: [start x > end x]) ifTrue: [tmp := start.  start := end.  end := tmp].
	"start now guaranteed to be before end in screen"
	"we don't include the character under selectionStart"
	end := end - (1@0).
	^Rectangle origin: start corner: end
]

{ #category : #accessing }
TerminalEmulatorMorph >> graphicsState [
	"Answer an opaque representation of the current character attributes."

	^Array with: fg with: bg with: em with: rv
]

{ #category : #accessing }
TerminalEmulatorMorph >> graphicsState: gs [
	"Restore the current character attributes.  (See #graphicsState.)"

	fg := gs at: 1.
	bg := gs at: 2.
	em := gs at: 3
]

{ #category : #events }
TerminalEmulatorMorph >> handlesKeyboard: evt [
	"Answer whether we're interested in keyboard events."
	^true
	"^hasFocus or: [super handlesKeyboard: evt]"
]

{ #category : #events }
TerminalEmulatorMorph >> handlesMouseDown: evt [
	"Answer whether we're interested in mouse events."
	^true
	"^self isConnected and: [hasFocus or: [super handlesMouseDown: evt]]"
]

{ #category : #events }
TerminalEmulatorMorph >> handlesMouseOver: evt [
	^true
	"^hasFocus or: [super handlesMouseOver: evt]"
]

{ #category : #accessing }
TerminalEmulatorMorph >> hasFocus [

	^hasFocus
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> hideCursor [

	self currentLine cursorCol: 0
]

{ #category : #scrolling }
TerminalEmulatorMorph >> hideOrShowScrollBar [

	"ScrollBar sends us this for no good reason."
]

{ #category : #geometry }
TerminalEmulatorMorph >> hideScrollbar [
	"Remove the scrollbar from the window."

	scroll notNil
		ifTrue:
			[scroll delete.
			 scroll := nil]
]

{ #category : #selection }
TerminalEmulatorMorph >> highlightSelection [
	"The selection region has changed.  Update the visual representation."

	| region |
	region := self getSelectionRegion.
	lines do: [ :line | line clearSelection].
	region height == 0		"single line"
		ifTrue:
			[(lines at: region top) selectFrom: region left to: region right]
		ifFalse:
			[(lines at: region top) selectFrom: region left to: cols.
			 lines from: region top + 1 to: region bottom - 1 do: [:line | line selectFrom: 1 to: cols].
			 (lines at: region bottom) selectFrom: 1 to: region right].
	selectionActive := true.
	self changed
]

{ #category : #geometry }
TerminalEmulatorMorph >> initScrollbar: frame [
	"Initialize the scrollbar to fit in/around the given frame."

	| width origin |
	width := self scrollbarWidth .
	origin := (frame right - width) @ frame top.
	scroll bounds: (origin extent: width @ (frame height))
]

{ #category : #geometry }
TerminalEmulatorMorph >> initTextBounds: textBounds width: nCols height: nRows [
	"This is a geometry change imposed from outside (either initial placement or manual resizing).  We honour it without attempting to fix the geometry of our owner."

	| r morphs morph |
	(nCols == cols and: [nRows == rows]) ifTrue: [^self].
	morphs := OrderedCollection withAll: submorphs.	"copy".
	self clearSelection; hideCursor; removeAllMorphs.
	cols := nCols max: 1.
	x := x min: cols.
	lines do: [ :line | line setWidth: cols].
	r := nRows max: 1.
	[rows < r]
		whileTrue:
			[displayStart > 0
				ifTrue:
					["suck last saved line back down into the screen"
					 displayStart := displayStart - 1.
					 savedLines := savedLines - 1.
					 morphs addFirst: (TerminalEmulatorLineMorph contents: (self displayLineAt: 1)).
					 y := y + 1]
				ifFalse:
					["add a new empty line at the bottom of the screen"
					 morph := TerminalEmulatorLineMorph contents: (lines addLast: (TerminalEmulatorTextState new: cols)).
					 morphs addLast: morph].
			 rows := rows + 1].
	[rows > r]
		whileTrue:
			[rows := rows - 1.
			 savedLines := savedLines + 1.
			 displayStart := displayStart + 1.
			 morphs removeLast.
			 y := y - 1 max: 1].
	self
		addAllMorphs: morphs;
		showCursor;
		doSoftReset;
		initializeTabs;
		reportSizeToSession;
		linesChanged.
	"morphic explodes if we continue before making absolutely sure the window is redrawn..."
	"(running and: [self world notNil]) ifTrue: [self world doOneCycle]"
]

{ #category : #geometry }
TerminalEmulatorMorph >> initialExtent [

	self flag: #ikp. "can this can go away?"
	^self preferredExtent
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initialize [

	^self initialize: 80@24
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initialize: size [

	super initialize.
	self borderWidth: 2.
	color := Color white.
	inset := 2.
	trackingSelection := false.
	self
		initializeTeletype: size;
		initializeContent;
		showScrollbar;
		extent: self preferredExtent
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initializeContent [

	| morphs |
	morphs := OrderedCollection new.
	rows timesRepeat: [morphs addLast: ((TerminalEmulatorLineMorph contents: (lines addLast: self newLine)) cursorColour: cursorColour)].
	self addAllMorphs: morphs.
	topLine := 1.
	bottomLine := rows.
	x := y := 1.
	self banner do: [:c | self upcall: c asInteger]
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initializeTabs [

	tabs := Array new: cols withAll: false.
	1 to: cols by: 8 do: [:i | tabs at: i put: true]
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initializeTeletype: size [
	"Initialize the default behaviour: dumb terminal with local echo and default xterm VT options."

	font := LogicalFont familyName: 'DejaVu Sans Mono' fallbackFamilyNames: 'Source Code Pro' pointSize: 9.
	pitch := font widthOf: $W.
	skip := font height.
	cols := size x.
	rows := size y.
	lines := OrderedCollection new.
	savedLines := 0.
	savedLineLimit := SavedLineLimit.
	displayStart := 0.
	x := 1.
	y := 1.
	fg := 0.
	bg := 7.
	em := 0.
	rv := false.
	ec := false.
	session := nil.
	self initializeTabs.
	self initializeTerminalModes.	"Default low protocol: local echo"
	down := ProtocolAdaptor new localEcho up: self.
	showCursor := true.
	running := false.
	autoFlush := 0.
	steps := 0.
	altScreenActive := false.
	altScreenColours := false.
	hasFocus := true.
	selectionStart := selectionEnd := nil.
	selectionActive := false.
	selection := ''.
	mouseControlsSelection := MouseControlsSelection.
	keyboardControlsSelection := KeyboardControlsSelection.
	scrollOnInput := false.
	scrollOnOutput := true.
	allow132 := true.
	characterClasses := CharClass copy.
	cursorColour := nil.
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> initializeTerminalModes [
	"Initialize the default behaviour: dumb terminal with local echo and standard xterm VT option settings."

	autoWrap := true.
	reverseWrap := autoLinefeed := autoCR := relativeOrigin := insertMode := false.
	showCursor := false.
	smoothScroll := false.
	metaSendsEscape := true.
	deleteIsDel := false.
	altScreenSwitch := true.
	reverseVideo := false.
	"useScrollbar := true"
]

{ #category : #private }
TerminalEmulatorMorph >> insert [

	(self protectSelection; currentLine)
		at: x insert: $  fg: fg bg: bg em: em
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> insert: n [

	self hideCursor.
	n timesRepeat: [self insert].
	self showCursor
]

{ #category : #private }
TerminalEmulatorMorph >> insertLine [

	^self scrollBackwardFrom: y to: bottomLine
]

{ #category : #'editor functions' }
TerminalEmulatorMorph >> insertLines: n [

	self hideCursor.
	n timesRepeat: [self insertLine].
	self showCursor.
	self autoFlush
]

{ #category : #protocol }
TerminalEmulatorMorph >> install [

	session isNil ifFalse: [session propertyAt: #window put: self]
]

{ #category : #testing }
TerminalEmulatorMorph >> isCollapsed [

	^(systemWindow notNil) and: [systemWindow isCollapsed]
]

{ #category : #protocol }
TerminalEmulatorMorph >> isConnected [

	^session notNil and: [session isConnected]
]

{ #category : #events }
TerminalEmulatorMorph >> keyStroke: evt [
	"Receive a character from the keyboard."

	| char |
	scrollOnInput ifTrue: [self pageEnd].
	char := evt keyValue "keyCharacter asciiValue".
	evt controlKeyPressed
		ifFalse:
			[char == 1 ifTrue: [^self pageHome].
			 char == 4 ifTrue: [^self pageEnd].
			 char == 11 ifTrue: [^self pageUp: rows // 2].
			 char == 12 ifTrue: [^self pageDown: rows // 2]].
	(keyboardControlsSelection and: [evt commandKeyPressed])
		ifTrue:
			[evt keyCharacter == $c ifTrue: [^self copySelection].
			 evt keyCharacter == $v ifTrue: [^self sendSelection]].
	(metaSendsEscape and: [evt commandKeyPressed])
		ifTrue: [down downcall: Character escape asciiValue].
	"Cursor keys clash with control keys: differentiate by sending 128+cursorKeyCode."
	(char == 8 & deleteIsDel and: [evt controlKeyPressed not]) ifTrue: [char := 127].
	(char < 32 and: [evt controlKeyPressed not]) ifTrue: [char := char + 128].
	down downcall: char.
	evt wasHandled: true.
]

{ #category : #events }
TerminalEmulatorMorph >> keyboardFocusChange: aBoolean [

	hasFocus := aBoolean
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> lf [

	autoCR
		ifTrue: [self newline]
		ifFalse: [self cursorDown: 1 scrolling: true]
]

{ #category : #private }
TerminalEmulatorMorph >> lineAt: index [

	^lines at: savedLines + index
]

{ #category : #private }
TerminalEmulatorMorph >> linesChanged [

	| lineNo line |
	lineNo := displayStart.
	1 to: rows do: [ :i |
		line := lines at: (lineNo := lineNo + 1).
		line setWidth: cols.
		(submorphs at: i) lineState: line].
	1 to: rows do: [ :i | (submorphs at: i) rv: rv; cursorColour: cursorColour; ec: ec & altScreenColours].
	self autoFlush
]

{ #category : #private }
TerminalEmulatorMorph >> linesDo: aBlock [

	self linesFrom: 1 to: rows do: aBlock
]

{ #category : #private }
TerminalEmulatorMorph >> linesFrom: start to: stop do: aBlock [

	| first |
	first := lines size - rows.
	lines from: first + start to: first + stop do: aBlock
]

{ #category : #events }
TerminalEmulatorMorph >> lock [
	"We're losing keyboard focus."

	super lock.
	hasFocus := false.
	self changed.
]

{ #category : #menus }
TerminalEmulatorMorph >> menuBlock: aBlock [

	aBlock value.
	self flush
]

{ #category : #accessing }
TerminalEmulatorMorph >> metaSendsEscape [

	^metaSendsEscape
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> metaSendsEscape: aBoolean [

	metaSendsEscape := aBoolean
]

{ #category : #events }
TerminalEmulatorMorph >> mouseDown: evt [
	"A mouse button has been pressed."

"	evt printString displayAt: 10@200.
"
	evt hand newKeyboardFocus: self.

	"Yellow button is menu (or selection send when in xterm mode)."
	(evt yellowButtonChanged)
		ifTrue:
			[(mouseControlsSelection and: [evt anyModifierKeyPressed not])
				ifTrue: [self sendSelection]
				ifFalse: [(systemWindow isKindOf: TerminalEmulator)
					ifTrue: [systemWindow offerWindowMenu]
					ifFalse: []].
			 ^super mouseDown: evt].

	"Red button is selection start (or selection extend when shifted in Squeak mode)."
	(evt redButtonChanged)
		ifTrue:
			[evt shiftPressed
				ifTrue: ["mouseControlsSelection not and:" self extendSelection: evt position]
				ifFalse: [self startSelection: evt position].
			 ^super mouseDown: evt].

	"Blue button is selection extend when in xterm mode."
	(mouseControlsSelection and: [evt blueButtonChanged])
		ifTrue:
			[self extendSelection: evt position.
			 ^super mouseDown: evt].

	super mouseDown: evt.
]

{ #category : #events }
TerminalEmulatorMorph >> mouseEnter: evt [
	"The pointer just entered the window."

	TextCursor beCursor.
	self showScrollbar.
	super mouseEnter: evt
]

{ #category : #events }
TerminalEmulatorMorph >> mouseLeave: evt [
	"The cursor just left the window."

	Cursor normal show.
	self hideScrollbar.
	super mouseLeave: evt
]

{ #category : #events }
TerminalEmulatorMorph >> mouseMove: evt [
	"The mouse is moving inside the window."

"	evt printString displayAt: 10@220.
"
	evt redButtonPressed ifTrue: [self trackSelection: evt position].
	super mouseMove: evt
]

{ #category : #events }
TerminalEmulatorMorph >> mouseUp: evt [
	"A mouse button has been released."

"	evt printString displayAt: 10@240.
"
	evt redButtonChanged ifTrue: [self endSelection: evt position].
	evt wasHandled: true
]

{ #category : #private }
TerminalEmulatorMorph >> newLine [

	| line |
	line := (TerminalEmulatorTextState string: (String new: cols withAll: $ )) .
	ec & altScreenColours ifTrue: [line emacsColours].
	^line
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> newline [

	self hideCursor; cursorDown: 1 scrolling: true.
	x := 1.
	self showCursor
]

{ #category : #protocol }
TerminalEmulatorMorph >> note: aSymbol with: anObject [
	aSymbol == #endpointClosed
		ifTrue:
			[^(systemWindow isKindOf: TerminalEmulator)
				ifTrue: [systemWindow endpointClosed]].
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> openInWorld [

	self currentHand newKeyboardFocus: nil.
	super openInWorld.

]

{ #category : #scrolling }
TerminalEmulatorMorph >> pageDown: nLines [

	displayStart := displayStart + nLines min: lines size - rows.
	self linesChanged; changed.
]

{ #category : #scrolling }
TerminalEmulatorMorph >> pageEnd [

	 lines size - rows == displayStart
		ifFalse:
		[displayStart := lines size - rows.
		 self linesChanged; changed]
]

{ #category : #scrolling }
TerminalEmulatorMorph >> pageHome [

	displayStart := 0.
	self linesChanged; changed.
]

{ #category : #scrolling }
TerminalEmulatorMorph >> pageUp: nLines [

	displayStart := displayStart - nLines max: 0.
	self linesChanged; changed.
]

{ #category : #accessing }
TerminalEmulatorMorph >> pitch [

	^pitch
]

{ #category : #geometry }
TerminalEmulatorMorph >> preferredExtent [
	"Answer the extent that we would be given in an ideal world (no pun intended).  This is just the amout of space we need to display our contents, and no more."

	| w h s |
	s := self scrollbarWidth .
	w := self borderWidth + s + inset + (cols * pitch) + inset + self borderWidth.
	h := self borderWidth + inset + (rows * skip) + inset + self borderWidth.
	^w@h
]

{ #category : #private }
TerminalEmulatorMorph >> protectSelection [
	"If the active position is within the selected region, clear the selection."

	self flag: #ikp. "This is called way too often.  Need to go look where and when it's really necessary."
"
	'protect selection ', (TEMP := TEMP + 1) printString, '  ' displayAt: 10@170.
"
	selectionActive ifTrue: [(self currentLine selectionSpansColumn: x) ifTrue: [self clearSelection]]
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> put: aChar [

	scrollOnOutput ifTrue: [self pageEnd].
	(insertMode and: [x < cols]) ifTrue: [(self protectSelection; currentLine) insertAt: x].
	(aChar == 13 & autoLinefeed or: [aChar == 10 & autoCR])
		ifTrue: [self newline]
		ifFalse: [self putNormal: aChar; cursorRight: 1 wrapping: true]
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> putNormal: aChar [

	x >= cols ifTrue: [self wrapIfPossible].
	selectionActive ifTrue: [self protectSelection].
	self currentLine at: x put: (Character value: aChar) fg: fg bg: bg em: em
]

{ #category : #private }
TerminalEmulatorMorph >> reportSizeToSession [

	session isNil ifFalse: [session note: #windowSize with: cols@rows]
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> resetVideo [

	self
		clearSelection;
		setBackground: 7;
		setForeground: 0;
		setEmphasis: 0
]

{ #category : #accessing }
TerminalEmulatorMorph >> rows [

	^rows
]

{ #category : #protocol }
TerminalEmulatorMorph >> run [

	running := true.
	session isNil ifFalse: [session note: #windowSize with: cols@rows]
]

{ #category : #accessing }
TerminalEmulatorMorph >> rv: aBoolean [
	"Set the programmed reverse video flag.  Not to be confused with reverseVideo, which is a user preference that inverts the sense of the programmed change."

	rv == aBoolean ifTrue: [^self].
	rv := aBoolean..
	submorphs from: 1 to: rows do: [ :m | m rv: (rv xor: reverseVideo)].
	self changed
]

{ #category : #selection }
TerminalEmulatorMorph >> saveSelection [
	"A new selection has been made.  Compute and remember the selection text."

	| stream region |
	region := self getSelectionRegion.
	stream := WriteStream on: String new.
	lines from: region top to: region bottom do: [:line | line appendSelectionTo: stream].
	selection := stream contents.
	mouseControlsSelection ifTrue: [Clipboard clipboardText: selection].
]

{ #category : #private }
TerminalEmulatorMorph >> scrollBackward [

	^self scrollBackwardFrom: topLine to: bottomLine
]

{ #category : #private }
TerminalEmulatorMorph >> scrollBackwardFrom: top to: bot [

	self hideCursor.
	savedLines + bot to: savedLines + top + 1 by: -1 do: [ :i | lines at: i put: (lines at: i - 1)].
	lines at: savedLines + top put: (TerminalEmulatorTextState new: cols).
	self showCursor.
	self linesChanged
]

{ #category : #private }
TerminalEmulatorMorph >> scrollForward [

	^self scrollForwardFrom: topLine to: bottomLine
]

{ #category : #private }
TerminalEmulatorMorph >> scrollForwardFrom: top to: bot [

	self hideCursor.
	(top == 1 and: [bot == rows and: [altScreenActive not]])
		ifTrue:
			[lines addLast: (TerminalEmulatorTextState new: cols).
			 lines size > (savedLineLimit + rows)
				ifTrue: [lines removeFirst selection notNil ifTrue: [self clearSelection]]
				ifFalse:
					[savedLines := savedLines + 1.
					 displayStart := displayStart + 1]]
		ifFalse:
			[savedLines + top to: savedLines + bot - 1 do: [ :i | lines at: i put: (lines at: i + 1)].
			 lines at: savedLines + bot put: (TerminalEmulatorTextState new: cols)].
	self showCursor.
	self linesChanged; autoFlush
]

{ #category : #scrolling }
TerminalEmulatorMorph >> scrollbarMenuButtonPressed: evt [

	(systemWindow isKindOf: TerminalEmulator)
		ifTrue: [systemWindow offerWindowMenu]
		ifFalse: []
]

{ #category : #scrolling }
TerminalEmulatorMorph >> scrollbarValue: value [
	| newStart |
	newStart := (savedLines * value) rounded min: lines size - rows.
	newStart == displayStart ifTrue: [^self].
	displayStart := newStart.
	self linesChanged; changed
]

{ #category : #geometry }
TerminalEmulatorMorph >> scrollbarWidth [
	^12
]

{ #category : #selection }
TerminalEmulatorMorph >> selectLine: screenPosition [
	"Triple click.  Select the line surrounding the cursor, including the end of line, and save the selection text."

	| pos |
"
	'select line   ' displayAt: 10@130.
"
	pos := self selectionPositionAt: screenPosition.
	selectionStart := 1 @ pos y.
	selectionEnd := cols + 1 @ pos y.
	self highlightSelection; saveSelection.
	selectionEnd := nil.
	mousePosition := nil.
]

{ #category : #selection }
TerminalEmulatorMorph >> selectWord: screenPosition [
	"Double click.  Select the word surrounding the cursor according to the current char class and save the selection text."

	| pos line left right |
"
	'select word   ' displayAt: 10@130.
"
	pos := self selectionPositionAt: screenPosition.
	line := lines at: pos y.
	left := line findFirstInClass: self characterClass from: (pos x min: cols).
	right := line findLastInClass: self characterClass from: (pos x min: cols).
	selectionStart := left @ pos y.
	selectionEnd := right + 1 @ pos y.
	right < left
		ifTrue: [self clearSelection]
		ifFalse: [self highlightSelection; saveSelection]
]

{ #category : #selection }
TerminalEmulatorMorph >> selectionPositionAt: screenPosition [
	"Answer a Point in character coordinates corresponding to the given position in screen coordinates.  If screenPosition is above the window, try to scroll up before answering the first character in the window.  If screenPosition is below the window, try to scroll down before answering one character right of the last character in the window."

	| pos |
	screenPosition y < (self submorphs at: 1) bounds top
		ifTrue:
			[self pageUp: (rows // 8 max: 1).
			 ^1 @ (displayStart + 1)].
	screenPosition y > (self submorphs at: rows) bounds bottom
		ifTrue:
			[self pageDown: (rows // 8 max: 1).
			 ^(cols + 1) @ (displayStart + rows)].
	1 to: rows do: [:i
		| (pos := (self submorphs at: i) selectionColumnAt: screenPosition) isNil
			ifFalse: [^pos @ (displayStart + i)]].
	^nil
]

{ #category : #selection }
TerminalEmulatorMorph >> sendSelection [
	"Send the clipboard text to the application."

	down downcallAll: Clipboard clipboardText asString asByteArray
]

{ #category : #protocol }
TerminalEmulatorMorph >> session [

	^session
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> session: aSession [

	session := aSession
]

{ #category : #protocol }
TerminalEmulatorMorph >> sessionNote: aSymbol [

	self sessionNote: aSymbol with: nil
]

{ #category : #protocol }
TerminalEmulatorMorph >> sessionNote: aSymbol with: anObject [

	session isNil ifFalse: [session note: aSymbol with: anObject]
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setAltScreenColours: aBoolean [

	altScreenColours := aBoolean.
	self setEmacsColours: ec.
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setAutoLinefeed: aBoolean [

	autoLinefeed := aBoolean
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setAutoWrap: aBoolean [

	autoWrap := aBoolean
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> setBackground: index [

	bg := index min: 7 max: 0.
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setEmacsColours: aBoolean [

	(ec := aBoolean) & altScreenColours
		ifTrue: [submorphs from: 1 to: rows do: [:line | line emacsColours]]
		ifFalse: [submorphs from: 1 to: rows do: [:line | line normalColours]].
	self changed
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> setEmphasis: index [

	index == 0 ifTrue: [^em := 0].
	em := em bitOr: (1 bitShift: index - 1).
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> setEmphasis: index to: bit [

	bit == 0
		ifTrue: [em := em bitClear: (1 bitShift: index - 1)]
		ifFalse: [em := em bitOr: (1 bitShift: index - 1)]
]

{ #category : #'character writing' }
TerminalEmulatorMorph >> setForeground: index [

	fg := index min: 7 max: 0
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setIconTitle: aString [

	systemWindow notNil
		ifTrue:
			[(systemWindow isKindOf: TerminalEmulator)
				ifTrue: [systemWindow setIconTitle: aString]]
				"icon title ignored by other kinds of window"
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setInsertMode: aBoolean [

	insertMode := aBoolean
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setRelativeOrigin: aBoolean [

	relativeOrigin := aBoolean.
	self activePosition: 1@1
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setReverseVideo: aBoolean [

	reverseVideo == aBoolean ifTrue: [^self].
	reverseVideo := aBoolean.
	submorphs from: 1 to: rows do: [ :m | m rv: (rv xor: reverseVideo)].
	self changed
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setScrollRegionTop: top bottom: bottom [

	topLine := top min: rows - 1 max: 1.
	bottomLine := bottom min: rows max: top + 1
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setShowCursor: aBoolean [

	self hideCursor.
	showCursor := aBoolean.
	self showCursor
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setSmoothScroll: aBoolean [

	autoFlush := 0.
	smoothScroll := aBoolean
]

{ #category : #tabs }
TerminalEmulatorMorph >> setTab [

	x <= cols ifTrue: [tabs at: x put: true].
"
	Transcript
		nextPutAll: 'tab SET ', x printString; tab;
		nextPutAll: (String withAll: (tabs collect: [:t | t ifTrue: [$!] ifFalse: [$.]]));
		cr; endEntry
"
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setWidth: nCols [

	allow132 ifTrue: [self setWidth: nCols height: rows]
]

{ #category : #geometry }
TerminalEmulatorMorph >> setWidth: nCols height: nRows [
	"This is a programmed geometry change.  We try to honour it by figuring out the corresponding geometry change required in our owner in order to acheive the given number of cols and rows.  The actual change takes place on the flip side, when our owner sends down our new extent."

	| flak |
	(cols == nCols and: [rows == nRows]) ifTrue: [^self].
	flak := systemWindow isNil ifTrue: [0] ifFalse: [systemWindow fullBounds extent - self textBounds extent].
	"self changed; sync."
	(systemWindow isNil ifTrue: [self] ifFalse: [systemWindow])
		extent: (pitch * nCols) @ (skip * nRows) + flak.
	"self sync."
]

{ #category : #'initialize-release' }
TerminalEmulatorMorph >> setWindow: aWindow [

	systemWindow := aWindow
]

{ #category : #'operating modes' }
TerminalEmulatorMorph >> setWindowTitle: aString [

	systemWindow notNil
		ifTrue:
			[(systemWindow isKindOf: TerminalEmulator)
				ifTrue: [systemWindow setWindowTitle: aString]
				ifFalse: [systemWindow setLabel: aString]]
]

{ #category : #'cursor control' }
TerminalEmulatorMorph >> showCursor [

	self currentLine cursorCol: x.
	self changed.
]

{ #category : #geometry }
TerminalEmulatorMorph >> showScrollbar [
	"Add a scrollbar to the window."

	scroll isNil
		ifTrue:
			[scroll := ScrollBar new model: self;
			setValueSelector: #scrollbarValue:.
			 self
				addMorphBack: scroll;
				initScrollbar: self layoutBounds;
				updateScrollbar]
]

{ #category : #accessing }
TerminalEmulatorMorph >> skip [

	^skip
]

{ #category : #selection }
TerminalEmulatorMorph >> startSelection: screenPosition [
	"Mouse selection has begun.  If this is a double click (mouse hasn't moved since last click and selectionEnd isNil) then select the word under the pointer.  If this is a triple click (mouse hasn't moved and selectionEnd notNil after prior word selection) then select the line under the pointer.  Otherwise clear the current selectionStart and begin tracking."

	| start |
	self hideCursor; changed.
	mousePosition = screenPosition
		ifTrue:
			[^selectionEnd isNil
				ifTrue: [self selectWord: screenPosition]
				ifFalse: [self selectLine: screenPosition]].
"
	'mouse position ' , mousePosition printString,
	' screen position ', screenPosition printString, 
	' selectionEnd ', selectionEnd printString, 
	'  ' displayAt: 10@150.
"
	mousePosition := screenPosition.
	selectionEnd := nil.

	start := self selectionPositionAt: screenPosition.
	self clearSelection.
	selectionStart := start.
"
	'selection begin ', selectionStart printString, '     ' displayAt: 10@10
"
]

{ #category : #private }
TerminalEmulatorMorph >> step [

	steps := steps + 1
]

{ #category : #private }
TerminalEmulatorMorph >> sync [
	"Wait until the world has revolved at least once before proceeding."

	| s |
	s := steps + 1.
	[steps < s] whileTrue: [^Processor yield]
]

{ #category : #tabs }
TerminalEmulatorMorph >> tab [

	self hideCursor.
	[x := x + 1.
	 x < cols and: [(tabs at: x) not]]
		whileTrue.
	x := x min: cols.
	self showCursor
]

{ #category : #geometry }
TerminalEmulatorMorph >> textBounds [
	"Answer just the bounds of the text -- excluding border, scroll and inset."

	^self textBounds: self layoutBounds
]

{ #category : #geometry }
TerminalEmulatorMorph >> textBounds: outer [
	"Answer just the bounds of the text -- excluding border, scroll and inset."

	|  left right inner |
	left := right := 0.
	right := self scrollbarWidth / 2.
	inner := outer insetBy: inset.
	^(inner left + left) @ (inner top) corner: (inner right - right) @ (inner bottom)
]

{ #category : #selection }
TerminalEmulatorMorph >> trackSelection [
	"The mouse is down during selection tracking.  Update the visual representation of the selected region."

	| pos |
	(pos := self selectionPositionAt: Sensor cursorPoint) isNil
		ifFalse:
			[selectionEnd := pos.
			 self highlightSelection]
]

{ #category : #selection }
TerminalEmulatorMorph >> trackSelection: screenPosition [
	"The mouse moved during selection tracking.  Update the visual representation of the selected region."

	(trackingSelection or: [(self selectionPositionAt: screenPosition) isNil])
		ifFalse: [self
				startStepping: #trackSelection
				at: Time millisecondClockValue
				arguments: #()
				stepTime: 100]
]

{ #category : #events }
TerminalEmulatorMorph >> unlock [
	"We're acquiring keyboard focus."

	super unlock.
	hasFocus := true.
	self changed.
]

{ #category : #protocol }
TerminalEmulatorMorph >> upcall: char [
"
	Transcript show: 'upcall ', char printString; cr.
""	char printString , '   ' displayAt: 10@10.
"
	self put: char.
	self invalidRect: self fullBounds.
]

{ #category : #protocol }
TerminalEmulatorMorph >> upcallAll: aCollection [

	aCollection do: [:b | self upcall: b]
]

{ #category : #scrolling }
TerminalEmulatorMorph >> updateScrollbar [

	scroll isNil ifTrue: [^self].
	savedLines == 0 ifTrue: [^scroll interval: 1.0; setValue: 0].
	scroll
		scrollDelta: (1 / savedLines) asFloat
		pageDelta: (rows / savedLines) asFloat;
		interval: (rows / lines size) asFloat;
		setValue: (displayStart / savedLines) asFloat
]

{ #category : #events }
TerminalEmulatorMorph >> wouldAcceptKeyboardFocus [
	"Of course we would."

	^true
]

{ #category : #private }
TerminalEmulatorMorph >> wrapIfPossible [

	x > cols ifTrue: [autoWrap
		ifTrue: [x := 1.  self cursorDown: 1 scrolling: true]
		ifFalse: [x := cols]]
]
