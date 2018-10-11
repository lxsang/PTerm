"
I am a transition to a new ProtocolState.  While making the transition I can perform some action association with the change from the old to the new state.
"
Class {
	#name : #ProtocolStateTransition,
	#superclass : #Object,
	#instVars : [
		'state',
		'action'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #'instance creation' }
ProtocolStateTransition class >> action: aSymbol [

	^self new state: nil; action: aSymbol
]

{ #category : #'instance creation' }
ProtocolStateTransition class >> action: aSymbol state: aState [

	^self new state: aState; action: aSymbol
]

{ #category : #'instance creation' }
ProtocolStateTransition class >> state: aState [

	^self new state: aState; action: nil
]

{ #category : #'instance creation' }
ProtocolStateTransition class >> state: aState action: aSymbol [

	^self new state: aState; action: aSymbol
]

{ #category : #accessing }
ProtocolStateTransition >> action [

	^action
]

{ #category : #accessing }
ProtocolStateTransition >> action: aSymbol [

	action := aSymbol
]

{ #category : #printing }
ProtocolStateTransition >> printOn: aStream [

	aStream nextPut: ${.
	action printOn: aStream.
	aStream nextPutAll: ' -> '.
	aStream nextPutAll: ((state isMemberOf: Symbol)
		ifTrue: [state]
		ifFalse: [state name]) printString.
	aStream nextPut: $}
]

{ #category : #accessing }
ProtocolStateTransition >> state [

	^state
]

{ #category : #accessing }
ProtocolStateTransition >> state: aState [

	state := aState
]

{ #category : #'state transitions' }
ProtocolStateTransition >> transitionFrom: lastState for: aClient with: anObject [

	action isNil ifFalse: [aClient perform: action with: anObject].
	^state isNil ifTrue: [lastState] ifFalse: [state]
]
