Class {
	#name : #TerminalEmulatorConfigChange,
	#superclass : #Announcement,
	#instVars : [
		'data'
	],
	#category : #'PTerm-UI'
}

{ #category : #accessing }
TerminalEmulatorConfigChange class >> data: f [
	^self new data:f; yourself
]

{ #category : #accessing }
TerminalEmulatorConfigChange >> data [
	^ data
]

{ #category : #accessing }
TerminalEmulatorConfigChange >> data: anObject [
	data := anObject
]
