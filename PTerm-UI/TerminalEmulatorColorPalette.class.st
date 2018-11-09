"
I presents a foreground and backgroud color scheme of the terminal.
Ech of my subclasses is a color theme
"
Class {
	#name : #TerminalEmulatorColorPalette,
	#superclass : #Object,
	#instVars : [
		'background',
		'foreground',
		'mode'
	],
	#category : #'PTerm-UI'
}

{ #category : #accessing }
TerminalEmulatorColorPalette class >> colors [
	^self initializeColors 
]

{ #category : #initialization }
TerminalEmulatorColorPalette class >> dark [
	|colors|
	colors := self colors.
	^self new 
		foreground:  (colors at:1) shallowCopy;
		background: (colors at:2) shallowCopy;
		reversePolarity;
		mode: #dark;
		yourself
]

{ #category : #accessing }
TerminalEmulatorColorPalette class >> initializeColors [
	^self rgbTriplets collect:[:p|
		 p  collect: [:el| (el bitOr: (255  bitShift: 24)) asColorOfDepth: 32 ]	
	]
]

{ #category : #initialization }
TerminalEmulatorColorPalette class >> light [
	|colors|
	colors := self colors.
	^self new 
		foreground:  (colors at:1) shallowCopy;
		background: (colors at:2) shallowCopy;
		mode: #light;
		yourself
]

{ #category : #theming }
TerminalEmulatorColorPalette class >> rgbTriplets [
	^ self subclassResponsibility 
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> background [
	^ background
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> background: anObject [
	background := anObject
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> foreground [
	^ foreground
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> foreground: anObject [
	foreground := anObject
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> initialize [
	background := Array new: 8.
	foreground := Array new: 8.
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> mode [
	^ mode
]

{ #category : #accessing }
TerminalEmulatorColorPalette >> mode: anObject [
	mode := anObject
]

{ #category : #private }
TerminalEmulatorColorPalette >> name [
	^ self className, ' ', mode
]

{ #category : #private }
TerminalEmulatorColorPalette >> reversePolarity [
	background swap: 1 with: background size.
	foreground swap: 1 with: foreground size.
]
