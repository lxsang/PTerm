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
		help: 'Terminal emulator';
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
	
	| win |

	win := self open.
	(PTerm new xspawn: { '/bin/bash'.} env: {'TERM=linux'}) asProtocolStack
		push: TerminalEmulatorXterm new;
		push: win tty;
		install;
		run.
	^ win	
	
]

{ #category : #'instance creation' }
TerminalEmulator class >> telnet: hostName [
	"TeletypeWindow telnet: 'localhost'"

	^self telnet: hostName port: 23
]

{ #category : #'menus-config' }
TerminalEmulator >> buildConfigMenu [

	| m |
	m := MenuMorph new defaultTarget: self.

	m
		add: 'terminal type (', TerminalType terminalTypeName, ') '
		subMenu: ((MenuMorph new defaultTarget: self)
			add: 'vt102' selector: #menuBlock: argument: [TerminalType := TerminalEmulatorVT102];
			balloonTextForLastItem: 'Emulate a VT102 terminal.';
			add: 'xterm' selector: #menuBlock: argument: [TerminalType := TerminalEmulatorXterm];
			balloonTextForLastItem: 'Emulate an xterm terminal.');
		balloonTextForLastItem: 'Select the kind of terminal emulation to use.'.
	"m
		add: 'font (', TerminalEmulatorLineMorph defaultFont, ')' subMenu: self buildFontMenu;
		balloonTextForLastItem: 'Set the default font for terminal windows.
(Changes take effect in NEW windows, not this one.)'."

	self menu: m add: 'enable auto-close' var: AutoClose eval: [AutoClose := AutoClose not]
			help: 'Automatically close the window when the session terminates.'.
	m addLine.

	self menu: m add: 'save screen size' var: SaveTerminalSize
			eval: [SaveTerminalSize := SaveTerminalSize not]
			help: 'Save terminal screen size in shortcuts and restore it in new sessions.'.
	self menu: m add: 'save main options' var: SaveTerminalMainOptions
			eval: [SaveTerminalMainOptions := SaveTerminalMainOptions not]
			help: 'Save terminal main options in shortcuts and restore them in new sessions.'.
	self menu: m add: 'save vt options' var: SaveTerminalVTOptions
			eval: [SaveTerminalVTOptions := SaveTerminalVTOptions not]
			help: 'Save terminal VT options in shortcuts and restore them in new sessions.'.
	self menu: m add: 'save telnet options' var: SaveTelnetOptions
			eval: [SaveTelnetOptions := SaveTelnetOptions not]
			help: 'Save telnet protocol options in shortcuts and restore them in new sessions.'.

	m addLine; add: 'restore defaults' selector: #menuBlock: argument: [self menuRestoreDefaults];
		balloonTextForLastItem: 'Reset ALL preferences and option values to their factory settings.'.

	^m
]

{ #category : #'menus-config' }
TerminalEmulator >> buildFontMenu [
	| m |
	m := MenuMorph new defaultTarget: TerminalEmulatorLineMorph.
	StrikeFont monospacedFamilyNames do: [ :family |
		m add: family
		selector: #defaultFont:
		argument: family;
		 balloonTextForLastItem: 'Set the default font to ', family, '.
(Changes take effect in NEW windows, not this one.)'
	].
	^ m
]

{ #category : #connections }
TerminalEmulator >> closeConnection [

	(self confirm: 'Really disconnect?') ifTrue: [tty session endpoint close]
]

{ #category : #events }
TerminalEmulator >> collapseOrExpand [

	super collapseOrExpand.
	self setLabel: (self isCollapsed ifTrue: [iconTitle] ifFalse: [windowTitle])
]

{ #category : #events }
TerminalEmulator >> delete [

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

	AutoClose ifTrue: [^self delete].
	self setLabel: (windowTitle := iconTitle := 'disconnected').
	(ProtocolAdaptor new localEcho) asProtocolStack push: tty; install; run
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

{ #category : #connections }
TerminalEmulator >> newConnection [

	| remote host port |
	remote := UIManager default
		request: 'Remote host name and port?'
		initialAnswer: 'localhost 23'.
	(remote isNil or: [remote size == 0]) ifTrue: [^nil].
	remote := remote substrings.
	remote size < 1 ifTrue: [^nil].
	host := remote first.
	port := remote size > 1 ifTrue: [remote last asInteger].
	port isNil ifTrue: [port := 23].
	self newConnection: host port: port
]

{ #category : #connections }
TerminalEmulator >> newConnection: args [

	^self newConnection: args preferences: nil
]

{ #category : #connections }
TerminalEmulator >> newShell [

	| shell argv prog |
	shell := UIManager default
		request: 'Shell command?'
		initialAnswer: '/bin/bash -i'.
	argv := shell substrings.
	argv isEmpty ifTrue: [^self].
	prog := argv first.
	argv := argv copyFrom: 2 to: argv size.
	self setIconTitle: prog; setWindowTitle: prog.
	(PseudoTTYEndpoint command: prog arguments: argv) asProtocolStack
		push:		TerminalType new;
		push:		tty;
		install;
		run

]

{ #category : #connections }
TerminalEmulator >> newShell: args [

	^self newShell: args preferences: nil
]

{ #category : #connections }
TerminalEmulator >> newShell: args preferences: prefs [

	| argv prog params |
	prog := args first.
	argv := args last.
	params := prefs isNil ifTrue: [IdentityDictionary new] ifFalse: [prefs].
	self setIconTitle: prog; setWindowTitle: prog.
	(PseudoTTYEndpoint command: prog arguments: argv) asProtocolStack
		push: TerminalType new;
		push: tty;
		note: #loadPreferences with: params;
		install;
		run

]

{ #category : #connections }
TerminalEmulator >> newShortcut: shortcut [

	| epClass epArgs |
	self savePreferences: shortcut.
	epClass := shortcut at: #endpointClass.
	epArgs := shortcut at: #endpointArguments.
	epClass == #PseudoTTYEndpoint ifTrue: [^self newShell: epArgs preferences: shortcut].
	epClass == #NetworkEndpoint ifTrue: [^self newConnection: epArgs preferences: shortcut].
	self error: 'I don''t know how to create an endpoint of type ', epClass
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
