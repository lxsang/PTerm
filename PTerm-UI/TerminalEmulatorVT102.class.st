"
I emulate a VT102 terminal.  The VT102 is an enhanced VT100 with additional screen editing functions, especially useful for full-screen editors (like Emacs) running over slow connections.

I expect to be inserted somewhere in the middle of a protocol stack.  My low procotol (usually some kind of remote login protocol) sends me #upcall: aCharacter to display aCharacter.  I filter out control sequences (sending appropriate messages to my window (usually a TerminalEmulatorMorph) to effect cursor movement, character attribute manipulation, screen editing and so on) or simply pass printing characters up to my high protocol (usually the same TerminalEmulatorMorph as my window) verbatim for display.  I accept keyboard input from my high protocol (again usually my window) which I pass down to my low protocol with conversion from Squeak keycodes to ANSI or DEC escape sequences representing cursor and other special keys.

I'm a subclass of Protocol, which is a subclass of StateMachine, since terminal emulation is simply a matter of recognising particular patterns (`escape sequences') in a stream of characters (as is any kind of `protocol').

I recognise the escape sequences as defined in: ""VT102 Video Terminal User Guide"", 3rd edition, Digital Equipment Corporation, February 1982, part number EK-VT102-UG-003.  When in VT52 mode I also recognise the escape sequences defined in ""DECscope User's Manual"", 1st edition, Digital Equipment Corporation, April 1976, part number EK-VT5X-OP-001.  (If you don't own copies of these historic documents then Shame On You! ;-)
"
Class {
	#name : #TerminalEmulatorVT102,
	#superclass : #StatefulProtocol,
	#instVars : [
		'arguments',
		'window',
		'trace',
		'mode',
		'keypadMode',
		'cursorState',
		'charMap',
		'g0Map',
		'g1Map',
		'keyMap'
	],
	#classVars : [
		'CharsGR',
		'CharsUK',
		'CharsUS'
	],
	#classInstVars : [
		'States'
	],
	#category : #'PTerm-UI'
}

{ #category : #'class initialization' }
TerminalEmulatorVT102 class >> initialize [
	"TerminalEmulatorVT102 initialize"

	"protocol"
	States := self protocol compile.

	"character sets"
	CharsUK := Array new: 256.
	CharsUS := Array new: 256.
	CharsGR := Array new: 256.
	1 to: 256 do: [:i | CharsUK at: i put: (CharsUS at: i put: (CharsGR at: i put: i - 1))].
	1 to: 32 do: [:i | CharsGR at: i + 95 put: (CharsGR at: i)].
	CharsUK at: ($# asInteger + 1) put: (CharsGR at: 31)
]

{ #category : #'instance creation' }
TerminalEmulatorVT102 class >> new [
	"VT100Emulator new"

	^super new initialize initialState: States
]

{ #category : #'class initialization' }
TerminalEmulatorVT102 class >> protocol [

	| desc |
	desc := StatefulProtocolDescription initialState: #relax.

	"Default: pass everything up except DEL, ESC and ASCII control chars (see end)"
	(desc newState: #relax	-> (#passUp:		-> nil))
		add: 8r033			-> (nil			-> #esc);	"ANSI or CSI"
		add: 8r177			-> (nil			-> nil).		"ignored on input"

	"ESC -- either ANSI control sequence, DEC private or first char of CSI"
	(desc newState: #esc		-> (#esc: 				-> #relax))
		addInteger: $#		-> (nil					-> #decla);	"line attributes"
		addInteger: $<		-> (#ansi52:				-> #relax);	"ansi mode"
		addInteger: $>		-> (#decpnm:			-> #relax);	"normal keypad mode"
		addInteger: $=		-> (#decpam:			-> #relax);	"application keypad mode"
		addInteger: $(		-> (nil					-> #scs0);	"select G0 character set"
		addInteger: $)		-> (nil					-> #scs1);	"select G1 character set"
		addInteger: $7		-> (#decsc:				-> #relax);	"save cursor"
		addInteger: $8		-> (#decrc:				-> #relax);	"restore cursor"
		addInteger: $A		-> (#cuu52:				-> #relax);	"VT52: cursor up"
		addInteger: $B		-> (#cud52:				-> #relax);	"VT52: cursor down"
		addInteger: $C		-> (#cur52:				-> #relax);	"VT52: cursor right"
		addInteger: $D		-> (#ind:				-> #relax);	"index (VT52: cursor left)"
		addInteger: $E		-> (#nel:				-> #relax);	"next line"
		addInteger: $F		-> (#egm52:				-> #relax);	"VT52: enter graphics mode"
		addInteger: $G		-> (#lgm52:				-> #relax);	"VT52: leave graphics mode"
		addInteger: $H		-> (#hts:				-> #relax);	"horizontal tab set (VT52: home)"
		addInteger: $I		-> (#rlf52:				-> #relax);	"VT52: reverse line feed"
		addInteger: $J		-> (#ed52:				-> #relax);	"VT52: erase to EOD"
		addInteger: $K		-> (#el52:				-> #relax);	"VT52: erase to EOL"
		addInteger: $M		-> (#ri:					-> #relax);	"reverse index"
		addInteger: $Y		-> (nil					-> #dca1);	"VT52: direct cursor address"
		addInteger: $Z		-> (#decid:				-> #relax);	"what are you?"
		addInteger: $[		-> (#clearArguments:	-> #csi).		"begin CS"

	"ESC # -- dec line attributes"
	(desc newState: #decla	-> (#decla:			-> #relax)).	"line attributes"
	"ESC ( -- SCS for G0 and G1"
	(desc newState: #scs0	-> (#scs0:			-> #relax)).	"select character set for G0"
	(desc newState: #scs1	-> (#scs1:			-> #relax)).	"select character set for G1"
	"ESC Y -- VT52 cursor addressing"
	(desc newState: #dca1	-> (#oneArgument:	-> #dca2)).	"direct cursor address (line)"
	(desc newState: #dca2	-> (#dca52:			-> #relax)).	"direct cursor address (col)"

	"ESC [ -- CSI"
	(desc newState: #csi				-> (#csi:				-> #relax))
		addAllInteger: '0123456789'	-> (#addArgument:	-> nil);
		addInteger: $;				-> (#newArgument:	-> nil);
		addInteger: $?				-> (nil				-> #dec);	"dec private mode"
		addInteger: $=				-> (nil				-> #relax);	"alternate keypad mode"
		addInteger: $A				-> (#cuu:			-> #relax);	"cursor up"
		addInteger: $B				-> (#cud:			-> #relax);	"cursor down"
		addInteger: $C				-> (#cuf:			-> #relax);	"cursor forward"
		addInteger: $D				-> (#cub:			-> #relax);	"cursor backward"
		addInteger: $H				-> (#cup:			-> #relax);	"cursor position"
		addInteger: $J				-> (#ed:				-> #relax);	"erase in display"
		addInteger: $K				-> (#el:				-> #relax);	"erase in line"
		addInteger: $L				-> (#il:				-> #relax);	"insert lines"
		addInteger: $M				-> (#dl:				-> #relax);	"delete lines"
		addInteger: $P				-> (#dch:			-> #relax);	"delete character"
		addInteger: $f				-> (#hvp:			-> #relax);	"horiz and vert pos"
		addInteger: $g				-> (#tbc:			-> #relax);	"tab clear"
		addInteger: $h				-> (#sm:				-> #relax);	"set mode"
		addInteger: $l				-> (#rm:				-> #relax);	"reset mode"
		addInteger: $m				-> (#sgr:			-> #relax);	"select graphic rendition"
		addInteger: $r				-> (#stbm:			-> #relax).	"set top/bottom"

	"CSI ? -- DEC private mode change"
	(desc newState: #dec				-> (#dec: 			-> #relax))
		addAllInteger: '0123456789'	-> (#addArgument:	-> nil);
		addInteger: $;				-> (#newArgument:	-> nil);
		addInteger: $h				-> (#decsm:			-> #relax);	"set mode"
		addInteger: $l				-> (#decrm:			-> #relax).	"reset mode"

	"ASCII control characters are interpreted immediately during ESC, CSI and DEC"
	#(esc csi dec relax) do: [:mode | (desc at: mode)
		add: 8r000	-> (nil		-> nil);	"NUL: ignored on input"
		add: 8r007	-> (#bel:	-> nil);	"Note: this is an OSC delimiter in XTerm"
		add: 8r010	-> (#bs:		-> nil);
		add: 8r011	-> (#ht:		-> nil);
		add: 8r012	-> (#lf:		-> nil);
		add: 8r013	-> (#lf:		-> nil);	"VT interpreted as LF"
		add: 8r014	-> (#lf:		-> nil);	"FF interpreted as LF"
		add: 8r015	-> (#cr:		-> nil);	"FF interpreted as LF"
		add: 8r016	-> (#so:		-> nil);	"shift out: select G0 charset"
		add: 8r017	-> (#si:		-> nil)].	"shift in: select G1 charset"

	"That's it folks.  (Simple when you look at it like this, no? ;-)"
	^desc
]

{ #category : #accessing }
TerminalEmulatorVT102 class >> terminalTypeName [

	^'vt102'
]

{ #category : #arguments }
TerminalEmulatorVT102 >> addArgument: arg [

	arguments
		at: arguments size
		put: (arguments last * 10 + (arg - $0 asInteger))
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> ansi52: arg [
	"enter ANSI mode"

	self trace: '(VT52) ANSI'.
	self setMode: #ansi
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> bel: arg [
	"ring keyboard bell"

	self traceControl: 'BEL'.
	"Smalltalk beep"
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> bs: arg [
	"backspace"

	self traceControl: 'BS'.
	mode == #vt52
		ifTrue: [window cursorLeft: 1 wrapping: false]
		ifFalse: [window bs]
]

{ #category : #arguments }
TerminalEmulatorVT102 >> clearArguments: arg [

	arguments := OrderedCollection with: 0
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> cr: arg [
	"carriage return"

	self traceControl: 'CR'.
	window cr
]

{ #category : #private }
TerminalEmulatorVT102 >> csi: arg [

	self debug: 'CSI' withAll: arguments withChar: arg
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> cub: arg [
	"CUrsor Back"

	| n |
	n := arguments last max: 1.
	self trace: 'CUB ' with: n.
	window cursorLeft: n wrapping: false.
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> cud52: arg [
	"VT52: CUrsor Down"

	mode == #ansi ifTrue: [^self debug: 'ESC B'].
	self trace: '(VT52) CUD'.
	window cursorDown: 1 scrolling: false
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> cud: arg [
	"CUrsor Down"

	| n |
	n := arguments last max: 1.
	self trace: 'CUD' with: n.
	window cursorDown: n scrolling: false
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> cuf: arg [
 
	| n |
	n := arguments last max: 1.
	self trace: 'CUF ' with: n.
	window cursorRight: n wrapping: false.
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> cul52: arg [
	"VT52: CUrsor Left"

	mode == #ansi ifTrue: [^self debug: 'ESC D'].
	self trace: '(VT52) CUL'.
	window cursorLeft: 1 wrapping: false
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> cup: arg [
	"CUrsor Position"
	"Note: this is identical to HVP"

	| x y |
	arguments size == 2
		ifTrue:
			[y := arguments first max: 1.
			 x := arguments last max: 1]
		ifFalse:
			[x := y := 1].
	self trace: 'CUP ' with: x with: y.
	window activePosition: x@y.
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> cur52: arg [
	"VT52: CUrsor Right"

	mode == #ansi ifTrue: [^self debug: 'ESC C'].
	self trace: '(VT52) CUR'.
	window cursorRight: 1 wrapping: false
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> cuu52: arg [
	"VT52: CUrsor Up"

	mode == #ansi ifTrue: [^self debug: 'ESC A'].
	self trace: '(VT52) CUU'.
	window cursorUp: 1 scrolling: false
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> cuu: arg [
	"CUrsor Up"

	| n |
	n := arguments last max: 1.
	self trace: 'CUU' with: n.
	window cursorUp: n scrolling: false
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> dca52: arg [
	"VT52: Direct Cursor Adress"
	"The manual probably says what to do with unhandled VT52 sequences
	 when in ANSI mode but I'm too lazy to wade through it today.  Just barf
	 it onto the Transcript for now."

	| line col |
	mode == #ansi ifTrue: [^self debug: 'ESC Y' withChar: arguments withChar: arg].
	line := arguments - 8r037.
	col := arg - 8r037.
	self trace: '(VT52) DCA' with: col@line.
	window activePosition: col@line
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> dch: arg [
	"Delete CHaracter"

	| n |
	n := (arguments at: 1 ifAbsent: [1]) max: 1.
	window deleteForward: n
	
]

{ #category : #private }
TerminalEmulatorVT102 >> debug: message [

	Transcript nextPutAll: '*** '; nextPutAll: message; cr; endEntry
]

{ #category : #private }
TerminalEmulatorVT102 >> debug: message with: arg [

	Transcript
		nextPutAll: '*** ';
		nextPutAll: message; space;
		print: arg; cr;
		endEntry
]

{ #category : #private }
TerminalEmulatorVT102 >> debug: message withAll: args withChar: char [

	Transcript
		nextPutAll: '*** ';
		nextPutAll: message; space.
	args do: [:a | Transcript print: a; space].
	Transcript
		print: char asCharacter; space;
		nextPut: $(; print: char; nextPut: $); cr;
		endEntry.
]

{ #category : #private }
TerminalEmulatorVT102 >> debug: message withChar: char [

	Transcript
		nextPutAll: '*** ';
		nextPutAll: message; space;
		print: char asCharacter; space;
		nextPut: $(; print: char; nextPut: $); cr;
		endEntry.
]

{ #category : #private }
TerminalEmulatorVT102 >> debug: message withChar: a withChar: b [

	Transcript
		nextPutAll: '*** ';
		nextPutAll: message; space;
		print: a asCharacter; space;
		print: b asCharacter; space;
		nextPut: $(; print: a; space; print: b; nextPut: $); cr;
		endEntry.
]

{ #category : #private }
TerminalEmulatorVT102 >> dec: arg [

	self debug: 'CSI ?' withAll: arguments withChar: arg
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decid: arg [
	"DEC IDentify terminal (what are you?)"
	"Note: the response is the same regardless of the operating mode: we send `ESC / Z'
	 which identifies us as a VT102."

	self trace: 'DECID -> ESC / Z'.
	down
		downcall: Character escape asInteger;
		downcall: $/ asInteger;
		downcall: $Z asInteger
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decla: arg [
	"DEC Line Attributes"

	arg == 16r33 ifTrue: [^self debug: 'DECDHL (hi)'].
	arg == 16r34 ifTrue: [^self debug: 'DECDHL (lo)'].
	arg == 16r35 ifTrue: [^self debug: 'DECSWL'].
	arg == 16r36 ifTrue: [^self debug: 'DECDWL'].
	arg == 16r38 ifTrue: [self trace: 'DECALN (alignment test)'. ^window fillScreen: $E].
	self debug: 'ESC #' withChar: arg.
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decpam: arg [
	"DEC keyPad Application Mode"

	self trace: 'DECPNM'.
	self flag: #ikp.	"ignored for now -- since I don't have a keypad. ;-)"
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decpnm: arg [
	"DEC keyPad Normal Mode"

	self trace: 'DECPNM'.
	self flag: #ikp.	"ignored for now -- since I don't have a keypad. ;-)"
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decrc: arg [
	"DEC private Restore Cursor"

	cursorState isNil ifFalse:
		[window
			activePosition:	(cursorState at: 1);
			graphicsState:	(cursorState at: 2).
		 charMap := cursorState at: 3]
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decrm: arg [
	"DEC private Reset Mode"

	arguments do: [:param | self decrmSingle: param]
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decrmSingle: param [
	"DEC private Reset Mode"

	param == 1	ifTrue: [self trace:		'DECCKM		(cursor key mode: cursor)'.  ^self setCursorKeysNormal].
	param == 2	ifTrue: [self trace:		'DECANM	(ansi mode: VT52)'.  ^self setMode: #vt52].
	param == 3	ifTrue: [self trace:		'DECCOLM	(column mode: 80)'. ^window setWidth: 80].
	param == 4	ifTrue: [self trace:		'DECSCLM	(scroll mode: jump)'.  ^window setSmoothScroll: false].
	param == 5	ifTrue: [self trace:		'DECSCNM	(screen mode: normal)'.  ^window rv: false].
	param == 6	ifTrue: [self trace:		'DECOM		(origin mode: absolute)'. ^window setRelativeOrigin: false; activePosition: 1@1].
	param == 7	ifTrue: [self trace:		'DECAWM	(autowrap mode: off)'. ^window setAutoWrap: false].
	param == 8	ifTrue: [^self trace:		'DECARM	(autorepeat mode: off)'].
	param == 18	ifTrue: [^self trace:		'DECPFF		(print FF: off)'].
	param == 19	ifTrue: [^self trace:		'DECPEX		(print extent: region)'].
	"Emacs somtimes sends this.  Ho hum..."
	param == 25	ifTrue: [^window setShowCursor: false].

	self debug: 'DECRM' with: param.
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decsc: arg [
	"DEC private Save Cursor"

	(cursorState := Array new: 3)
		at: 1 put: window activePosition;
		at: 2 put: window graphicsState;
		at: 3 put: charMap
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decsm: arg [
	"DEC private Set Mode"

	arguments do: [:param | self decsmSingle: param]
]

{ #category : #'control sequences-DEC' }
TerminalEmulatorVT102 >> decsmSingle: param [
	"DEC private Set Mode"

	param == 1	ifTrue: [self trace:		'DECCKM		(cursor key mode: application)'. ^self setCursorKeysApplication].
	param == 2	ifTrue: [self trace:		'DECANM	(ansi mode: ANSI)'.  ^self setMode: #ansi].
	param == 3	ifTrue: [self trace:		'DECCOLM	(column mode: 132)'. ^window setWidth: 132].
	param == 4	ifTrue: [self trace:		'DECSCLM	(scroll mode: smooth)'.  ^window setSmoothScroll: true].
	param == 5	ifTrue: [self trace:		'DECSCNM	(screen mode: reverse)'.  ^window rv: true].
	param == 6	ifTrue: [self trace:		'DECOM		(origin mode: relative)'. ^window setRelativeOrigin: true; activePosition: 1@1].
	param == 7	ifTrue: [self trace:		'DECAWM	(autowrap mode: on)'. ^window setAutoWrap: true].
	param == 8	ifTrue: [^self trace:		'DECARM	(autorepeat mode: on)'].
	param == 18	ifTrue: [^self trace:		'DECPFF		(print FF: on)'].
	param == 19	ifTrue: [^self trace:		'DECPEX		(print extent: screen)'].
	"Emacs somtimes sends this.  Ho hum..."
	param == 25	ifTrue: [^window setShowCursor: true].

	self debug: 'DECSM' with: param.
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> dl: arg [
	"Delete Lines"

	| param |
	param := arguments last max: 1.
	self trace: 'DL' with: param.
	window deleteLines: param
]

{ #category : #protocol }
TerminalEmulatorVT102 >> downcall: arg [
	"Translate Squeak special keys into VT100 control sequences."

	(keyMap includesKey: arg)
		ifTrue: [down downcallAll: (keyMap at: arg)]
		ifFalse: [down downcall: (arg bitAnd: 127)]
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> ed52: arg [
	"VT52: Erase to end of Display"

	mode == #ansi ifTrue: [^self debug: 'ESC J'].
	self trace: '(VT52) ED'.
	window clearScreenRight
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> ed: arg [
	"Erase in Display"

	| param |
	param := arguments first.
	self trace: 'ED' with: param.
	param == 1 ifTrue: [^window clearScreenLeft].
	param == 2 ifTrue: [^window clearScreen].
	window clearScreenRight.
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> egm52: arg [
	"VT52: Enter Graphics Mode"

	mode == #ansi ifTrue: [^self debug: 'ESC F'].
	self trace: '(VT52) EGM'.
	charMap := CharsGR
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> el52: arg [
	"VT52: Erase to end of Line"

	mode == #ansi ifTrue: [^self debug: 'ESC K'].
	self trace: '(VT52) EL'.
	window clearLineRight
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> el: arg [
	"Erase in Line"

	| param |
	param := arguments last.
	self trace: 'EL' with: param.
	param == 1 ifTrue: [^window clearLineLeft].
	param == 2 ifTrue: [^window clearLine].
	window clearLineRight
]

{ #category : #private }
TerminalEmulatorVT102 >> esc: arg [

	self debug: 'ESC' withChar: arg
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> ht: arg [
	"horizontal tab"

	self traceControl: 'HT'.
	window tab
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> hts: arg [
	"VT52: cursor home
	 ANSI: Horizontal Tab Set"

	mode == #vt52
		ifTrue:
			[self trace: '(VT52) HOME'.
			 window activePosition: 1@1]
		ifFalse:
			[self trace: '(ANSI) HTS'.
			 window setTab]
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> hvp: arg [
	"Horizontal and Vertical Position"
	"Note: this is identical to CUP"

	| x y |
	arguments size == 2
		ifTrue:
			[y := arguments first max: 1.
			 x := arguments last max: 1]
		ifFalse:
			[x := y := 1].
	self trace: 'HVP ' with: x with: y.
	window activePosition: x@y.
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> il: arg [
	"Insert Lines"

	| param |
	param := arguments last max: 1.
	self trace: 'IL' with: param.
	window insertLines: param
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> ind: arg [
	"INDex"

	mode == #vt52 ifTrue: [^self cul52: arg].
	self trace: 'RI'.
	window cursorDown: 1 scrolling: true
]

{ #category : #'initialize-release' }
TerminalEmulatorVT102 >> initialState: aState [

	super initialState: aState.
	arguments := nil.
	trace := false.
	mode := #vt52.
	keypadMode := #normal.
	cursorState := nil.
	g0Map := g1Map := CharsUS.
	charMap := g0Map.
	keyMap := IdentityDictionary new.
	self setCursorKeysNormal
]

{ #category : #'initialize-release' }
TerminalEmulatorVT102 >> initialize [
]

{ #category : #protocol }
TerminalEmulatorVT102 >> install [

	super install.
	session propertyAt: #terminalType put: self terminalTypeString
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> lf: arg [
	"linefeed (also formfeed and vertical tab)"

	self traceControl: 'LF'.
	window lf
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> lgm52: arg [
	"VT52: Leave Graphics Mode"

	mode == #ansi ifTrue: [^self debug: 'ESC G'].
	self trace: '(VT52) LGM'.
	charMap := CharsUS
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> nel: arg [
	"NExt Line"

	self trace: 'NEL'.
	window newline
]

{ #category : #arguments }
TerminalEmulatorVT102 >> newArgument: arg [

	arguments addLast: 0
]

{ #category : #arguments }
TerminalEmulatorVT102 >> oneArgument: arg [

	arguments := arg
]

{ #category : #protocol }
TerminalEmulatorVT102 >> passUp: arg [

	super passUp: (charMap at: arg + 1 ifAbsent: [arg])
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> ri: arg [
	"Reverse Index"

	self trace: 'RI'.
	window cursorUp: 1 scrolling: true
]

{ #category : #'control sequences-VT52' }
TerminalEmulatorVT102 >> rlf52: arg [
	"VT52: Reverse Line Feed"

	mode == #ansi ifTrue: [^self debug: 'ESC I'].
	self trace: '(VT52) RLF'.
	window cursorUp: 1 scrolling: true
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> rm: arg [
	"Reset Mode"

	| param |
	param := arguments at: 1 ifAbsent: [0].
	param == 4	ifTrue: [self trace:	'IRM	(insert-replace mode: replace)'. ^window setInsertMode: false].

	self debug: 'RM' with: param.
]

{ #category : #protocol }
TerminalEmulatorVT102 >> run [

	super run.
	window := session
		propertyAt: #window
		ifAbsent: [^self error: 'Terminal emulators require a window in their protocol stack']
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> scs0: arg [
	"Select Character Set G0"

	| char |
	char := Character value: arg.
	char == $A	ifTrue: [self trace: 'select G0 UK'.  ^g0Map := CharsUK].
	char == $B	ifTrue: [self trace: 'select G0 US'.  ^g0Map := CharsUS].
	char == $0	ifTrue: [self trace: 'select G0 GR'.  ^g0Map := CharsGR].
	char == $1	ifTrue: [self trace: 'select G0 US'.  ^g0Map := CharsUS].
	char == $2	ifTrue: [self trace: 'select G0 US'.  ^g0Map := CharsUS].
	self debug: 'SCS G0' withChar: arg
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> scs1: arg [
	"Select Character Set G1"

	| char |
	char := Character value: arg.
	char == $A	ifTrue: [self trace: 'select G1 UK'.  ^g1Map := CharsUK].
	char == $B	ifTrue: [self trace: 'select G1 US'.  ^g1Map := CharsUS].
	char == $0	ifTrue: [self trace: 'select G1 GR'.  ^g1Map := CharsGR].
	char == $1	ifTrue: [self trace: 'select G1 US'.  ^g1Map := CharsUS].
	char == $2	ifTrue: [self trace: 'select G1 US'.  ^g1Map := CharsUS].
	self debug: 'SCS G1' withChar: arg
]

{ #category : #private }
TerminalEmulatorVT102 >> setCursorKeysApplication [

	| esc |
	esc := Character escape asString.
	keyMap
		at: 128+28 put: (esc,'OD') asByteArray;		"left"
		at: 128+29 put: (esc,'OC') asByteArray;		"right" 
		at: 128+30 put: (esc,'OA') asByteArray;		"up"
		at: 128+31 put: (esc,'OB') asByteArray.		"down" 
]

{ #category : #private }
TerminalEmulatorVT102 >> setCursorKeysNormal [

	| esc |
	esc := Character escape asString.
	keyMap
		at: 128+28 put: (esc,'[D') asByteArray;		"left"
		at: 128+29 put: (esc,'[C') asByteArray;		"right" 
		at: 128+30 put: (esc,'[A') asByteArray;		"up"
		at: 128+31 put: (esc,'[B') asByteArray.		"down" 
]

{ #category : #private }
TerminalEmulatorVT102 >> setMode: aSymbol [

	mode := aSymbol.
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> sgr: arg [
	"Select Graphics Rendition"

	arguments do: [:gr | self sgrSingle: gr]
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> sgrSingle: arg [

	self trace: 'SGR' with: arg.
	arg == 0 ifTrue: [^window resetVideo].
	arg == 1 ifTrue: [^window setEmphasis: 1].
	arg == 4 ifTrue: [^window setEmphasis: 4].
	arg == 5 ifTrue: [^window setEmphasis: 5].
	arg == 7 ifTrue: [^window setEmphasis: 7].		"this is the most common"
	"all others are ignored silently"
	self debug: 'SGR ', arg printString
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> si: arg [
	"Shift In: select G0 charset"

	charMap := g0Map
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> sm: arg [
	"Set Mode"

	| param |
	param := arguments at: 1 ifAbsent: [0].
	param == 4	ifTrue: [self trace:	'IRM	(insert-replace mode: insert)'. ^window setInsertMode: true].

	self debug: 'SM' with: param.
]

{ #category : #'control characters' }
TerminalEmulatorVT102 >> so: arg [
	"Shift In: select G1 charset"

	charMap := g1Map
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> stbm: arg [
	"Set Top and BottoM lines"

	| top bottom |
	top := 1.
	bottom := window rows.
	arguments size == 2
		ifTrue:
			[top := arguments first max: 1.
			 bottom := arguments last min: bottom].
	self trace: 'STBM' with: top with: bottom.
	top < bottom ifTrue: [window setScrollRegionTop: top bottom: bottom; activePosition: 1@1]
]

{ #category : #'control sequences' }
TerminalEmulatorVT102 >> tbc: arg [
	"TaB Clear"

	| n |
	n := arguments last.
	self trace: 'TBC' with: n.
	n == 0 ifTrue: [^window clearTab].
	n == 3 ifTrue: [^window clearTabs].
	self trace: 'TBC' with: n.
]

{ #category : #identification }
TerminalEmulatorVT102 >> terminalTypeString [
	"Viz: RFCs 930 (Telnet Terminal Type Option) and 1700 (Assigned Numbers)"

	^'VT102'
]

{ #category : #private }
TerminalEmulatorVT102 >> trace: message [

	trace ifTrue: [Transcript nextPutAll: message; cr; endEntry]
]

{ #category : #private }
TerminalEmulatorVT102 >> trace: message with: a [

	trace ifTrue: [Transcript nextPutAll: message; space; print: a; cr; endEntry]
]

{ #category : #private }
TerminalEmulatorVT102 >> trace: message with: a with: b [

	trace ifTrue: [Transcript nextPutAll: message; space; print: a; space; print: b; cr; endEntry]
]

{ #category : #private }
TerminalEmulatorVT102 >> traceControl: message [

	trace ifTrue: [Transcript nextPutAll: message; cr; endEntry]
]

{ #category : #'initialize-release' }
TerminalEmulatorVT102 >> window: aWindow [

	window := aWindow.
	window setAutoLinefeed: false
]
