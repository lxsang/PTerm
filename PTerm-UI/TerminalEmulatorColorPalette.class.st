"
I presents a foreground and backgroud color scheme of the terminal.
Ech of my subclasses is a color theme
"
Class {
	#name : #TerminalEmulatorColorPalette,
	#superclass : #Object,
	#instVars : [
		'background',
		'foreground'
	],
	#classInstVars : [
		'colors'
	],
	#category : #'PTerm-UI'
}

{ #category : #accessing }
TerminalEmulatorColorPalette class >> colors [
	colors ifNil: [ colors := self initializeColors ].
	^colors
]

{ #category : #initialization }
TerminalEmulatorColorPalette class >> dark [
	^self mode: #dark
]

{ #category : #accessing }
TerminalEmulatorColorPalette class >> initializeColors [
	^self rgbTriplets collect:[:p|
		 p  collect: [:el| (el bitOr: (255  bitShift: 24)) asColorOfDepth: 32 ]	
	]
]

{ #category : #initialization }
TerminalEmulatorColorPalette class >> light [
	^self mode: #light
]

{ #category : #initialization }
TerminalEmulatorColorPalette class >> mode: mode [
	^self new 
		foreground:  (self colors at:1);
		background: (self colors at:2);
		yourself
]

{ #category : #'as yet unclassified' }
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

{ #category : #private }
TerminalEmulatorColorPalette >> reversePolarity [
	background swap: 1 with: background size.
	foreground swap: 1 with: foreground size.
]
