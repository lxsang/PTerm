"
I am a collection of ProtocolStates constituting a transition graph for a StatefulProtocol.  See my class side for some examples of how I construct state machine descriptions for you.

Note that before I can be used to drive a StatefulProtocol you *must* send me #compile.  I will answer the initial ProtocolState in the compiled transition graph.  (I will also complain if your protocol is broken. ;-)  You subsequently pass this ProtocolState as the argument to StatefulProtocol class>>initialState: in order to instantiate a new StatefulProtocol.

Structure:
 initialState		Symbol	-- the name of the initial (root) node in my transition graph
"
Class {
	#name : #StatefulProtocolDescription,
	#superclass : #IdentityDictionary,
	#instVars : [
		'initialState'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #examples }
StatefulProtocolDescription class >> example [
	"A state machine that recognises occurrences of 'x' 'xy' and 'xy[digits...]z' in a stream of characters.  Note: this is used by StateMachineTester, so don't modify it.  See StateMachineTester class>>test for an example of use."
	"StatefulProtocolDescription example"

	| desc |
	desc := self new.
	(desc newState: #initial -> (#echo: -> #initial)) add: $x -> (nil -> #statex).
	(desc newState: #statex -> (#echox: -> #initial)) add: $y -> (#initPrefix: -> #statexy).
	(desc newState: #statexy -> (#echoxy: -> #initial))
		add: $z -> (#echoxyz: -> #initial);
		addAll: '0123456789' -> (#addPrefix: -> nil).
	desc initialState: #initial.
	^desc
]

{ #category : #examples }
StatefulProtocolDescription class >> example2 [
	"StatefulProtocolDescription example2 explore"

	^self example compile
]

{ #category : #examples }
StatefulProtocolDescription class >> example3 [		"Note: this example should pop up an error notifier during compilation"

	"StatefulProtocolDescription example3 compile"

	| desc |
	desc := self new.
	(desc newState: #initial -> (#echo: -> #initial)) add: $x -> (nil -> #statex).
	(desc newState: #statex -> (#echox: -> #initial)) add: $y -> (nil -> #statexy).
	(desc newState: #statexy -> (#echoxy: -> #initial)) add: $z -> (#echoxy: -> #statexyz).
	desc initialState: #initial.
	^desc
]

{ #category : #'instance creation' }
StatefulProtocolDescription class >> initialState: stateName [

	^self new initialState: stateName
]

{ #category : #compiling }
StatefulProtocolDescription >> compile [
	"Compile my symbolic representation into a cyclic DAG and answer the root node"

	| edge |
	self valuesDo: [:state |
		state defaultTransition: (self resolve: state default).
		state keysDo: [:key |
			edge := state at: key.
			state transitionAt: key put: (self resolve: edge)]].
	
	^self at: initialState
]

{ #category : #'initialize-release' }
StatefulProtocolDescription >> initialState: stateName [

	initialState := stateName
]

{ #category : #'initialize-release' }
StatefulProtocolDescription >> newState: rule [

	^self newState: rule key default: rule value
]

{ #category : #'initialize-release' }
StatefulProtocolDescription >> newState: stateName default: transition [

	^self at: stateName put: (ProtocolState name: stateName default: transition)
]

{ #category : #printing }
StatefulProtocolDescription >> printElementsOn: aStream [

	aStream nextPutAll: '(initial: ' , initialState printString , ' states:'.
	self keysDo: [:key | aStream space.  key printOn: aStream].
	aStream nextPut: $)
]

{ #category : #compiling }
StatefulProtocolDescription >> resolve: edge [

	| target action |
	target := edge state.
	action := edge action.
	target := (self includesKey: target)
		ifTrue: [self at: target]
		ifFalse: [target isNil
					ifTrue: [nil]
					ifFalse: [self error: 'unknown target state ' , edge printString]].
	^ProtocolStateTransition action: action state: target
]
