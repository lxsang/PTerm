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
		'iconTitle'
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
	#category : #'PTerm-UI'
}

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
	
	(aBuilder item: #'Terminal emulator')
		order: 0.8; 
		icon: self icon;  
		parent: #'MostUsedTools';
		keyText: 'o, c';
		help: 'Terminal';
		action: [ self openBash ].

]

{ #category : #'instance creation' }
TerminalEmulator class >> new [

	^super new initialize
]

{ #category : #'instance creation' }
TerminalEmulator class >> open [

	^self new openOn: TerminalEmulatorMorph new
]

{ #category : #'instance creation' }
TerminalEmulator class >> openBash [
	
	| win term |
	term := (PTerm new xspawn: { '/bin/bash'} env: {'TERM=xterm'}).
	"term := (PTermEcho new)."
	win := self open.
	term asProtocolStack
		push: TerminalEmulatorXterm new;
		push: win tty;
		install;
		run.
	win extent: win extent.
	^ win	
	
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
	Transcript show: 'close endpoint'.
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

{ #category : #'initialize-release' }
TerminalEmulator >> initialize [

	super initialize.
	self setLabel: (windowTitle := iconTitle := 'Teletype').
	self extent: 10@10.
]

{ #category : #private }
TerminalEmulator >> menu: aMenu add: aString var: aBoolean eval: aBlock help: helpString [

	aMenu
		add: (aBoolean ifTrue: ['<yes>'] ifFalse: ['<no>']), aString
		selector: #menuBlock:
		argument: aBlock;
		balloonTextForLastItem: helpString
]

{ #category : #private }
TerminalEmulator >> menuBlock: aBlock [

	aBlock value
]

{ #category : #'menus-config' }
TerminalEmulator >> menuRestoreDefaults [

	(self confirm: 'Really restore all defaults?
 Note: this will also clear all of your shortcuts! ') ifFalse: [^self].
	TerminalEmulator initialize.
	TerminalEmulatorMorph initialize.
	TerminalEmulatorVT102 initialize.
	TerminalEmulatorXterm initialize.
	tty sessionNote: #restoreDefaults
	
]

{ #category : #'menus-window' }
TerminalEmulator >> menuSaveShortcut [

	| shortcut name | 
	shortcut := IdentityDictionary new.
	shortcut at: #sessionType put: #unknown.
	tty sessionNote: #savePreferences with: shortcut.
	name := UIManager default request: 'Shortcut name?' initialAnswer: 'Untitled'.
	(name isNil or: [name isEmpty]) ifTrue: [^self].
	((Shortcuts includesKey: name) and: [(self confirm: 'Replace existing shortcut called `', name, '''?') not])
		ifTrue: [^self].
	Shortcuts at: name put: shortcut.
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
	self activeHand keyboardFocus: nil.			"make sure we get focus when we're opened"
	self extent: ext; openInWorldExtent: ext.
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

{ #category : #private }
TerminalEmulator >> savePreferences: dict [

	dict
		at: #saveTerminalSize put: SaveTerminalSize;
		at: #saveTerminalMainOptions put: SaveTerminalMainOptions;
		at: #saveTerminalVTOptions put: SaveTerminalVTOptions;
		at: #saveTelnetOptions put: SaveTelnetOptions
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
TerminalEmulator >> tty [

	^ tty
]

{ #category : #private }
TerminalEmulator >> ttyLayoutBounds [

	^self layoutBounds
]
