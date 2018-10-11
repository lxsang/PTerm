"
I am an abstract endpoint for communication within a LayeredProtocol stack.  (I therefore expect to be the lowest element in that stack.)  I implement a server which waits for incoming data and then passes it up the stack for processing by higher protocol layers.  The actual reading of data from the remote entity must be implemented by my concrete subclasses.
"
Class {
	#name : #ProtocolEndpoint,
	#superclass : #ProtocolLayer,
	#instVars : [
		'serverProcess'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #protocol }
ProtocolEndpoint >> close [
	"Terminate the connection to the remote entity."

	^self subclassResponsibility
]

{ #category : #protocol }
ProtocolEndpoint >> downcall: anObject [
	"Receive anObject from my high protocol.  The default behaviour (in Protocol) is to pass it down to my low protocol.  ProtocolEndpoints however are at the bottom of the ProtocolStack and thus have no low protocol, so they have to treat this specially (e.g., by sending the data over the network or to another process)."

	^self subclassResponsibility
]

{ #category : #'server loop' }
ProtocolEndpoint >> getData [
	"Answer a collection of data to be passed up the protocol stack, or nil if the endpoint has failed."

	^self subclassResponsibility
]

{ #category : #protocol }
ProtocolEndpoint >> isConnected [
	"Answer whether the endpoint is still connected."

	^self subclassResponsibility
]

{ #category : #protocol }
ProtocolEndpoint >> name [
	"Answer the name of the remote entity."

	^self subclassResponsibility
]

{ #category : #protocol }
ProtocolEndpoint >> note: aSymbol with: anObject [

	super note: aSymbol with: anObject.
	aSymbol == #endpointClosed ifTrue: [^self terminateServer].
	aSymbol == #windowClosed ifTrue: [^self close].
]

{ #category : #protocol }
ProtocolEndpoint >> run [
	"Spawn a background process running the serverLoop."

	super run.
	serverProcess := [self serverLoop] forkAt: Processor userSchedulingPriority.
]

{ #category : #'server loop' }
ProtocolEndpoint >> serverLoop [
	"I sit in a loop (usually in a background Process) waiting for data to arrive on my underlying connection then pass anything received up to my high protocol.  When #getData answers nil to inform me that my underlying connection has been destroyed I close down the entire endpoint, inform my session of the fact and then exit.  See also ProtocolEndpoint>>run."

	| buf |
"MessageTally spyOn: ["
	Transcript cr; show: self class name, ' server running'.
	[(buf := self getData) notNil] whileTrue: [up upcallAll: buf].
	serverProcess := nil.
	self sessionNote: #endpointClosed; close.
	Transcript cr; show: self class name, ' server terminated'.
"] toFileNamed: 'spy.out'"
]

{ #category : #'server loop' }
ProtocolEndpoint >> terminateServer [
	"Terminate the serverLoop process.  This should never be called directly: use #close instead."

	serverProcess isNil
		ifFalse:
			[serverProcess terminate.
			 serverProcess := nil.
			 self sessionNote: #disconnected.
			 Transcript cr; show: self class name, ' server terminated']
]
