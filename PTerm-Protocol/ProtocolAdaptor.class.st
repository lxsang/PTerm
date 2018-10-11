"
I am a pluggable ProtocolLayer.  You can insert me anywhere in a LayeredProtocol stack.

Communication between protocol stack layers is accomplished using the following messages:

	upcall: datum					-- receive data from the protocol below me in the stack
	downcall: datum					-- receive data from the protocol above me
	flush							-- the protocol below me might become idle for a while
	note: aSymbol with: anObject	-- I am being informed that something ""global"" has happened

By default I am completely transparent.  In other words I react to the above messages as follows:

	upcall: datum					-- I pass datum on to the protocol above me
	downcall: dataum				-- I pass datum on to the protocol below me
	flush							-- I pass the message to the protocol above me
	note: sym with: obj				-- is ignored entirely

Any or all of these default reactions can be changed by installing blocks which I will execute in response to the above messages.  You install such blocks by sending me the following messages:

	upBlock: unaryBlock			-- evaluated on #up: passing datum as argument
	downBlock: unaryBlock			-- evaluated on #down: passing datum as argument
	flushBlock: aBlock				-- evaulated on #flush with no arguments
	noteBlock: binaryBlock			-- evaulated on #note:with: passing aSym and anObj as arguments

By now you've probably guess that my default behaviour is simply to install the following blocks when I am created:

	upBlock: [:datum | up upcall: datum]
	downBlock: [:datum | down downcall: datum]
	flushBlock: []
	noteBlock: [:aSymbol :anObject | ]

My class knows how to instantiate particular kinds of default behaviour in me, including:

	pass							-- the default (transparency)
	trace							-- prints each datum on the Transcript as it whizzes by
	reflect							-- bounces downward data back up the stack and vice-versa

Here's one example, possibly the shortest known means to create an ""echo"" server:

	(NetworkEndpoint socket: anAcceptedSocket) asProtocolStack
		push: ProtocolAdaptor reflect;
		install;
		run
"
Class {
	#name : #ProtocolAdaptor,
	#superclass : #ProtocolLayer,
	#instVars : [
		'upBlock',
		'downBlock',
		'flushBlock',
		'noteBlock'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #'instance creation' }
ProtocolAdaptor class >> new [

	^super new initialize
]

{ #category : #'instance creation' }
ProtocolAdaptor class >> upBlock: aBlock [

	^self new upBlock: aBlock
]

{ #category : #accessing }
ProtocolAdaptor >> downBlock: block [

	downBlock := block
]

{ #category : #protocol }
ProtocolAdaptor >> downcall: arg [

	downBlock value: arg
]

{ #category : #protocol }
ProtocolAdaptor >> flush [

	flushBlock value
]

{ #category : #accessing }
ProtocolAdaptor >> flushBlock: block [

	flushBlock := block
]

{ #category : #'initialize-release' }
ProtocolAdaptor >> initialize [

	upBlock := [:arg | self notify: 'up ' , arg printString].
	downBlock := [:arg | self notify: 'down ' , arg printString].
	flushBlock := [].
	noteBlock := [:s :a | ]
]

{ #category : #'canned protocols' }
ProtocolAdaptor >> localEcho [
	"A reflect suitable for local echo on dumb ttys, when placed immediately below a TtyMorph, recognising a few of the ASCII control characters."

	| c |
	^self
		upBlock: [:arg | down downcall: arg];
		downBlock: [:arg | c := arg bitAnd: 127.
			(c == 8) | (c == 127) ifTrue: [up bs; upcall: 32; bs]
				ifFalse: [(c == 10) | (c == 13) ifTrue: [up newline]
				ifFalse: [c >= 32 ifTrue: [up upcall: c]]].
			up flush.]
]

{ #category : #protocol }
ProtocolAdaptor >> note: aSymbol with: anObject [

	noteBlock value: aSymbol value: anObject
]

{ #category : #accessing }
ProtocolAdaptor >> noteBlock: block [

	noteBlock := block
]

{ #category : #'canned protocols' }
ProtocolAdaptor >> pass [

	^self
		upBlock: [:arg | up upcall: arg];
		downBlock: [:arg | down downcall: arg]
]

{ #category : #'canned protocols' }
ProtocolAdaptor >> reflect [

	^self
		upBlock: [:arg | down downcall: arg];
		downBlock: [:arg | up upcall: arg; flush]
]

{ #category : #'canned protocols' }
ProtocolAdaptor >> trace [

	^self
		upBlock: [:arg |
			Transcript cr; nextPutAll: 'up '; nextPutAll: arg printString; endEntry.
			up upcall: arg];
		downBlock: [:arg |
			Transcript cr; nextPutAll: 'down '; nextPutAll: arg printString; endEntry.
			down downcall: arg]
]

{ #category : #'canned protocols' }
ProtocolAdaptor >> traceTo: aCollection [

	"trace protocol opertaions for testing purposes"

	^self
		upBlock: [:arg |
			aCollection add: {#up. arg}.
			up upcall: arg];
		downBlock: [:arg |
			aCollection add: {#down. arg}.
			down downcall: arg]
]

{ #category : #accessing }
ProtocolAdaptor >> upBlock: block [

	upBlock := block
]

{ #category : #protocol }
ProtocolAdaptor >> upcall: arg [

	upBlock value: arg
]
