"
I am a kind of SystemWindow intended specifically for hosting a TerminalEmulatorMorph.  I provide connection-oriented menus, persistent preferences and menu-based access to my TerminalEmulatorMorph options.


win := TerminalEmulator open.
(ProcessEndpoint command: '/bin/bash' arguments: {'-i'}) asProtocolStack
	push:        TerminalEmulatorXterm new;
	push:        win tty;
	install;
	run
"
Class {
	#name : #TerminalEmulator,
	#superclass : #SystemWindow,
	#instVars : [
		'tty',
		'windowTitle',
		'iconTitle',
		'workingDirectory'
	],
	#classVars : [
		'AutoClose',
		'SaveTelnetOptions',
		'SaveTerminalMainOptions',
		'SaveTerminalSize',
		'SaveTerminalVTOptions',
		'Shortcuts',
		'TerminalType'
	],
	#classInstVars : [
		'font',
		'palette'
	],
	#category : #'PTerm-UI'
}

{ #category : #'shortcut-handling' }
TerminalEmulator class >> buildTerminalShortcutsOn: aBuilder [ 
	<keymap>
	(aBuilder shortcut: #metaw)
		category: #TerminalEmulator
		default: PharoShortcuts current closeWindowShortcut 
		do: [ :target | target simulateShortcutAsKeyStroke: PharoShortcuts current closeWindowShortcut].
	(aBuilder shortcut: #metau)
		category: #TerminalEmulator
		default: $u meta 
		do: [ :target | target simulateShortcutAsKeyStroke: $u meta].
]

{ #category : #font }
TerminalEmulator class >> checkFont [
	|path|
	(self hasFont: self fontFamily) ifTrue:[^self fontFamily].
	path := self fontsDir.
	[
		self fontsURI do:[:a|
			(path / (a key)) exists ifFalse:[
				"Download the font"
				ZnClient new
					url: a value;
					downloadTo: path.
			]
		] displayingProgress: [ 'Checking and downloading font' ].
		FreeTypeFontProvider current prepareForUpdating.
		FreeTypeFontProvider current updateAvailableFontFamilies.
		FreeTypeFontProvider current updateFromSystem.
		FreeTypeFontProvider current updateAvailableFontFamilies.
		(self hasFont: self fontFamily) ifFalse:[^self selecFont].
		^self fontFamily
	] on: Error do: [^self selecFont]
]

{ #category : #'shortcut-handling' }
TerminalEmulator class >> cleanUpKeyMap [
	KMRepository default globalCategories do:[:m|
		"we remove the global Ctrl+u keymap of GTSpotter
		we dont really need it, but the terminal certainly will"
		m className asSymbol = #GTSpotterProfiler ifTrue:[
			KMRepository default globalCategories remove: m
		]
	].
]

{ #category : #'instance creation' }
TerminalEmulator class >> environ [
	|collection|
	collection := OrderedCollection new.
	Smalltalk os environment asDictionary keysAndValuesDo: [ :k :v|
		collection add: k,'=',v
	].
	collection add: 'LANG=en_US.UTF-8'.
	collection add: 'TERM=linux'.
	^collection 
]

{ #category : #accessing }
TerminalEmulator class >> font [
	font ifNil: [ font := LogicalFont familyName: 'DejaVu Sans Mono' pointSize: 10 ].
	^ font
]

{ #category : #accessing }
TerminalEmulator class >> font: anObject [
	font := anObject
]

{ #category : #font }
TerminalEmulator class >> fontFamily [
	^  self font familyName 
]

{ #category : #font }
TerminalEmulator class >> fontsDir [
	|path|
	path := FreeTypeFontProvider current imageRelativeFontFolder.
	path exists ifFalse:[ path createDirectory  ].
	^path
]

{ #category : #font }
TerminalEmulator class >> fontsURI [
^{
	'DejaVuSansMono-Bold.ttf' -> 'https://github.com/lxsang/PTerm/raw/master/fonts/DejaVuSansMono-Bold.ttf'.
	'DejaVuSansMono-BoldOblique.ttf' -> 'https://github.com/lxsang/PTerm/raw/master/fonts/DejaVuSansMono-BoldOblique.ttf'.
	'DejaVuSansMono-Oblique.ttf' -> 'https://github.com/lxsang/PTerm/raw/master/fonts/DejaVuSansMono-Oblique.ttf'.
	'DejaVuSansMono.ttf' -> 'https://github.com/lxsang/PTerm/raw/master/fonts/DejaVuSansMono.ttf'.
}
]

{ #category : #font }
TerminalEmulator class >> hasFont: fontName [
	^(FreeTypeFontProvider current families includesKey: fontName).
	"check if font file exists"
	
]

{ #category : #'world menu' }
TerminalEmulator class >> icon [
	^ self iconNamed: #morph
]

{ #category : #'class initialization' }
TerminalEmulator class >> initialize [
	"TeletypeWindow initialize"

	AutoClose := false.
	SaveTelnetOptions := false.
	SaveTerminalMainOptions := true.
	SaveTerminalSize := false.
	SaveTerminalVTOptions := true.
	TerminalType := TerminalEmulatorXterm.
	Shortcuts := Dictionary new.
	
]

{ #category : #'world menu' }
TerminalEmulator class >> menuCommandOn: aBuilder [ 
	"Add a custom menu item to the world menu"	
	<worldMenu> 
	
	(aBuilder item: #'Terminal')
		order: 4; 
		icon: self icon;  
		parent: #'SystemTools';
		keyText: 'o, c';
		help: 'Terminal';
		action: [ self openBash ].

]

{ #category : #'instance creation' }
TerminalEmulator class >> new [
	self announcer when: TerminalEmulatorConfigChange do: [:e|
		self allInstancesDo: [ :i |
			e data class = LogicalFont ifTrue:[i updateFont]
			ifFalse:[i updateTheme]
		]
	].
	^super new initialize
]

{ #category : #'instance creation' }
TerminalEmulator class >> open [

	^self new openOn: TerminalEmulatorMorph new
]

{ #category : #'instance creation' }
TerminalEmulator class >> open: path arguments: arguments [
	
	| win term |

	self checkFont.
	self cleanUpKeyMap.
	term := PTerm new xspawn: { path } , arguments env: self environ.
	win := self open.
	term asProtocolStack
		push: TerminalEmulatorXterm new;
		push: win tty;
		install;
		run.
	win extent: win extent.
	^ win	

]

{ #category : #'instance creation' }
TerminalEmulator class >> openBash [
	^self openShell: '/bin/bash'
	
]

{ #category : #'instance creation' }
TerminalEmulator class >> openShell: path [
	
	^ self open: path arguments: #('-i')

]

{ #category : #accessing }
TerminalEmulator class >> palette [
	palette ifNil: [ palette := PTermSolarizedTheme dark ].
	^ palette
]

{ #category : #accessing }
TerminalEmulator class >> palette: anObject [
	palette := anObject
]

{ #category : #font }
TerminalEmulator class >> selecFont [
	|fontSelector|
	self inform: 'Please select a (mono) font from system'.
	font ifNil: [ font := LogicalFont familyName: 'Source Code Pro' pointSize: 10 ].
	FreeTypeFontProvider current prepareForUpdating.
	FreeTypeFontProvider current updateAvailableFontFamilies.
	FreeTypeFontProvider current updateFromSystem.
	FreeTypeFontProvider current updateAvailableFontFamilies.
	[
		"The code inside this block provide support only for Pharo9.
		From Pharo10, FreeTypeFontSelectorDialogWindow no longer exist"
		fontSelector := FreeTypeFontSelectorDialogWindow new.
		fontSelector selectedFont: font.
		fontSelector openModal.
		fontSelector cancelled ifFalse:[
			self setFont: fontSelector selectedFont
		]
	] on:Error do:[
		"Use FontChooser for pharo10 and up.
		FontChooser exists on Pharo9, but the class interface is completely different
		from Pharo10. It is impossible to have a compatible use of this class for both
		Pharo9 and Pharo10"
		self selectFontUsingFontChooser
	].
	
]

{ #category : #font }
TerminalEmulator class >> selectFontUsingFontChooser [
	FontChooser openWithTitle: 'Please select terminal font'
		initialFont: font
		onAcceptDo: [ :aFont | self setFont: aFont ]
]

{ #category : #theme }
TerminalEmulator class >> selectTheme [
	| themes selected|
	themes := OrderedCollection new.
	TerminalEmulatorColorPalette subclassesDo: [ :e|
		themes add: e light; add: e dark.
	].
	selected := (UIManager default 
                chooseFrom: (themes collect: [:e| e name]) 
                values: themes  
                message: 'Current selected theme is: "', self palette name, '". Pick another one?' 
                title: 'Select theme').
	selected ifNil:[^self].
	palette := selected.
	self announcer announce: (TerminalEmulatorConfigChange data:palette)
]

{ #category : #font }
TerminalEmulator class >> setFont: aFont [
	font := aFont.
	self announcer announce: (TerminalEmulatorConfigChange data: font).
	
]

{ #category : #font }
TerminalEmulator class >> uniFontURI [
	^{'unifont-11.0.02.ttf' -> 'http://unifoundry.com/pub/unifont/unifont-11.0.02/font-builds/unifont-11.0.02.ttf'}
]

{ #category : #font }
TerminalEmulator class >> useUnifont [
	|path|
	(self hasFont: 'Unifont') ifTrue:[
		font := LogicalFont familyName: 'Unifont' pointSize: 11.
		^self announcer announce: (TerminalEmulatorConfigChange data:font)].
	path := self fontsDir.
	self uniFontURI do:[:a|
		(path / (a key)) exists ifFalse:[
		"Download the font"
			ZnClient new
				url: a value;
				downloadTo: path.
		]
	] displayingProgress: [ 'Checking and downloading Unifont font' ].
	FreeTypeFontProvider current prepareForUpdating.
	FreeTypeFontProvider current updateAvailableFontFamilies.
	FreeTypeFontProvider current updateFromSystem.
	FreeTypeFontProvider current updateAvailableFontFamilies.
	(self hasFont: 'Unifont') ifFalse:[^self].
	font := LogicalFont familyName: 'Unifont' pointSize: 11.
	self announcer announce: (TerminalEmulatorConfigChange data:font)
	
]

{ #category : #'world menu' }
TerminalEmulator class >> windowMenuOn: aBuilder [
	<windowMenu>
	aBuilder model class = self ifFalse:[^self].
	"super windowMenuOn: aBuilder."
	(aBuilder item: #'Change PTerm default font')
		order: 2.4;
		action: [ self selecFont ].
	(aBuilder item: #'Download and use Unifont')
		order: 2.5;
		action: [ self useUnifont];
		withSeparatorAfter.
	(aBuilder item: #'Themes')
		order: 2.6;
		action: [ self selectTheme];
		withSeparatorAfter.
	(aBuilder item: #'Browse working directory')
		order: 9;
		action: #browseWorkingDirectory.
	(aBuilder item: #'Inspect working directory')
		action: #inspectWorkingDirectory.
]

{ #category : #'menus-window' }
TerminalEmulator >> browseWorkingDirectory [
	[FileList openOn: self workingDirectory] on: Error do:[self cwdNotFound ]
]

{ #category : #connections }
TerminalEmulator >> closeConnection [

	(self confirm: 'Really disconnect?') ifTrue: [tty session endpoint close. ^true].
	^ false
]

{ #category : #events }
TerminalEmulator >> collapseOrExpand [

	super collapseOrExpand.
	self setLabel: (self isCollapsed ifTrue: [iconTitle] ifFalse: [windowTitle])
]

{ #category : #events }
TerminalEmulator >> cwdNotFound [
	self inform:  'Unable to identify or list the current working directory' 
      
]

{ #category : #events }
TerminalEmulator >> delete [
	self closeConnection ifFalse: [ ^self ].
	tty delete.
	^super delete

]

{ #category : #events }
TerminalEmulator >> doFastWindowReframe: ptName [
	"Override to provide geometry feedback at display top left and to ensure sane gridding of final bounds."

	| newBounds delta flak w pitch skip grid h |
	"For fast display, only higlight the rectangle during loop"
	flak := self bounds extent - tty textBounds extent.
	pitch := tty pitch.
	skip := tty skip.
	grid := pitch@skip.
	newBounds := self bounds newRectButtonPressedDo: [:f | 
		delta := f extent - flak grid: grid.
		w := delta x // pitch.
		h := delta y // skip.
		delta := delta + flak.
		((' ', w printString, 'x', h printString, ' ') forceTo: 10 paddingWith: $ ) displayAt: 5@5.
		f 
			withSideOrCorner: ptName
			setToPoint: (self pointFromWorld: Sensor cursorPoint)
			minExtent: self minimumExtent].
	delta := (newBounds extent - flak grid: grid) + flak.
	self bounds: (newBounds origin extent: delta).
	self world invalidRect: (5@5 extent: (TextMorph new contents: '999x999') extent)
]

{ #category : #connections }
TerminalEmulator >> endpointClosed [
	tty delete.
	super delete.
	"AutoClose ifTrue: [^self delete].
	self setLabel: (windowTitle := iconTitle := 'disconnected').
	(ProtocolAdaptor new localEcho) asProtocolStack push: tty; install; run"
]

{ #category : #events }
TerminalEmulator >> extent: aPoint [

	super extent: aPoint.
	self isCollapsed ifTrue: [^self].
	tty notNil ifTrue: [tty extent: self ttyLayoutBounds extent].
]

{ #category : #events }
TerminalEmulator >> handlesKeyboard: evt [
	"Answer whether we're interested in keyboard events."
	^true
]

{ #category : #'menus-window' }
TerminalEmulator >> hasWorkingDirectory [

	^ workingDirectory notNil
]

{ #category : #'initialize-release' }
TerminalEmulator >> initialize [

	super initialize.
	self setLabel: (windowTitle := iconTitle := 'Terminal').
	self attachKeymapCategory: #TerminalEmulator targetting: self.
	self extent: 10@10.
]

{ #category : #'menus-window' }
TerminalEmulator >> inspectWorkingDirectory [
	[self workingDirectory inspect] on: Error do:[self cwdNotFound ]
]

{ #category : #events }
TerminalEmulator >> keyStroke: evt [
	self tty keyStroke: evt.
	evt wasHandled: true.
]

{ #category : #events }
TerminalEmulator >> keyboardFocusChange: aBoolean [
	super keyboardFocusChange: aBoolean.
	self tty keyboardFocusChange: aBoolean 
]

{ #category : #private }
TerminalEmulator >> nextByteFromLsofOutput: outputStream [

	| character |
	
	character := outputStream next.
	character = $\ ifTrue: [
		character := outputStream next.
		character = $b ifTrue: [ ^ Character backspace asciiValue ].
		character = $f ifTrue: [ ^ Character newPage asciiValue ].
		character = $r ifTrue: [ ^ Character cr asciiValue ].
		character = $n ifTrue: [ ^ Character lf asciiValue ].
		character = $t ifTrue: [ ^ Character tab asciiValue ].
		character = $\ ifTrue: [ ^ $\ asciiValue ].
		character = $x ifTrue: [
			| digitValue1 digitValue2 |
			digitValue1 := outputStream next digitValue.
			digitValue2 := outputStream next digitValue.
			^ digitValue1 * 16 + digitValue2 ].
		Error signal: ('Could not read lsof output due to unrecognized character escape sequence: {1}' format: {
			(String with: $\ with: character) printString }) ].
	character = $^ ifTrue: [
		"Note that lsof's output is ambiguous in this case, see: https://github.com/lsof-org/lsof/issues/130.
		We interpret a $^ followed by $A through $_ as a control character, and as a plain $^ otherwise."
		character := outputStream peek.
		^ (character asciiValue between: $A asciiValue and: $_ asciiValue)
			ifTrue: [
				outputStream next.
				character asciiValue - $@ asciiValue ]
			ifFalse: [ $^ asciiValue ] ].
	^ character asciiValue

]

{ #category : #'initialize-release' }
TerminalEmulator >> openOn: ttyMorph [
	"Open a new SystemWindow containing just a ttyMorph."

	| ext |
	self setLabel: windowTitle.
	tty := ttyMorph setWindow: self.
	self
		addMorph: tty frame: (0 @ 0 corner: 1 @ 1);
		model: tty.
	"Figure out what our extent should be based on how much extra space we use for decoration."
	ext := tty preferredExtent						"the extent that the tty would like to receive"
		+ self extent - self ttyLayoutBounds extent.	"window decoration"
	self currentWorld activeHand keyboardFocus: nil.			"make sure we get focus when we're opened"
	self extent: ext; openInWorld.
	tty install; run
]

{ #category : #'initialize-release' }
TerminalEmulator >> openOn: ttyMorph labeled: aString [
	"Open a new SystemWindow containing just a ttyMorph."

	windowTitle := iconTitle := aString.
	^self openOn: ttyMorph
]

{ #category : #events }
TerminalEmulator >> qdoFastWindowReframe: ptName [
	"Override to provide geometry feedback at display top left and to ensure sane gridding of final bounds."

	| newBounds delta flak w pitch skip grid h |
	"For fast display, only higlight the rectangle during loop"
	flak := self bounds extent - tty textBounds extent.
	pitch := tty pitch.
	skip := tty skip.
	grid := pitch@skip.
	newBounds := self bounds newRectButtonPressedDo: [:f | 
		delta := f extent - flak grid: grid.
		w := delta x // pitch.
		h := delta y // skip.
		delta := delta + flak.
		((' ', w printString, 'x', h printString, ' ') forceTo: 10 paddingWith: $ ) displayAt: 5@5.
		f 
			withSideOrCorner: ptName
			setToPoint: (self pointFromWorld: Sensor cursorPoint)
			minExtent: self minimumExtent].
	delta := (newBounds extent - flak grid: grid) + flak.
	self bounds: (newBounds origin extent: delta).
	self world invalidRect: (5@5 extent: (TextMorph new contents: '999x999') extent).
	self activeHand newKeyboardFocus: self
]

{ #category : #'menus-window' }
TerminalEmulator >> removeShortcut: name [

	Shortcuts removeKey: name ifAbsent: []
]

{ #category : #accessing }
TerminalEmulator >> setIconTitle: aString [

	iconTitle := aString.
	self isCollapsed ifTrue: [self setLabel: aString].
]

{ #category : #private }
TerminalEmulator >> setLabel: aString [

	labelString = aString ifFalse: [super setLabel: aString]
]

{ #category : #accessing }
TerminalEmulator >> setWindowTitle: aString [

	windowTitle := aString.
	self isCollapsed ifFalse: [self setLabel: aString].
]

{ #category : #accessing }
TerminalEmulator >> setWorkingDirectory: fileURLString [

	| fileURL |

	fileURL := [ ZnUrl fromString: fileURLString ] on: Error do: [ :error | nil ].
	workingDirectory := fileURL ifNotNil: [ fileURL asFileReference ].
]

{ #category : #events }
TerminalEmulator >> simulateShortcutAsKeyStroke: comb [
	|evt|
	evt := KeyboardEvent new 
				setType: #keyDown 
				buttons: comb modifier eventCode
				position: 0@0 
				keyValue: comb key asciiValue + 1 - $a asciiValue
				charCode: comb key asciiValue
				hand: ActiveWorld activeHand  
				stamp: 0.
	tty keyStroke: evt
]

{ #category : #accessing }
TerminalEmulator >> tty [

	^ tty
]

{ #category : #private }
TerminalEmulator >> ttyLayoutBounds [

	^self layoutBounds
]

{ #category : #events }
TerminalEmulator >> updateFont [
	tty setUpFont.
]

{ #category : #events }
TerminalEmulator >> updateTheme [
	tty setUpTheme.
]

{ #category : #private }
TerminalEmulator >> workingDirectory [

	| pid lsofCommand output status path |

	workingDirectory ifNotNil: [ ^ workingDirectory ].
	pid := self tty session endpoint pid.
	lsofCommand := 'LC_ALL=C lsof -F n0 -a -d cwd -p {1}; printf "\\n%s" $?' format: { pid }.
	output := OSPlatform current resultOfCommand: lsofCommand.
	status := (output copyAfterLast: Character lf) asInteger.
	status = 0 ifFalse: [
		Error signal: ('Could not determine working directory (lsof status: {1})' format: { status }) ].
	path := ByteArray streamContents: [ :pathStream |
		| outputStream |
		outputStream := output readStream.
		outputStream skipTo: Character null; skipTo: Character null; next.
		[ outputStream peek = Character null ] whileFalse: [
			pathStream nextPut: (self nextByteFromLsofOutput: outputStream) ] ].
	^ path utf8Decoded asFileReference
]
