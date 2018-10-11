"
I am a ProtocolLayer.  I implement my protocol as a state machine, transitioning from one state to another according to patterns that I recognise in the data flowing through me.
"
Class {
	#name : #StatefulProtocol,
	#superclass : #ProtocolLayer,
	#instVars : [
		'currentState',
		'client'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #'instance creation' }
StatefulProtocol class >> initialState: stateNode [

	^self new initialState: stateNode
]

{ #category : #'instance creation' }
StatefulProtocol class >> initialState: stateNode client: aClient [

	^self new initialState: stateNode; client: aClient
]

{ #category : #accessing }
StatefulProtocol >> client: anObject [

	client := anObject
]

{ #category : #accessing }
StatefulProtocol >> initialState: stateNode [

	currentState := stateNode.
	self client: self
]

{ #category : #accessing }
StatefulProtocol >> state [

	^currentState
]

{ #category : #protocol }
StatefulProtocol >> upcall: anObject [

	currentState := (currentState transitionAt: anObject)
		transitionFrom: currentState for: client with: anObject
]
