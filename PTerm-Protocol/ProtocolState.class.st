"
I am a single state within a cyclic graph of states.  My values are edges leading to another state in the graph.  If the edge has an action associated with it then I perform the method of that name in my client object, passing the object which stepped me as argument, before following the edge.

Structure:
 name		Symbol				-- my state's name
 keys		Object				-- the input tokens that cause me to step
 values		#(Symbol1 Symbol2)	-- an edge: the next state and a client action selector
 default		#(Symbol1 Symbol2)	-- the edge I follow if no key matches the stepping object

I am intended to be inserted somewhere in the middle of a LayeredProtocol stack.
"
Class {
	#name : #ProtocolState,
	#superclass : #IdentityDictionary,
	#instVars : [
		'name',
		'default'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #examples }
ProtocolState class >> example [
	"ProtocolState example"

	^(self name: #initial default: #echo: -> #initial)
		at: 42 put: #echo42: -> #initial;
		yourself
]

{ #category : #'instance creation' }
ProtocolState class >> name: myName default: aTransition [
	^self new
		name: myName;
		default: aTransition
]

{ #category : #accessing }
ProtocolState >> add: anAssociation [

	^self transitionAt: anAssociation key put: (self transitionFor: anAssociation value)
]

{ #category : #accessing }
ProtocolState >> addAll: anAssociation [

	^self atAll: anAssociation key put: anAssociation value
]

{ #category : #accessing }
ProtocolState >> addAllInteger: anAssociation [

	^self atAllInteger: anAssociation key put: anAssociation value
]

{ #category : #accessing }
ProtocolState >> addInteger: anAssociation [

	^self transitionAt: anAssociation key asInteger put: (self transitionFor: anAssociation value)
]

{ #category : #accessing }
ProtocolState >> at: key put: transition [

	^self transitionAt: key put: (self transitionFor: transition)
]

{ #category : #accessing }
ProtocolState >> at: anObject to: limit put: transition [

	| edge |
	edge := self transitionFor: transition.
	anObject to: limit do: [:target | self transitionAt: target put: edge]
]

{ #category : #accessing }
ProtocolState >> atAll: collection put: transition [
	| edge |
	edge := self transitionFor: transition.
	collection do: [:elt | self transitionAt: elt put: edge]
]

{ #category : #accessing }
ProtocolState >> atAllInteger: collection put: transition [
	| edge |
	edge := self transitionFor: transition.
	collection do: [:elt | self transitionAt: elt asInteger put: edge]
]

{ #category : #accessing }
ProtocolState >> default [

	^default
]

{ #category : #accessing }
ProtocolState >> default: transition [

	self defaultTransition: (self transitionFor: transition)
]

{ #category : #accessing }
ProtocolState >> defaultTransition: aTransition [

	default := aTransition
]

{ #category : #accessing }
ProtocolState >> name [

	^name
]

{ #category : #accessing }
ProtocolState >> name: aSymbol [

	name := aSymbol
]

{ #category : #printing }
ProtocolState >> printElementsOn: aStream [

	aStream nextPutAll: '(name: ' , name printString.
	aStream nextPutAll: ' default: ' , default printString.
	aStream nextPutAll: ' transitions:'.
	self associationsDo: [:transition | aStream space.  transition printOn: aStream.].
	aStream nextPut: $).
]

{ #category : #accessing }
ProtocolState >> transitionAt: key [

	^super at: key ifAbsent: [default]
]

{ #category : #accessing }
ProtocolState >> transitionAt: key put: edge [

	^super at: key put: edge
]

{ #category : #private }
ProtocolState >> transitionFor: transition [

	^ProtocolStateTransition action: transition key state: transition value
]
