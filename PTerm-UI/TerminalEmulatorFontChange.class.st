Class {
	#name : #TerminalEmulatorFontChange,
	#superclass : #Announcement,
	#instVars : [
		'font'
	],
	#category : #'PTerm-UI'
}

{ #category : #accessing }
TerminalEmulatorFontChange class >> font: f [
	^self new font:f; yourself
]

{ #category : #accessing }
TerminalEmulatorFontChange >> font [
	^ font
]

{ #category : #accessing }
TerminalEmulatorFontChange >> font: anObject [
	font := anObject
]
